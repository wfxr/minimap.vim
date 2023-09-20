" MIT (c) Wenxuan Zhang and Zach Nielsen

" Script-scoped constants
let s:STATE_CURSOR       = 0b00001
let s:STATE_DIFF_RM      = 0b00010
let s:STATE_DIFF_ADD     = 0b00100
let s:STATE_DIFF_MOD     = 0b01000
let s:STATE_WINDOW_RANGE = 0b10000
let s:last_pos = {}
let s:last_range = {}
let s:win_info = {}
let s:len_cache = {}

function! minimap#vim#MinimapToggle() abort
    call s:toggle_window()
endfunction

function! minimap#vim#MinimapClose() abort
    call s:close_window()
endfunction

function! minimap#vim#MinimapOpen() abort
    call s:open_window()
endfunction

function! minimap#vim#MinimapRefresh() abort
    call s:refresh_minimap(1)
endfunction

function! minimap#vim#MinimapUpdateHighlight() abort
    call s:get_window_info()
    call s:update_highlight()
endfunction

function! minimap#vim#MinimapRescan() abort
    call remove(s:len_cache, expand('%'))
    call s:get_window_info()
    call s:refresh_minimap(1)
    call s:update_highlight()
endfunction

function! s:buffer_enter_handler() abort
    if &filetype ==# 'minimap'
        call s:minimap_buffer_enter_handler()
    elseif &buftype !=# 'terminal'
        call s:source_buffer_enter_handler()
    endif
endfunction

function! s:cursor_move_handler() abort
    if &filetype ==# 'minimap'
        call s:minimap_move()
    else
        call s:source_move()
    endif
endfunction

function! s:win_enter_handler() abort
    if &filetype ==# 'minimap'
        call s:minimap_win_enter()
    else
        call s:source_win_enter()
    endif
endfunction

function! s:tab_leave_handler() abort
    " Nuke our state - we don't keep a per-tab cache so we need to rebuild on
    " any tab change
    let s:last_pos = {}
    let s:last_range = {}
    let s:win_info = {}
    let s:len_cache = {}
endfunction

function! s:get_longest_line_cmd() abort
    if has('mac')
        return 'gwc'
    endif
    return 'wc'
endfunction

let s:bin_dir = expand('<sfile>:p:h:h:h').'/bin/'
if has('win32')
    let s:minimap_gen = s:bin_dir.'minimap_generator.bat'
    let s:default_shell = 'cmd.exe'
    let s:default_shellflag = '/s /c'
else
    let s:minimap_gen = s:bin_dir.'minimap_generator.sh'
    let s:default_shell = 'sh'
    let s:default_shellflag = '-c'
endif
let s:minimap_cache = {}

function! s:toggle_window() abort
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr != -1
        call s:close_window()
        return
    endif

    call s:open_window()
endfunction

function! s:close_window() abort
    call s:clear_highlights()
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        if winbufnr(2) != -1
            " Other windows are open, only close this one
            close
            exe 'wincmd p'
        endif
    else
        exe mmwinnr . 'wincmd c'
    endif
    let s:win_info = {}
endfunction

function! s:quit_last() abort
    let tabnum = tabpagenr()
    if tabnum == tabpagenr('$') && tabnum == 1
        doautocmd ExitPre,VimLeavePre,VimLeave
    endif
    let s:win_info = {}
    execute 'quit'
endfunction

function! s:close_auto() abort
    if winnr('$') == 3 && exists('g:coc_last_float_win') && win_id2win(g:coc_last_float_win) != 0
        " This addresses an issue where the minimap will not close
        " if CoC has a diagnostic window open - GH-74
    elseif winnr('$') != 1
        return
    endif

    if g:minimap_did_quit
        silent! call s:quit_last()
    else
        " Since we just closed a buffer, we want to completely wipe out
        " the minimap tied to that buffer.
        bwipeout
    endif
    " In case the plugin accidentally highlights the main buffer.
    call s:clear_highlights()
endfunction

