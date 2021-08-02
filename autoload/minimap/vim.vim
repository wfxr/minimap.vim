" MIT (c) Wenxuan Zhang

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
endfunction

function! s:quit_last() abort
    let tabnum = tabpagenr()
    if tabnum == tabpagenr('$') && tabnum == 1
        doautocmd ExitPre,VimLeavePre,VimLeave
    endif
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
        bwipeout
    endif
    " In case the plugin accidentally highlights the main buffer.
    call s:clear_highlights()
endfunction

function! s:open_window() abort
    " If the minimap window is already open jump to it
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr != -1 || s:closed_on()   " Don't open if file/buftype is closed on
        return
    endif

    let g:minimap_opening = 1

    " Preserve 'previous buffer' when opening the minimap
    let prev_buffer = bufnr('#')
    let curr_buffer = bufnr()

    let openpos = g:minimap_left ? 'topleft vertical ' : 'botright vertical '
    noautocmd execute 'silent! ' . openpos . g:minimap_width . 'split ' . '-MINIMAP-'

    " Buffer-local options
    setlocal filetype=minimap
    setlocal noreadonly " in case the "view" mode is used
    setlocal buftype=nofile
    setlocal bufhidden=hide
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
        if g:minimap_highlight_range == 1
            " Vim and Neovim (pre-November 2020) do not have a WinScrolled autocmd event.
            if has('##WinScrolled')
                autocmd FocusGained,WinScrolled *               call s:handle_autocmd(5)
            else
                autocmd FocusGained,CursorMoved,CursorMovedI *  call s:handle_autocmd(5)
            endif
        else
            autocmd FocusGained,CursorMoved,CursorMovedI *      call s:handle_autocmd(6)
        endif
        if g:minimap_highlight_search != 0
            autocmd CmdlineLeave * if expand('<afile>') == '/' || expand('<afile>') == '?' |
                        \ call s:minimap_update_color_search(getcmdline())
        endif
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
            call s:close_auto()
        elseif a:cmd == 1           " WinEnter *
            " If previously triggered minimap_did_quit, untrigger it
            let g:minimap_did_quit = 0
            call s:win_enter_handler()
        elseif a:cmd == 2           " BufWritePost,VimResized *
            call s:refresh_minimap(1)
            call s:update_highlight()
        elseif a:cmd == 3           " BufEnter,FileType *
            call s:buffer_enter_handler()
        elseif a:cmd == 4           " FocusGained,CursorMoved,CursorMovedI <buffer>
            call s:minimap_move()
        elseif a:cmd == 5           " FocusGained,WinScrolled * (neovim); else same autocmds as below
            call s:source_win_scroll()
        elseif a:cmd == 6           " FocusGained,CursorMoved,CursorMovedI *
            call s:source_move()
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

    if a:force || !has_key(s:minimap_cache, bufnr) ||
                \ s:minimap_cache[bufnr].mtime != getftime(fname)
        call s:generate_minimap(mmwinnr, bufnr, fname, &filetype)
    endif
    call s:render_minimap(mmwinnr, bufnr, fname, &filetype)
endfunction

function! s:generate_minimap(mmwinnr, bufnr, fname, ftype) abort
    let winid = win_getid(a:mmwinnr)
    let hscale = string(2.0 * g:minimap_width / min([winwidth('%'), 120]))
    let vscale = string(4.0 * winheight(winid) / line('$'))

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

" Only called if g:minimap_highlight_range is not set.
function! s:source_move() abort
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        return
    endif

    let winid = win_getid(mmwinnr)
    let height = line('$')
    let mm_height = getwininfo(winid)[0].botline

    let curr = line('.') - 1
    let pos = s:buffer_to_map(curr, height, mm_height)
    call s:highlight_line(winid, pos)
endfunction

