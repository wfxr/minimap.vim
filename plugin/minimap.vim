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

command! Minimap        call minimap#vim#MinimapOpen()
command! MinimapClose   call minimap#vim#MinimapClose()
command! MinimapToggle  call minimap#vim#MinimapToggle()
command! MinimapRefresh call minimap#vim#MinimapRefresh()

if !exists('g:minimap_left')
    let g:minimap_left = 0
endif

if !exists('g:minimap_width')
    let g:minimap_width = 10
endif

if !exists('g:minimap_highlight')
    let g:minimap_highlight = 'Title'
endif

if !exists('g:minimap_auto_start')
    let g:minimap_auto_start = 0
endif

if !exists('g:minimap_cursorline_matchid')
    let g:minimap_cursorline_matchid = 9265454 " magic number
endif

if !exists('g:minimap_block_filetypes')
    let g:minimap_block_filetypes = ['', 'fugitive', 'nerdtree', 'startify']
endif

if g:minimap_auto_start == 1
    augroup MinimapAutoStart
        au!
        au BufWinEnter * Minimap
    augroup end
endif