function! s:open_window() abort
    " If the minimap window is already open jump to it
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr != -1 || s:closed_on() || s:ignored() " Don't open if file/buftype is ignored/closed on
        return
    endif

    let g:minimap_opening = 1 " Used to lock out autocmds, otherwise we get multiple fires that take a long time

    " Preserve 'previous buffer' when opening the minimap
    let prev_buffer = bufnr('#')
    let curr_buffer = bufnr()

    let openpos = g:minimap_left ? 'topleft vertical ' : 'botright vertical '
    noautocmd execute 'silent! ' . openpos . g:minimap_width . 'split ' . '-MINIMAP-'

    " Buffer-local options
    setlocal filetype=minimap
    setlocal noreadonly " in case the "view" mode is used
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal textwidth=0
    " Window-local options
    setlocal nolist
    setlocal winfixwidth
    setlocal nospell
    setlocal nowrap
    setlocal nonumber
    setlocal nofoldenable
    setlocal foldcolumn=0
    setlocal foldmethod&
    setlocal foldexpr&
    setlocal nocursorline
    silent! setlocal signcolumn=no
    silent! setlocal norelativenumber
    silent! setlocal sidescrolloff=0

    let cpoptions_save = &cpoptions
    set cpoptions&vim

    augroup MinimapAutoCmds
        autocmd!
        autocmd QuitPre *                                       let g:minimap_did_quit = 1
        autocmd WinEnter <buffer>                               call s:handle_autocmd(0)
        autocmd WinEnter *                                      call s:handle_autocmd(1)
        autocmd BufWritePost,VimResized *                       call s:handle_autocmd(2)
        autocmd BufEnter,FileType *                             call s:handle_autocmd(3)
        autocmd FocusGained,CursorMoved,CursorMovedI <buffer>   call s:handle_autocmd(4)
        if g:minimap_highlight_range
            " Vim and Neovim (pre-November 2020) do not have a WinScrolled autocmd event.
            if exists('##WinScrolled')
                autocmd FocusGained,WinScrolled *               call s:handle_autocmd(5)
            else
                autocmd FocusGained,CursorMoved,CursorMovedI *  call s:handle_autocmd(5)
            endif
        endif
        autocmd FocusGained,CursorMoved,CursorMovedI *          call s:handle_autocmd(6)
        if g:minimap_highlight_search != 0
            autocmd CmdlineLeave * if expand('<afile>') == '/' || expand('<afile>') == '?' |
                        \ call s:minimap_update_color_search(getcmdline())
        endif
        autocmd VimEnter,DiffUpdated *                          call s:handle_autocmd(7)
        autocmd TabLeave *                                      call s:handle_autocmd(8)
    augroup END

    " https://github.com/neovim/neovim/issues/6211
    noremap <buffer> <ScrollWheelUp>     k
    noremap <buffer> <2-ScrollWheelUp>   k
    noremap <buffer> <3-ScrollWheelUp>   k
    noremap <buffer> <4-ScrollWheelUp>   k
    noremap <buffer> <ScrollWheelDown>   j
    noremap <buffer> <2-ScrollWheelDown> j
    noremap <buffer> <3-ScrollWheelDown> j
    noremap <buffer> <4-ScrollWheelDown> j

    let &cpoptions = cpoptions_save

    execute 'wincmd p'
    call s:refresh_minimap(1)
    call s:get_window_info() " Must call after refresh_minimap so we can get the mm height after creation
    call s:update_highlight()

    " Restore buffer orders
    execute(prev_buffer . 'buffer')
    execute(curr_buffer . 'buffer')

    let g:minimap_opening = 0
endfunction

function! s:handle_autocmd(cmd) abort
    if g:minimap_opening == 0
        if s:closed_on()
            let mmwinnr = bufwinnr('-MINIMAP-')
            if mmwinnr != -1
                call s:close_window()
            endif
        elseif s:ignored()
            return
        elseif a:cmd == 0           " WinEnter <buffer>
            " echom 'WinEnter <buffer>'
            call s:close_auto()
        elseif a:cmd == 1           " WinEnter *
            " echom 'WinEnter *'
            " If previously triggered minimap_did_quit, untrigger it
            let g:minimap_did_quit = 0
            call s:win_enter_handler()
        elseif a:cmd == 2           " BufWritePost,VimResized *
            " echom 'BufWritePost,VimResized *'
            call s:refresh_minimap(1)
            call s:update_highlight()
        elseif a:cmd == 3           " BufEnter,FileType *
            " echom 'BufEnter,FileType *'
            call s:buffer_enter_handler()
        elseif a:cmd == 4           " FocusGained,CursorMoved,CursorMovedI <buffer>
            " echom 'FocusGained,CursorMoved,CursorMovedI <buffer>'
            call s:minimap_move()
        elseif a:cmd == 5           " FocusGained,WinScrolled * (neovim); else same autocmds as below
            " echom 'FocusGained,WinScrolled * (neovim); else same autocmds as below'
            call s:source_win_scroll()
        elseif a:cmd == 6           " FocusGained,CursorMoved,CursorMovedI *
            " echom 'FocusGained,CursorMoved,CursorMovedI *'
            call s:source_move()
        elseif a:cmd == 7           " VimEnter,DiffUpdated *
            " echom 'VimEnter,DiffUpdated *'
            call s:minimap_diffoff()
        elseif a:cmd == 8           " TabLeave *
            echom 'TabLeave *'
            call s:tab_leave_handler()
        endif
    endif
endfunction

function! s:ignored() abort
    return &filetype !=# 'minimap' &&
                \ (
                \   index(g:minimap_block_buftypes,  &buftype)  >= 0 ||
                \   index(g:minimap_block_filetypes, &filetype) >= 0
                \ )
endfunction

function! s:closed_on() abort
    return &filetype !=# 'minimap' &&
                \ (
                \   index(g:minimap_close_buftypes,  &buftype)  >= 0 ||
                \   index(g:minimap_close_filetypes, &filetype) >= 0
                \ )