function! s:get_window_info() abort
    " This function moves to the minimap to get info, which will trigger
    " autocmds set up to catch switching windows. Put a mutex around this
    " function so it only runs once.
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
        let curwinview = winsaveview()

        let winid = win_getid(mmwinnr)
        let height = line('$')
        let max_width = 0
        if g:minimap_highlight_search
            " Get the max width of this buffer
            let line_num = 1
            while line_num <= line('$')
                call setpos('.', [0, line_num, 1])
                " Move cursor to the last non-blank character on the line
                normal! g_
                let max_width = max([max_width, col('.')])
                let line_num = line_num + 1
            endwhile
        endif

        " Go to the minimap
        call win_gotoid(winid)
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

        let g:minimap_getting_window_info = 0
        return {'winid': winid, 'height': height, 'mm_height': mm_height,
                    \ 'max_width': max_width, 'mm_max_width': mm_max_width}
    endif
    return {}
endfunction

" botline is broken and this works.  However, it's slow, so we call this function less.
" Remove this function when `getwininfo().botline` is fixed.
function! s:update_highlight() abort
    let win_info = s:get_window_info()
    if len(win_info) == 0
        return
    endif

    " For unit tests. Very little ovehead so not gating it
    let g:minimap_run_update_highlight_count = g:minimap_run_update_highlight_count + 1

    if g:minimap_highlight_range
        let startln = line('w0') - 1
        let endln = line('w$') - 1
        let pos1 = s:buffer_to_map(startln, win_info['height'], win_info['mm_height']) - 1
        let pos2 = s:buffer_to_map(endln, win_info['height'], win_info['mm_height']) + 1
        call s:highlight_range(win_info['winid'], pos1, pos2)
    else
        let curr = line('.') - 1
        let pos = s:buffer_to_map(curr, win_info['height'], win_info['mm_height'])
        call s:highlight_line(win_info['winid'], pos)
    endif

    if g:minimap_git_colors
        call s:minimap_color_git(win_info)
    endif
    if g:minimap_highlight_search
        call s:minimap_color_search(win_info, 2)
    endif
endfunction

" Translates a position in a buffer to its respective position in the map.
function! minimap#vim#BufferToMap(lnnum, buftotal, mmtotal) abort
    return s:buffer_to_map(a:lnnum, a:buftotal, a:mmtotal)
endfunction
function! s:buffer_to_map(lnnum, buftotal, mmtotal) abort
    return float2nr(1.0 * a:lnnum / a:buftotal * a:mmtotal) + 1
endfunction

function! s:highlight_line(winid, pos) abort
    call s:clear_id_list_colors(a:winid, g:minimap_range_id_list)
    let g:minimap_range_id_list = []
    call add(g:minimap_range_id_list, s:get_next_range_matchid())
    call s:set_line_color(g:minimap_highlight, a:pos,
        \ g:minimap_cursor_color_priority, g:minimap_range_id_list[-1], a:winid)
endfunction

function! s:highlight_range(winid, startpos, endpos) abort
    " Delete the old ones before drawing
    call s:clear_id_list_colors(a:winid, g:minimap_range_id_list)
    let g:minimap_range_id_list = []
    let idx = a:startpos
    while idx <= a:endpos
        call add(g:minimap_range_id_list, s:get_next_range_matchid())
        call matchaddpos(g:minimap_highlight, [idx], g:minimap_cursor_color_priority,
                    \ g:minimap_range_id_list[-1], { 'window': a:winid })
        let idx = idx+1
    endwhile
endfunction

" Clears the specified match id list
function! s:clear_id_list_colors(winid, id_list) abort
    for id in a:id_list
        silent! call matchdelete(id, a:winid) " require vim 8.1.1084+ or neovim 0.5.0+
    endfor
endfunction

" Manages doling out match ids based on list sizes
function! s:get_next_range_matchid() abort
    return g:minimap_range_matchid_safe_range + len(g:minimap_range_id_list)
endfunction

function! s:set_span_color(set_color, spans, priority, match_id, winid) abort
    call matchaddpos(a:set_color, a:spans, a:priority,
        \ a:match_id, { 'window': a:winid })
endfunction

function! s:set_line_color(set_color, pos, priority, match_id, winid) abort
    call matchaddpos(a:set_color, [a:pos], a:priority, a:match_id, { 'window': a:winid })
endfunction

" Clears matches of current window only.
function! s:clear_highlights() abort
    silent! call matchdelete(g:minimap_base_matchid)
    call s:clear_id_list_colors(winnr(), g:minimap_range_id_list)
    let g:minimap_range_id_list = []
    call s:clear_id_list_colors(winnr(), g:minimap_git_id_list)
    let g:minimap_git_id_list = []
    call s:clear_id_list_colors(winnr(), g:minimap_search_id_list)
    let g:minimap_search_id_list = []
