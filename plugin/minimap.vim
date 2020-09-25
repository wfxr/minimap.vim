if exists('loaded_minimap')
    finish
endif

let loaded_minimap = 1

command! MinimapToggle           call minimap#MinimapToggle()
command! Minimap                 call minimap#MinimapOpen()
command! MinimapClose            call minimap#MinimapClose()
command! MinimapRefresh          call minimap#MinimapRefresh()
command! MinimapUpdateHightlight call minimap#MinimapUpdateHighlight()

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
