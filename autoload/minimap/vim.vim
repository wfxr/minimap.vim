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
    if winnr('$') == 3 && exists('g:coc_last_float_win')
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

    let g:id_list = []
    execute 'wincmd p'
    call s:refresh_minimap(1)
    call s:update_highlight()
endfunction

function! s:handle_autocmd(cmd) abort
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

    if has('nvim')
        let minimap_cmd = 'w !'.s:minimap_gen.' '.hscale.' '.vscale.' '.g:minimap_width
        " echom minimap_cmd
        let minimap_output = execute(minimap_cmd) " Not work for vim 8.2 ?
    else
        let minimap_cmd = s:minimap_gen.' '.hscale.' '.vscale.' '.g:minimap_width
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
    let total = line('$')
    let mmheight = getwininfo(winid)[0].botline

    let curr = line('.') - 1
    let pos = s:buffer_to_map(curr, total, mmheight)
    call s:highlight_line(winid, pos)
endfunction

" botline is broken and this works.  However, it's slow, so we call this function less.
" Remove this function when `getwininfo().botline` is fixed.
function! s:update_highlight() abort
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        return
    endif

    let winid = win_getid(mmwinnr)
    let total = line('$')

    let curwinview = winsaveview()
    execute mmwinnr . 'wincmd w'
    let mmheight = line('w$')
    execute 'wincmd p'
    call winrestview(curwinview)

    if g:minimap_highlight_range
        let startln = line('w0') - 1
        let endln = line('w$') - 1
        let pos1 = s:buffer_to_map(startln, total, mmheight) - 1
        let pos2 = s:buffer_to_map(endln, total, mmheight) + 1
        call s:highlight_range(winid, pos1, pos2)
    else
        let curr = line('.') - 1
        let pos = s:buffer_to_map(curr, total, mmheight)
        call s:highlight_line(winid, pos)
    endif

    if g:minimap_git_colors
        " Get git info
        let git_call = 'git diff -U0 -- ' . expand('%')
        let git_diff = substitute(system(git_call), '\n\+&', '', '') | silent echo strtrans(git_diff)

        let lines = split(git_diff, '\n')
        let diff_list = []
        for line in lines
            if line[0] ==? '@'
                let this_diff = {}

                let blobs = split(line, ' ')
                let del_info = blobs[1]
                let add_info = blobs[2]

                " Parse newfile info
                let add_info = split(add_info, ',')
                let add_start = str2nr(add_info[0])
                let add_len = 0
                if len(add_info) > 1
                    let add_len = abs(str2nr(add_info[1]))
                endif
                " Parse oldfile info
                let del_info = split(del_info, ',')
                let del_len = 0
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
                    let this_diff['end'] = this_diff['start'] + 1
                else
                    let this_diff['color'] = g:minimap_diff_color
                    let this_diff['end'] = this_diff['start'] + 1
                endif

                " Map locations to minimap
                let this_diff['start'] = s:buffer_to_map(this_diff['start'], total, mmheight) - 1
                let this_diff['end'] = s:buffer_to_map(this_diff['end'], total, mmheight) + 1
                " Add to list
                let diff_list = add(diff_list, this_diff)
            endif
        endfor

        " Delete the old lines before drawing the new ones
        for id in g:id_list
            silent! call matchdelete(id, winid) " require vim 8.1.1084+ or neovim 0.5.0+
        endfor
        " Color lines, creating a new id for each section
        let g:id_list = []
        for a_diff in diff_list
            call add(g:id_list, g:minimap_cursorline_matchid  + (1 + len(g:id_list)))
            call s:set_range_color(winid, a_diff['start'], max([a_diff['start']+1, a_diff['end']]), a_diff['color'], g:id_list[-1])
        endfor
    endif
endfunction

" Translates a line in a buffer to its respective pos in the map.
function! s:buffer_to_map(lnnum, buftotal, mmheight) abort
    return float2nr(1.0 * a:lnnum / a:buftotal * a:mmheight) + 1
endfunction

function! s:highlight_line(winid, pos) abort
    silent! call matchdelete(g:minimap_cursorline_matchid, a:winid) " require vim 8.1.1084+ or neovim 0.5.0+
    call matchadd(g:minimap_highlight, '\%' . a:pos . 'l', 100, g:minimap_cursorline_matchid, { 'window': a:winid })
endfunction

function! s:set_range_color(winid, startpos, endpos, set_color, match_id) abort
    call matchadd(a:set_color, '\%>' . a:startpos . 'l\%<' . a:endpos . 'l', 100, a:match_id, { 'window': a:winid })
endfunction
function! s:highlight_range(winid, startpos, endpos) abort
    " Delete the old one before drawing
    silent! call matchdelete(g:minimap_cursorline_matchid, a:winid) " require vim 8.1.1084+ or neovim 0.5.0+
    call s:set_range_color(a:winid, a:startpos, a:endpos, g:minimap_highlight, g:minimap_cursorline_matchid)
endfunction
function! s:set_diffadd_range(winid, startpos, endpos) abort
    call s:set_range_color(a:winid, a:startpos, a:endpos, g:minimap_diffadd_color, g:minimap_add_matchid)
endfunction
function! s:set_diffremove_range(winid, startpos, endpos) abort
    call s:set_range_color(a:winid, a:startpos, a:endpos, g:minimap_diffremove_color, g:minimap_rem_matchid)
endfunction
function! s:set_diff_range(winid, startpos, endpos) abort
    call s:set_range_color(a:winid, a:startpos, a:endpos, g:minimap_diff_color, g:minimap_diff_matchid)
endfunction

" Clears matches of current window only.
function! s:clear_highlights() abort
    silent! call matchdelete(g:minimap_base_matchid)
    silent! call matchdelete(g:minimap_cursorline_matchid)
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
    let total = line('$')
    let mmheight = getwininfo(winid)[0].botline

    let start = line('w0') - 1
    let end = line('w$') - 1
    " The -/+ 1 compensates for the exclusive ranges we use in the
    " patterns for matchadd.
    let pos1 = s:buffer_to_map(start, total, mmheight) - 1
    let pos2 = s:buffer_to_map(end, total, mmheight) + 1
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