endfunction

function! s:refresh_minimap(force) abort
    if &filetype ==# 'minimap'
        execute 'wincmd p'
    endif

    let bufnr = bufnr('%')
    let fname = fnamemodify(bufname('%'), ':p')
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    call s:get_window_info()
    if a:force || !has_key(s:minimap_cache, bufnr) ||
                \ s:minimap_cache[bufnr].mtime != getftime(fname)
        call s:generate_minimap(mmwinnr, bufnr, fname, &filetype)
    endif
    call s:render_minimap(mmwinnr, bufnr, fname, &filetype)
endfunction

function! s:generate_minimap(mmwinnr, bufnr, fname, ftype) abort
    if !exists('s:win_info') || s:win_info == {}
        call s:get_window_info()
    endif

    " No file will result in an empty win_info, bail out early
    if s:win_info == {}
        return
    endif

    let hscale = string(2.0 * g:minimap_width / s:win_info['working_width'])
    let vscale = string(4.0 * winheight(s:win_info['mmwinid']) / line('$'))

    " Users that have custom shells and shell flags may face problems.
    let usershell = &shell
    let userflag = &shellcmdflag
    let &shell = s:default_shell
    let &shellcmdflag = s:default_shellflag
    let minimap_cmd = '"'.s:minimap_gen.'"'
    if has('nvim')
        let minimap_cmd = 'w !'.minimap_cmd.' '.hscale.' '.vscale.' '.g:minimap_width
        " echom minimap_cmd
        let minimap_output = execute(minimap_cmd) " Not work for vim 8.2 ?
    else
        let minimap_cmd = minimap_cmd.' '.hscale.' '.vscale.' '.g:minimap_width
        " echom minimap_cmd
        let minimap_output = system(minimap_cmd, join(getline(1, '$'), "\n"))
    endif

    " Recover the user's selected shell and flag.
    let &shell = usershell
    let &shellcmdflag = userflag

    if v:shell_error
        " print error message if file exists
        if filereadable(expand('%'))
            let msg = 'minimap: could not generate minimap for ' . a:fname
            call s:print_warning_msg(msg)
            if !empty(minimap_output)
                call s:print_warning_msg(minimap_output)
            endif
        endif
        return
    endif

    let cache = {}
    let cache.mtime = getftime(a:fname)
    let cache.content = minimap_output
    let s:minimap_cache[a:bufnr] = cache
endfunction

function! s:print_warning_msg(msg) abort
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

function! s:render_minimap(mmwinnr, bufnr, fname, ftype) abort
    if !has_key(s:minimap_cache, a:bufnr)
        return
    endif

    let curwinview = winsaveview()
    execute a:mmwinnr . 'wincmd w'
    setlocal modifiable

    let cache = s:minimap_cache[a:bufnr]

    silent 1,$delete _
    silent put =cache.content
    if has('nvim')
        silent 1,3delete _
    else
        silent 1delete _
    endif

    if g:minimap_base_highlight !=# 'Normal'
        silent! call matchdelete(g:minimap_base_matchid)
        call matchadd(g:minimap_base_highlight, '.*', 10, g:minimap_base_matchid)
    endif

    setlocal nomodifiable
    execute 'wincmd p'
    call winrestview(curwinview)
endfunction

function! s:source_move() abort
    if !exists('s:win_info["mmwinid"]') || win_getid() == s:win_info['mmwinid']
        return
    endif

    let curr = line('.') - 1
    let pos = s:buffer_to_map(curr, s:win_info['height'], s:win_info['mm_height'])

    if s:last_pos != pos
        let this_table = s:make_state_table_with_position(pos)

        call s:render_highlight_table(this_table)
        let s:last_pos = pos
    endif
endfunction

" Only called if g:minimap_highlight_range is set.
function! s:source_win_scroll() abort
    if !exists('s:win_info["mmwinid"]') || win_getid() == s:win_info['mmwinid']
        return
    endif

    let range = s:get_highlight_range(s:win_info)

    if s:last_range['pos1'] == range['pos1'] && s:last_range['pos2'] == range['pos2']
        " Range is the same, no need to update anything
        return
    endif

    let this_table = s:make_state_table_with_range(range)

    call s:render_highlight_table(this_table)
    let s:last_range = range
endfunction

" Pos is the new minimap line we are on
function! s:make_state_table_with_position(pos) abort
    let this_table = {}

    " Clear cursor state for last pos
    let current_info = get(g:minimap_line_state_table, s:last_pos, {})
    let current_state = get(current_info, 'state')
    let this_table[s:last_pos] = {'state': and(current_state, invert(s:STATE_CURSOR)) }

    " Set cursor state for new pos
    let current_info = get(g:minimap_line_state_table, a:pos, {})
    let current_state = get(current_info, 'state')
    let this_table[a:pos] = {'state': or(current_state, s:STATE_CURSOR) }

    return this_table
endfunction

