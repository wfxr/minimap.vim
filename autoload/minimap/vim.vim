" MIT (c) Wenxuan Zhang

function! minimap#vim#MinimapToggle()
    call s:toggle_window()
endfunction

function! minimap#vim#MinimapClose()
    call s:close_window()
endfunction

function! minimap#vim#MinimapOpen()
    call s:open_window()
endfunction

function! minimap#vim#MinimapRefresh()
    call s:refresh_content()
endfunction

function! s:buffer_enter_handler()
    if &filetype ==# 'minimap'
        call s:minimap_buffer_enter_handler()
    else
        call s:source_buffer_enter_handler()
    endif
endfunction

function! s:cursor_move_handler()
    if &filetype ==# 'minimap'
        call s:minimap_move()
    else
        call s:source_move()
    endif
endfunction

function! s:win_enter_handler()
    if &filetype ==# 'minimap'
        call s:minimap_win_enter()
    else
        call s:source_win_enter()
    endif
endfunction

let s:known_files = {}
let s:bin_dir = expand('<sfile>:p:h:h:h').'/bin/'
let s:minimap_gen = s:bin_dir.'minimap_generator.sh'

function! s:toggle_window()
    let mmwinnr = bufwinnr('MINIMAP')
    if mmwinnr != -1
        call s:close_window()
        return
    endif

    call s:open_window()
endfunction

function! s:close_window()
    let mmwinnr = bufwinnr('MINIMAP')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        if winbufnr(2) != -1
            " Other windows are open, only close the this one
            close
        endif
    else
        " Go to the minimap window, close it and then come back to the
        " original window
        let curbufnr = bufnr('%')
        exe mmwinnr . 'wincmd w'
        close
        " Need to jump back to the original window only if we are not
        " already in that window
        let winnum = bufwinnr(curbufnr)
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif
    endif
endfunction

function! s:open_window()
    " If the minimap window is already open jump to it
    let mmwinnr = bufwinnr('MINIMAP')
    if mmwinnr != -1
        return
    endif

    let openpos = g:minimap_left ? 'topleft vertical ' : 'botright vertical '
    execute 'silent! ' . openpos . g:minimap_width . 'split ' . 'MINIMAP'

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
    silent! setlocal norelativenumber
    setlocal nofoldenable
    setlocal foldcolumn=0
    setlocal foldmethod&
    setlocal foldexpr&
    silent! setlocal signcolumn=no

    let cpoptions_save = &cpoptions
    set cpoptions&vim

    augroup MinimapAutoCmds
        autocmd!
        autocmd WinEnter <buffer> if winnr('$') == 1|q|endif
        autocmd BufWritePost            * call s:refresh_content()
        autocmd BufEnter                * call s:buffer_enter_handler()
        autocmd FocusGained,CursorMoved * call s:cursor_move_handler()
        autocmd WinEnter                * call s:win_enter_handler()
    augroup END

    let &cpoptions = cpoptions_save

    execute 'wincmd p'
endfunction

function! s:quit_if_only_window()
    " Before quitting Vim, delete the minimap buffer so that
    " the '0 mark is correctly set to the previous buffer.
    if winbufnr(2) == -1
        " Check if there is more than one tab page
        if tabpagenr('$') == 1
            bdelete
            quit
        else
            close
        endif
    endif
endfunction

function! s:refresh_content()
    let bufnr = bufnr('%')
    let fname = fnamemodify(bufname('%'), ':p')

    if !s:is_valid_file(fname, &filetype)
        return
    endif

    let mmwinnr = bufwinnr('MINIMAP')

    if mmwinnr == -1
        return
    endif

    if has_key(s:known_files, fname)
        if s:known_files[fname].mtime != getftime(fname)
            call s:process_buffer(mmwinnr, bufnr, fname, &filetype)
        endif
    else
        call s:process_buffer(mmwinnr, bufnr, fname, &filetype)
    endif

    call s:render_content(mmwinnr, bufnr, fname, &filetype)
endfunction

function! s:is_valid_file(fname, ftype)
    if a:ftype ==# 'minimap'
        return 0
    endif
    return 1
endfunction

function! s:process_buffer(mmwinnr, bufnr, fname, ftype) abort
    let winid = win_getid(a:mmwinnr)
    let hscale = string(2.0 * g:minimap_width / min([winwidth('%'), 120]))
    let vscale = string(4.0 * winheight(winid) / line('$'))

    if has('nvim')
        let minimap_cmd = 'w !'.s:minimap_gen.' '.hscale.' '.vscale.' '.g:minimap_width
        " echom minimap_cmd
        let minimap_output = execute(minimap_cmd) " Not work for vim 8.2 ?
    else
        let minimap_cmd = s:minimap_gen.' '.hscale.' '.vscale.' '.g:minimap_width.' '.shellescape(expand('%'))
        " echom minimap_cmd
        let minimap_output = system(minimap_cmd)
    endif


    if v:shell_error
        let msg = 'minimap: could not generate minimap for ' . a:fname
        call s:print_warning_msg(msg)
        if !empty(minimap_output)
            call s:print_warning_msg(minimap_output)
        endif
        return
    endif

    let cache = {}
    let cache.mtime = getftime(a:fname)
    let cache.content = minimap_output
    let s:known_files[a:bufnr] = cache
endfunction

function! s:print_warning_msg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

function! s:render_content(mmwinnr, bufnr, fname, ftype) abort
    execute a:mmwinnr . 'wincmd w'
    setlocal modifiable

    let cache = s:known_files[a:bufnr]

    silent 1,$delete _
    silent put =cache.content
    if has('nvim')
        silent 1,3delete
    else
        silent 1delete
    endif

    setlocal nomodifiable
    execute 'wincmd p'
endfunction

function! s:source_move() abort
    let mmwinnr = bufwinnr('MINIMAP')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        return
    endif

    let winid = win_getid(mmwinnr)
    let curr = line('.') - 1
    let total = line('$')
    let mmheight = getwininfo(win_getid(mmwinnr))[0].botline
    let pos = float2nr(1.0 * curr / total * mmheight) + 1
    call s:highlight_line(winid, pos)
    " TODO: Also move the cursor of minimap, but how to? <20-09-25 17:30, Wenxuan Zhang> "
endfunction

function! s:highlight_line(winid, pos) abort
    silent! call matchdelete(g:minimap_highlight_id, a:winid) " require vim 8.1.1084+ or neovim 0.5.0+
    let g:minimap_highlight_id = matchadd(g:minimap_highlight, '\%' . a:pos . 'l', 100, -1, { 'window': a:winid })
endfunction

function! s:minimap_move()
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
    call s:source_move()
endfunction

function! s:minimap_buffer_enter_handler() abort
    " do nothing
endfunction

function! s:source_buffer_enter_handler() abort
    call s:refresh_content()
endfunction
