" MIT (c) Wenxuan Zhang

if v:version < 800
    echom 'minimap: this plugin requires vim >= 8.'
    finish
endif

if exists('loaded_minimap')
    finish
endif

let loaded_minimap = 1

command! Minimap                 call minimap#vim#MinimapOpen()
command! MinimapClose            call minimap#vim#MinimapClose()
command! MinimapToggle           call minimap#vim#MinimapToggle()
command! MinimapRefresh          call minimap#vim#MinimapRefresh()

if !exists('g:minimap_left')
    let g:minimap_left = 0
endif

if !exists('g:minimap_width')
    let g:minimap_width = 10
endif

if !exists('g:minimap_highlight')
    let g:minimap_highlight= 'Title'
endif

if g:minimap_auto_start == 1
    augroup MinimapAutoStart
        au!
        au BufWinEnter * Minimap
    augroup end
endif
