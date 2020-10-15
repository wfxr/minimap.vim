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
    call s:refresh_minimap()
endfunction

function! s:buffer_enter_handler() abort
    if &filetype ==# 'minimap'
        call s:minimap_buffer_enter_handler()
    else
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
else
    let s:minimap_gen = s:bin_dir.'minimap_generator.sh'
    let s:default_shell = 'sh'
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
    silent! call matchdelete(g:minimap_cursorline_matchid)
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        if winbufnr(2) != -1
            " Other windows are open, only close the this one
            close
            exe 'wincmd p'
        endif
    else
        exe mmwinnr . 'wincmd c'
    endif
endfunction

function! s:close_window_last() abort
    " We are on the last tab and the <MINIMAP> buffer is in the last window
    let tabnum = tabpagenr()
    if winnr('$') == 1
        silent! call s:close_window()
        if tabnum == tabpagenr('$') && tabnum == 1
            doautocmd ExitPre,VimLeavePre,VimLeave
        endif
        quit
    endif
endfunction

function! s:open_window() abort
    " If the minimap window is already open jump to it
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr != -1
        return
    endif

    let openpos = g:minimap_left ? 'topleft vertical ' : 'botright vertical '
    execute 'silent! ' . openpos . g:minimap_width . 'split ' . '-MINIMAP-'

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
        autocmd WinEnter                      <buffer> call s:close_window_last()
        autocmd BufWritePost,VimResized              * call s:refresh_minimap(1) | call s:update_highlight()
        autocmd BufEnter                             * call s:buffer_enter_handler()
        autocmd FocusGained,CursorMoved,CursorMovedI * call s:cursor_move_handler()
        autocmd WinEnter                             * call s:win_enter_handler()
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
    call s:update_highlight()
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

    " Users that have custom shells may face problems.
    let usershell = &shell
    let &shell = s:default_shell

    if has('nvim')
        let minimap_cmd = 'w !'.s:minimap_gen.' '.hscale.' '.vscale.' '.g:minimap_width
        " echom minimap_cmd
        let minimap_output = execute(minimap_cmd) " Not work for vim 8.2 ?
    else
        let minimap_cmd = s:minimap_gen.' '.hscale.' '.vscale.' '.g:minimap_width.' '.shellescape(expand('%'))
        " echom minimap_cmd
        let minimap_output = system(minimap_cmd)
    endif

    " Recover the user's selected shell.
    let &shell = usershell

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

    setlocal nomodifiable
    execute 'wincmd p'
endfunction

function! s:source_move() abort
    let mmwinnr = bufwinnr('-MINIMAP-')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        return
    endif

    let winid = win_getid(mmwinnr)
    let curr = line('.') - 1
    let total = line('$')
    let mmheight = getwininfo(winid)[0].botline
    let pos = float2nr(1.0 * curr / total * mmheight) + 1
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
    let curr = line('.') - 1
    let total = line('$')

    let l:winview = winsaveview()
    execute mmwinnr . 'wincmd w'
    let mmheight = line('w$')
    execute 'wincmd p'
    call winrestview(l:winview)
    
    let pos = float2nr(1.0 * curr / total * mmheight) + 1
    call s:highlight_line(winid, pos)
endfunction

function! s:highlight_line(winid, pos) abort
    silent! call matchdelete(g:minimap_cursorline_matchid, a:winid) " require vim 8.1.1084+ or neovim 0.5.0+
    call matchadd(g:minimap_highlight, '\%' . a:pos . 'l', 100, g:minimap_cursorline_matchid, { 'window': a:winid })
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
endfunction
