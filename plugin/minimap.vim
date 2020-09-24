if exists('loaded_minimap')
    finish
endif

let loaded_minimap = 1

command! MinimapToggle           call minimap#MinimapToggle()
command! Minimap                 call minimap#MinimapOpen()
command! MinimapClose            call minimap#MinimapClose()
command! MinimapRefresh          call minimap#MinimapRefresh()
command! MinimapUpdateHightlight call minimap#MinimapUpdateHighlight()
