" MIT (c) Wenxuan Zhang

if exists('g:loaded_minimap')
    finish
endif

if v:version < 800
    echom 'minimap: this plugin requires vim >= 8.'
    finish
endif

if !executable('code-minimap')
    echom 'minimap: this plugin requires code-minimap installed.'
    finish
endif

let g:loaded_minimap = 1

command! Minimap                call minimap#vim#MinimapOpen()
command! MinimapClose           call minimap#vim#MinimapClose()
command! MinimapToggle          call minimap#vim#MinimapToggle()
command! MinimapRefresh         call minimap#vim#MinimapRefresh()
command! MinimapUpdateHighlight call minimap#vim#MinimapUpdateHighlight()

if !exists('g:minimap_auto_start')
    let g:minimap_auto_start = 0
endif

if !exists('g:minimap_left')
    let g:minimap_left = 0
endif

if !exists('g:minimap_width')
    let g:minimap_width = 10
endif

if !exists('g:minimap_base_highlight')
    let g:minimap_base_highlight = 'Normal'
endif

if !exists('g:minimap_base_matchid')
    let g:minimap_base_matchid = 9265454 " magic number
endif

if !exists('g:minimap_highlight')
    let g:minimap_highlight = 'Title'
endif

if !exists('g:minimap_cursorline_matchid')
    let g:minimap_cursorline_matchid = 9265455
endif

if !exists('g:minimap_block_filetypes')
    let g:minimap_block_filetypes = ['fugitive', 'nerdtree', 'tagbar']
endif

if !exists('g:minimap_block_buftypes')
    let g:minimap_block_buftypes = ['nofile', 'nowrite', 'quickfix', 'terminal', 'prompt']
endif

if !exists('g:minimap_close_filetypes')
    let g:minimap_close_filetypes = ['startify', 'netrw']
endif

if !exists('g:minimap_close_buftypes')
    let g:minimap_close_buftypes = []
endif

if !exists('g:minimap_auto_start_win_enter')
    let g:minimap_auto_start_win_enter = 0
endif

if g:minimap_auto_start == 1
    augroup MinimapAutoStart
        au!
        au BufWinEnter * Minimap
        if g:minimap_auto_start_win_enter == 1
            au WinEnter * Minimap
        endif
    augroup end
endif