" Build the update map - only includes lines that have changed
" Optional parameter is a table to integrate into the one we are building.
" Intended for use with states where both can exist without causing an issue
" (eg. CURSOR and RANGE states).
function! s:make_state_table_with_range(range,...) abort
    let this_table = {}

    " Only do items outside the last range
    " (everything else is the same, so don't waste time updating it)
    " Clear out the range state
    for mm_line_num in range(s:last_range['pos1'], s:last_range['pos2'])
        if mm_line_num < a:range['pos1'] || mm_line_num > a:range['pos2']
            if a:0 >= 1 && has_key(a:1, mm_line_num)
                let current_state = a:1[mm_line_num]['state']
            else
                let current_info = get(g:minimap_line_state_table, mm_line_num, {})
                let current_state = get(current_info, 'state')
            endif
            let this_table[mm_line_num] = {'state': and(current_state, invert(s:STATE_WINDOW_RANGE)) }
        endif
    endfor
    " Separate for loops, to account for the case when jumping around file
    " would result in processing a bunch of lines that we never touched
    " Add the range state
    for mm_line_num in range(a:range['pos1'], a:range['pos2'])
        if mm_line_num < s:last_range['pos1'] || mm_line_num > s:last_range['pos2']
            if a:0 >= 1 && has_key(a:1, mm_line_num)
                let current_state = a:1[mm_line_num]['state']
            else
                let current_info = get(g:minimap_line_state_table, mm_line_num, {})
                let current_state = get(current_info, 'state')
            endif
            let this_table[mm_line_num] = {'state': or(current_state, s:STATE_WINDOW_RANGE) }
        endif
    endfor

    " Merge items from the passed in table if it wasn't addressed in the loop above.
    if a:0 >= 1
        for mm_line_num in keys(a:1)
            if !has_key(this_table, mm_line_num)
                let this_table[mm_line_num] = { 'state': a:1[mm_line_num]['state'] }
            endif
        endfor
    endif

    return this_table
endfunction

function! s:get_highlight_range(win_info) abort
    let startln = line('w0') - 1
    let endln = line('w$') - 1
    let pos1 = s:buffer_to_map(startln, a:win_info['height'], a:win_info['mm_height'])
    let pos2 = s:buffer_to_map(endln, a:win_info['height'], a:win_info['mm_height'])
    return { 'pos1': pos1, 'pos2': pos2 }
endfunction

" We expect to get 2 things from the background worker, separated by newlines:
" 1) The filename that was checked
" 2) The number of characters in the longest line (currently expecting ascii
"    characters, multibyte characters haven't seen any testing)
"
" This event function collects the output we have gotten from the worker.
" Information may arrive all chunked up, so the collection step is required,
" see: https://neovim.io/doc/user/job_control.html
" After the program exits, we set the cached length. Following symlinks will
" result in multiple file names being checked, even though they are the same
" file. (aside: That may have been part of the reason the original 'get the
" length inline' strategy was so slow.)
" Once we have the cached length set, we do a hard refresh of the minimap,
" which will now find a cached length value and won't spawn another job for
" this file.
" All of this results in the minimap 'popping in', but the tradeoff is we are
" no longer blocking the file open to scan for the longest line.
let s:chunks = ['']
function! s:background_worker_event(job_id, data, event) dict abort
    if a:event ==? 'stdout'
        " echom 'received callback stdout: '.join(a:data)
        let s:chunks[-1] .= a:data[0]
        call extend(s:chunks, a:data[1:])
    elseif a:event ==? 'stderr'
        " echom 'received callback stderr: '.join(a:data)
    elseif a:event ==? 'exit'
        " Have the data, parse then call the set function
        " echom 'received callback exit '.join(s:chunks)

        " Parse each line into the number of lines + filename. wc -L gives
        " <length of longest line> <filename>

        for chunk in s:chunks
            " echom 'doing ' . len(s:chunks) . '(' . chunk . ')'
            if len(chunk) == 0
                continue
            endif

            let splits = split(chunk, ' ')
            let longest = splits[0]
            let file_name = join(splits[1:], ' ')

            " echom 'adding [' . file_name . '] val [' . str2nr(longest) .']'
            let s:len_cache[file_name] = str2nr(longest)
        endfor
        let g:minimap_getting_window_info = 0
        call s:refresh_minimap(1)
        call s:update_highlight()
    endif
endfunction
let s:callbacks = {
\ 'on_stdout': function('s:background_worker_event'),
\ 'on_stderr': function('s:background_worker_event'),
\ 'on_exit': function('s:background_worker_event')
\ }

