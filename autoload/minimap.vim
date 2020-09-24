function! minimap#MinimapToggle()
    call s:toggle_window()
endfunction

function! minimap#MinimapClose()
    call s:close_window()
endfunction

function! minimap#MinimapOpen()
    call s:open_window()
endfunction

function! minimap#MinimapRefresh()
    call s:refresh_content()
endfunction

function! minimap#MinimapUpdateHighlight()
    call s:update_highlight()
endfunction

let s:known_files = {}
if !exists('g:minimap_left')
    let g:minimap_left = 0
endif

if !exists('g:minimap_width')
    let g:minimap_width = 30
endif

function! s:toggle_window()
    let mmwinnr = bufwinnr('__minimap__')
    if mmwinnr != -1
        call s:close_window()
        return
    endif

    call s:open_window()
endfunction

function! s:close_window()
    let mmwinnr = bufwinnr('__minimap__')
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
    let mmwinnr = bufwinnr('__minimap__')
    if mmwinnr != -1 && winnr() != mmwinnr
        return
    endif

    let openpos = g:minimap_left ? 'topleft vertical ' : 'botright vertical '
    execute 'silent! ' . openpos . g:minimap_width . 'split ' . '__minimap__'

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
    setlocal signcolumn=no

    let cpoptions_save = &cpoptions
    set cpoptions&vim

    augroup MinimapAutoCmds
        autocmd!
        autocmd BufEnter  __minimap__ nested call s:quit_if_only_window()
        autocmd BufUnload __minimap__ call s:clean_up()

        autocmd BufEnter * call s:refresh_content()
        " TODO: Should be improved <20-09-24 21:06, Wenxuan Zhang> "
        autocmd WinEnter,FocusGained,CursorMoved,VimResized * call minimap#MinimapUpdateHighlight()
    augroup END

    let &cpoptions = cpoptions_save

    execute 'wincmd p'
endfunction

function! s:clean_up()
    silent! autocmd! MinimapAutoCmds
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
    let fname = fnamemodify(bufname('%'), ':p')

    if !s:is_valid_file(fname, &filetype)
        return
    endif

    let mmwinnr = bufwinnr('__minimap__')

    if mmwinnr == -1
        return
    endif

    if has_key(s:known_files, fname)
        if s:known_files[fname].mtime != getftime(fname)
            call s:process_file(fname, &filetype)
        endif
    else
        call s:process_file(fname, &filetype)
    endif

    call s:render_content(fname, &filetype)
endfunction

function! s:is_valid_file(fname, ftype)
    if a:ftype ==# 'minimap'
        return 0
    endif
    return 1
endfunction
function! s:process_file(fname, ftype)
    let hscale = 2.0 * g:minimap_width / min([winwidth('%'), 120])
    let vscale = 4.0 * winheight('%') / line('$')
    let minimap_cmd = 'code-minimap -H' . string(hscale) .
                \' -V' . string(vscale) . ' ' . shellescape(a:fname)
    " echomsg minimap_cmd
    let minimap_output = system(minimap_cmd)

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
    let s:known_files[a:fname] = cache
endfunction

function! s:print_warning_msg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

function! s:render_content(fname, ftype) abort
    let mmwinnr = bufwinnr('__minimap__')
    execute mmwinnr . 'wincmd w'
    setlocal modifiable

    let cache = s:known_files[a:fname]

    silent 1,$delete _
    silent put =cache.content
    silent 1delete

    setlocal nomodifiable
    execute 'wincmd p'
endfunction

function! s:update_highlight() abort
    let mmwinnr = bufwinnr('__minimap__')
    if mmwinnr == -1
        return
    endif

    if winnr() == mmwinnr
        return
    endif
    let curr = line('.') - 1
    let total = line('$')

    execute mmwinnr . 'wincmd w'
    setlocal modifiable

    let height = line('$')
    let pos = float2nr(1.0 * curr / total * height) + 1
    " if pos < 1
    "     let pos = 1
    " elseif pos > height
    "     let pos = height
    " endif

    silent! call matchdelete(g:minimap_highlight_id)
    let g:minimap_highlight_id = matchadd('SignifySignAdd', '\%' . pos . 'l')

    setlocal nomodifiable
    execute 'wincmd p'
endfunction