endfunction

function! s:minimap_move() abort
    let mmwinnr = winnr()
    let curr = line('.')
    let mmlines = line('$')

    execute 'wincmd p'
    let pos = float2nr(1.0 * curr / mmlines * line('$'))
    execute pos
    execute 'wincmd p'
    let winid = win_getid(mmwinnr)
    call s:highlight_line(winid, curr)
endfunction

" Only called if g:minimap_highlight_range is set.
function! s:source_win_scroll() abort
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        return
    endif

    let winid = win_getid(mmwinnr)
    let height = line('$')
    let mm_height = getwininfo(winid)[0].botline

    let start = line('w0') - 1
    let end = line('w$') - 1
    " The -/+ 1 compensates for the exclusive ranges we use in the
    " patterns for matchadd.
    let pos1 = s:buffer_to_map(start, height, mm_height) - 1
    let pos2 = s:buffer_to_map(end, height, mm_height) + 1
    call s:highlight_range(winid, pos1, pos2)
endfunction

function! s:minimap_win_enter() abort
    execute 'wincmd p'
    let curr = line('.') - 1
    let srclines = line('$')
    execute 'wincmd p'
    let pos = float2nr(1.0 * curr / srclines * line('$')) + 1
    execute pos
    call s:minimap_move()
endfunction

function! s:source_win_enter() abort
    call s:update_highlight()
endfunction

function! s:minimap_buffer_enter_handler() abort
    " do nothing
endfunction

function! s:source_buffer_enter_handler() abort
    call s:refresh_minimap(0)
    call s:update_highlight()
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

    " Clear colors before writing new ones
    call s:clear_id_list_colors(a:win_info['winid'], g:minimap_git_id_list)
    let g:minimap_git_id_list = []
    " Color lines, creating a new id for each section
    for a_diff in diff_list
        let idx = a_diff['start']
        while idx <= a_diff['end']
            call add(g:minimap_git_id_list, s:get_next_git_matchid())
            call matchaddpos(a_diff['color'], [idx], g:minimap_git_color_priority,
                        \ g:minimap_git_id_list[-1], { 'window': a:win_info['winid'] })
            let idx = idx+1
        endwhile
    endfor
endfunction

function! s:get_next_git_matchid() abort
    return g:minimap_git_matchid_safe_range + len(g:minimap_git_id_list)
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search Highlight Stuff
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! minimap#vim#ClearColorSearch() abort
    if exists('g:minimap_search_id_list')
        let win_info = s:get_window_info()
        if win_info != {}
            call s:clear_id_list_colors(win_info['winid'], g:minimap_search_id_list)
            let g:minimap_search_id_list = []
        endif
    endif
endfunction
function! minimap#vim#UpdateColorSearch(query) abort
    call s:minimap_update_color_search(a:query)
endfunction

function! s:minimap_update_color_search(query) abort
    let win_info = s:get_window_info()
    if len(win_info) > 0
        call s:minimap_color_search(win_info, a:query)
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
                " Error - end not farther than start. Skip.
                continue
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
        let mm_col = 3 * (s:buffer_to_map(this_location['col'] - 1,       a:win_info['max_width'], a:win_info['mm_max_width']))
        let mm_len = 3 * (s:buffer_to_map(this_location['match_len'] - 1, a:win_info['max_width'], a:win_info['mm_max_width']))
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
    call s:clear_id_list_colors(a:win_info['winid'], g:minimap_search_id_list)
    let g:minimap_search_id_list = []
    " Color lines, creating a new id for each group
    for a_span in mm_spans
        " span_list item: [line_number, column_number, length]
        call add(g:minimap_search_id_list, s:get_next_search_matchid())
        call s:set_span_color(g:minimap_search_color, [a_span],
            \ g:minimap_search_color_priority, g:minimap_search_id_list[-1], a:win_info['winid'])
    endfor
endfunction

function! s:get_next_search_matchid() abort
    return g:minimap_search_matchid_safe_range + len(g:minimap_search_id_list)
endfunction