function! s:get_window_info() abort
    " This function moves to the minimap to get info, which will trigger
    " autocmds set up to catch switching windows. Protect with a mutex so it
    " only runs one time.
    if g:minimap_getting_window_info == 0
        let g:minimap_getting_window_info = 1
        let mmwinnr = bufwinnr('-MINIMAP-')
        if mmwinnr == -1
            let g:minimap_getting_window_info = 0
            return {}
        endif

        if winnr() == mmwinnr
            let g:minimap_getting_window_info = 0
            return {}
        endif

        let filename = expand('%')
        " echom 'checking filename [' . filename .']'
        if filename == ''
            let g:minimap_getting_window_info = 0
            return {}
        endif

        let curwinview = winsaveview()

        let mmwinid = win_getid(mmwinnr)
        let height = line('$')
        let max_width = 0
        " Get the max width of this buffer. Value is cached so this only runs
        " on first open of any file. This means significant changes to the
        " file may result in an inaccurate minimap, but the tradeoff is worth
        " it. This cache only lasts for the life of this vim instance, so it
        " will be updated with each new open.
        if has_key(s:len_cache, filename)
            let max_width = s:len_cache[filename]
        elseif g:minimap_background_processing == 0
            let line_num = 1
            while line_num <= line('$')
                call setpos('.', [0, line_num, 1])
                " Move cursor to the last non-blank character on the line
                normal! g_
                let max_width = max([max_width, col('.')])
                let line_num = line_num + 1
            endwhile
            let s:len_cache[filename] = max_width
        else
            " Make sure the file exists
            if filereadable(filename)
                " Spawn a job to get the longest line
                let longest_line_cmd = s:get_longest_line_cmd()
                let s:job_id = jobstart([longest_line_cmd, '-L', filename], s:callbacks)
            else
                " If not, don't spawn a job, it will freak out. We know
                " there's nothing there, so let 0 ride.
            endif
        endif
        " Let users override the max width. By default, this does nothing.
        let working_width = min([max_width, g:minimap_window_width_override_for_scaling])
        " Protect against divide by 0 or negative hscale - working_width must be > 0
        let working_width = max([working_width, 1])

        " Go to the minimap
        call win_gotoid(mmwinid)
        let mm_height = line('w$')
        let mm_max_width = 0
        if g:minimap_highlight_search
            " Get max width of the minimap (characters, not window)
            let line_num = 1
            while line_num <= line('$')
                call setpos('.', [0, line_num, 1])
                " Move cursor to the last non-blank character on the line
                normal! g_
                let mm_max_width = max([mm_max_width, col('.')])
                let line_num = line_num + 1
            endwhile

            " Scale to cursor positions, not bytes
            let mm_max_width = (mm_max_width / 3) + 1
            " The window can be smaller than the max width, so rail to the smaller
            " value.
            let mm_max_width = min([mm_max_width, g:minimap_width])
            " echom 'max_width, mm_max_width: ' . join([max_width, mm_max_width])
        endif

        " Go back to previous window and reset the view
        execute 'wincmd p'
        call winrestview(curwinview)

        if has_key(s:len_cache, filename)
            let g:minimap_getting_window_info = 0
        endif
        let s:win_info = { 'mmwinid': mmwinid,
                    \ 'height': height, 'mm_height': mm_height,
                    \ 'working_width': working_width, 'mm_max_width': mm_max_width }
    endif
endfunction

" botline is broken and this works.  However, it's slow, so we call this function less.
" Remove this function when `getwininfo().botline` is fixed. <- still relevent?
" This function builds a new line state table from scratch, clearing out the
" old one.
function! s:update_highlight(...) abort
    if s:win_info == {}
        return
    endif

    " For unit tests. Very little overhead so not gating it
    let g:minimap_run_update_highlight_count = g:minimap_run_update_highlight_count + 1

    " Search does its own sub-line highlighting
    if g:minimap_highlight_search
        let his_idx = 2
        if a:0 > 0 && a:1 ==? 'source_buffer_enter_handler'
            let his_idx = 1
        endif
        call s:minimap_color_search(s:win_info, his_idx)
    endif

    " Clear all table highlights (search handles its own)
    for key in keys(g:minimap_line_state_table)
        silent! call matchdelete(g:minimap_line_state_table[key]['id'], s:win_info['mmwinid'])
    endfor

    " Build the global highlight state table
    let g:minimap_line_state_table = {}
    " Cursor
    let curr = line('.') - 1
    let pos = s:buffer_to_map(curr, s:win_info['height'], s:win_info['mm_height'])
    let current_info = get(g:minimap_line_state_table, pos, {})
    let current_state = get(current_info, 'state')
    let g:minimap_line_state_table[pos] = { 'state': or(current_state, s:STATE_CURSOR) }
    let s:last_pos = pos
    " Range
    if g:minimap_highlight_range
        let pos_range =  s:get_highlight_range(s:win_info)
        for mm_line_number in range(pos_range['pos1'], pos_range['pos2'])
            let current_info = get(g:minimap_line_state_table, mm_line_number, {})
            let current_state = get(current_info, 'state')
            let g:minimap_line_state_table[mm_line_number] = {'state': or(current_state, s:STATE_WINDOW_RANGE) }
        endfor
        let s:last_range = pos_range
    endif

    if g:minimap_git_colors
        call s:minimap_color_git(s:win_info)
    endif

    " Render the state map
    call s:render_highlight_table(g:minimap_line_state_table)
endfunction

function! s:render_highlight_table(table) abort
    if s:win_info == {}
        return
    endif
    let mmwinid = s:win_info['mmwinid']

    " Loop over all entries of the passed in table
    for [mm_line_number, info] in items(a:table)
        " Need to clear out the previous highlight here - if a highlight already
        " exists (ex. cursor -> range), we will lose the ID of the old match and
        " won't be able to delete it
        if exists("g:minimap_line_state_table[mm_line_number]['id']")
            silent! call matchdelete(g:minimap_line_state_table[mm_line_number]['id'], mmwinid)
        endif

        " Request to remove from the table.
        if info['state'] == 0
            silent! call matchdelete(g:minimap_line_state_table[mm_line_number]['id'], mmwinid)
            silent! unlet! g:minimap_line_state_table[mm_line_number]
            continue
        endif

        "
        " Bit mask to check states - Order matters for priority
        "

        " Cursor + Diff
        if and(info['state'], or(s:STATE_CURSOR, s:STATE_DIFF_RM)) == or(s:STATE_CURSOR, s:STATE_DIFF_RM)
            let line_color = g:minimap_cursor_diffremove_color
        elseif and(info['state'], or(s:STATE_CURSOR, s:STATE_DIFF_ADD)) == or(s:STATE_CURSOR, s:STATE_DIFF_ADD)
            let line_color = g:minimap_cursor_diffadd_color
        elseif and(info['state'], or(s:STATE_CURSOR, s:STATE_DIFF_MOD)) == or(s:STATE_CURSOR, s:STATE_DIFF_MOD)
            let line_color = g:minimap_cursor_diff_color

        " Range + Diff
        elseif and(info['state'], or(s:STATE_WINDOW_RANGE, s:STATE_DIFF_RM)) == or(s:STATE_WINDOW_RANGE, s:STATE_DIFF_RM)
            let line_color = g:minimap_range_diffremove_color
        elseif and(info['state'], or(s:STATE_WINDOW_RANGE, s:STATE_DIFF_ADD)) == or(s:STATE_WINDOW_RANGE, s:STATE_DIFF_ADD)
            let line_color = g:minimap_range_diffadd_color
        elseif and(info['state'], or(s:STATE_WINDOW_RANGE, s:STATE_DIFF_MOD)) == or(s:STATE_WINDOW_RANGE, s:STATE_DIFF_MOD)
            let line_color = g:minimap_range_diff_color

        " Diff
        elseif and(info['state'], s:STATE_DIFF_RM) == s:STATE_DIFF_RM
            let line_color = g:minimap_diffremove_color
        elseif and(info['state'], s:STATE_DIFF_ADD) == s:STATE_DIFF_ADD
            let line_color = g:minimap_diffadd_color
        elseif and(info['state'], s:STATE_DIFF_MOD) == s:STATE_DIFF_MOD
            let line_color = g:minimap_diff_color

        " Cursor
        elseif and(info['state'], s:STATE_CURSOR) == s:STATE_CURSOR
            let line_color = g:minimap_cursor_color

        " Range
        elseif and(info['state'], s:STATE_WINDOW_RANGE) == s:STATE_WINDOW_RANGE
            let line_color = g:minimap_range_color

        " Catcher
        else
            " Error, everything should be accounted for above
            echom 'Error rendering highlights, missing state catcher: ' . info['state']
            continue
        endif

        let id = matchaddpos(line_color, [str2nr(mm_line_number)], g:minimap_cursor_color_priority, -1, { 'window': mmwinid })
        let g:minimap_line_state_table[mm_line_number] = { 'state': info['state'], 'id': id }
    endfor
endfunction

" Translates a position in a buffer to its respective position in the map.
function! minimap#vim#BufferToMap(lnnum, buftotal, mmtotal) abort
    return s:buffer_to_map(a:lnnum, a:buftotal, a:mmtotal)
endfunction
function! s:buffer_to_map(lnnum, buftotal, mmtotal) abort
    return float2nr(1.0 * a:lnnum / a:buftotal * a:mmtotal) + 1
endfunction

" Clears the specified match id list
function! s:clear_id_list_colors(mmwinid, id_list) abort
    for id in a:id_list
        silent! call matchdelete(id, a:mmwinid) " require vim 8.1.1084+ or neovim 0.5.0+
    endfor
endfunction

" Clears matches of current window only.
function! s:clear_highlights() abort
    silent! call clearmatches(s:win_info['mmwinid'])
    let g:minimap_search_id_list = []
endfunction

function! s:minimap_move() abort
    if s:win_info == {}
        call s:get_window_info()
        if s:win_info == {}
            echom 'Could not populate s:win_info, exiting'
        endif
    endif
    let curr = line('.')

    execute 'wincmd p'
    " Position cursor at the top line of this mm block
    let pos = float2nr(1.0 * (curr-1) / s:win_info['mm_height'] * s:win_info['height']) + 2
    execute pos
    if g:minimap_highlight_range
        let range =  s:get_highlight_range(s:win_info)
    endif
    execute 'wincmd p'

    let this_table = s:make_state_table_with_position(curr)
    if g:minimap_highlight_range
        let this_table = s:make_state_table_with_range(range, this_table)
    endif

    call s:render_highlight_table(this_table)

    let s:last_pos = curr
    if g:minimap_highlight_range
        let s:last_range = range
    endif
endfunction

function! s:minimap_win_enter() abort
    " do nothing
endfunction

function! s:source_win_enter() abort
    call s:get_window_info()
    call s:update_highlight()
endfunction

function! s:minimap_buffer_enter_handler() abort
    " Move the cursor to where we were in the main buffer. Without this it
    " jumps to the top of the minimap
    call cursor(s:last_pos, 1)
endfunction

function! s:source_buffer_enter_handler() abort
    silent! call clearmatches(s:win_info['mmwinid'])
    call s:refresh_minimap(0)
    call s:update_highlight('source_buffer_enter_handler')
endfunction

function! s:minimap_diffoff() abort
    if s:win_info == {}
        return
    endif
    let mmwinid = s:win_info['mmwinid']
    silent! call win_execute(mmwinid, 'diffoff')
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Git Stuff
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! minimap#vim#MinimapParseGitDiffLine(line, buffer_lines, mm_height) abort
    return s:minimap_parse_git_diff_line(a:line, a:buffer_lines, a:mm_height)
endfunction
function! s:minimap_parse_git_diff_line(line, buffer_lines, mm_height) abort
    let this_diff = {}

    let blobs = split(a:line, ' ')
    let del_info = blobs[1]
    let add_info = blobs[2]

    " Parse newfile info
    let add_info = split(add_info, ',')
    let add_start = str2nr(add_info[0])
    let add_len = 1
    if len(add_info) > 1
        let add_len = abs(str2nr(add_info[1]))
    endif
    " Parse oldfile info
    let del_info = split(del_info, ',')
    let del_len = 1
    if len(del_info) > 1
        let del_len = abs(str2nr(del_info[1]))
    endif

    " Get diff type + end line
    let this_diff['start'] = add_start
    let this_diff['end'] = this_diff['start'] + add_len
    if add_len != 0 && del_len != 0
        let this_diff['color'] = g:minimap_diff_color
    elseif add_len != 0
        let this_diff['color'] = g:minimap_diffadd_color
    elseif del_len != 0
        let this_diff['color'] = g:minimap_diffremove_color
        let this_diff['end'] = this_diff['start']
    else
        let this_diff['color'] = g:minimap_diff_color
        let this_diff['end'] = this_diff['start']
    endif

    " Map locations to minimap
    " echom 'buf: ' . join([this_diff['start'], this_diff['end']])
    let this_diff['start'] = s:buffer_to_map(this_diff['start'] - 1, a:buffer_lines, a:mm_height)
    let this_diff['end']   = s:buffer_to_map(this_diff['end']   - 1, a:buffer_lines, a:mm_height)
    " echom 'mm : ' . join([this_diff['start'], this_diff['end']])

    return this_diff
endfunction

function! s:minimap_color_git(win_info) abort
    " Get git info
    let git_call = 'git diff -U0 -- ' . expand('%')
    let git_diff = substitute(system(git_call), '\n\+&', '', '') | silent echo strtrans(git_diff)

    let lines = split(git_diff, '\n')
    let diff_list = []
    for line in lines
        if line[0] ==? '@'
            let this_diff = s:minimap_parse_git_diff_line(line,
                        \ a:win_info['height'], a:win_info['mm_height'])
            " Add to list
            let diff_list = add(diff_list, this_diff)
        endif
    endfor

    " Color lines, creating a new id for each section
    for a_diff in diff_list
        let idx = a_diff['start']
        while idx <= a_diff['end']
            " Override the other diff states
            let current_info = get(g:minimap_line_state_table, idx, {})
            let current_state = and(get(current_info, 'state'), invert(or(s:STATE_DIFF_RM, or(s:STATE_DIFF_ADD, s:STATE_DIFF_MOD))))
            let g:minimap_line_state_table[idx] = { 'state': or(current_state, s:get_diff_state_flag(a_diff['color'])) }
            let idx = idx+1
        endwhile
    endfor
endfunction

function! s:get_diff_state_flag(state) abort
    if a:state == g:minimap_diffremove_color
        return s:STATE_DIFF_RM
    elseif a:state == g:minimap_diffadd_color
        return s:STATE_DIFF_ADD
    elseif a:state == g:minimap_diff_color
        return s:STATE_DIFF_MOD
    endif

    return 0xFFFF
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search Highlight Stuff
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! minimap#vim#ClearColorSearch() abort
    if exists('g:minimap_search_id_list')
        if s:win_info != {}
            call s:clear_id_list_colors(s:win_info['mmwinid'], g:minimap_search_id_list)
            let g:minimap_search_id_list = []
        endif
    endif
endfunction
function! minimap#vim#UpdateColorSearch(query) abort
    call s:minimap_update_color_search(a:query)
endfunction

function! s:minimap_update_color_search(query) abort
    if s:win_info != {} && win_getid() != s:win_info['mmwinid']
        call s:minimap_color_search(s:win_info, a:query)
    endif
endfunction

" Hook function for unit tests
function! minimap#vim#MinimapColorSearchGetSpans(win_info, query) abort
    return s:minimap_color_search_get_spans(a:win_info, a:query)
endfunction
" Query argument is either the query string, or a number representing how far
" back into the search history we need to grab (it varies by context)
function! s:minimap_color_search_get_spans(win_info, query) abort
    " Get the last search the user searched for
    if type(a:query) != type(0)
        let last_search = a:query
    else
        let tmp = split(execute('his /'), '\n')
        let tmp = split(tmp[len(tmp)-a:query], '', 1)
        " echom 'tmp: ' . join(tmp)
        let last_search = join(tmp[2:-1])
    endif
    " echom 'last_search: ' . last_search

    " Save the current view so we can return to it after searching
    let curwinview = winsaveview()
    " Start at top, save all match positions until we hit the bottom
    call cursor(1, 1)
    " The 'c' in this string lets the search match at the current cursor
    " position. We need this for the first search to catch the very first
    " character in the file, but we need to exclude it from all future
    " searches, since the cursor will be moved to the start of each match.
    let search_options_string = 'czW'
    " Loop and get locations of all matches
    let locations = []
    let done = 0
    while done == 0
        let start_location = searchpos(last_search, search_options_string)
        if start_location != [0, 0]
            call searchpos(last_search, 'cezW')
            let end_cursor = getpos('.')
            let end_location = [end_cursor[1], end_cursor[2]]
            if start_location[0] != end_location[0]
                " Not equipped to handle matches that span more than one line
                " yet, just skip it for now.
                continue
            endif
            if end_location[1] < start_location[1]
                " Error - end not farther than start. Abort.
                echom 'Error looking for matches: end_location: [' . end_location[1] . '] is less than start_location: [' . start_location[1] . ']. Aborting'
                break
            endif
            let match_len = end_location[1] - start_location[1]
            let this_location = {}
            let this_location['line'] = start_location[0]
            let this_location['col'] = start_location[1]
            let this_location['match_len'] = match_len
            call add(locations, this_location)
            let this_location = {}
            let search_options_string = 'zW'
        else
            let done = 1
        endif
    endwhile
    " Restore window view
    call winrestview(curwinview)

    " Convert all positions to mm
    let mm_spans = []
    for this_location in locations
        let mm_line = s:buffer_to_map(this_location['line'] - 1, a:win_info['height'], a:win_info['mm_height'])
        " Braille takes 3 bytes when using UTF-8. Column position is specified
        " in number of bytes offset, so to calculate horizontal position to
        " pass to the highlighting function, we need to multiply by 3
        let mm_col = 3 * (s:buffer_to_map(this_location['col'] - 1,       a:win_info['working_width'], a:win_info['mm_max_width']))
        let mm_len = 3 * (s:buffer_to_map(this_location['match_len'] - 1, a:win_info['working_width'], a:win_info['mm_max_width']))
        " If we don't land directly on an integer value of ([byte length]x + 1),
        " the highlight will not show up. Make sure the values land in those
        " bins. Above scaling gives 3 as a minimum. We take off any
        " remainder, then bump it down to the leftmost column (which is
        " offset by 1, hence the -2)
        let mm_col = (mm_col - (mm_col % 3)) - 2
        " echom 'buf: ' . join([this_location['line'], this_location['col'], this_location['match_len']])
        " echom 'mm : ' . join([mm_line, mm_col, mm_len])
        call add(mm_spans, [mm_line, mm_col, mm_len])
    endfor

    return mm_spans
endfunction

function! s:minimap_color_search(win_info, query) abort
    if eval('v:hlsearch') == 0 || eval('&hlsearch') == 0
        " Don't bother doing anything if any search highlighting is turned off
        return
    endif

    let mm_spans = s:minimap_color_search_get_spans(a:win_info, a:query)

    " Clear old colors before writing new ones
    call s:clear_id_list_colors(a:win_info['mmwinid'], g:minimap_search_id_list)
    let g:minimap_search_id_list = []
    " Color lines, creating a new id for each group
    for a_span in mm_spans
        " span_list item: [line_number, column_number, length]
        call add(g:minimap_search_id_list, s:get_next_search_matchid())
        call s:set_span_color(g:minimap_search_color, [a_span],
            \ g:minimap_search_color_priority, g:minimap_search_id_list[-1], a:win_info['mmwinid'])
    endfor
endfunction

function! s:set_span_color(set_color, spans, priority, match_id, mmwinid) abort
    call matchaddpos(a:set_color, a:spans, a:priority,
        \ a:match_id, { 'window': a:mmwinid })
endfunction


function! s:get_next_search_matchid() abort
    return g:minimap_search_matchid_safe_range + len(g:minimap_search_id_list)
endfunction
