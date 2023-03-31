" MIT (c) Wenxuan Zhang
" MIT (c) Zach Nielsen 2021
"
" Utility Tests
function! s:minimap_test_utility()
    " Token test to ensure the algebra for mm conversion doesn't change
    " unexpectedly. Args are (buffer num, buffer max, minimap max) -> mm num
    let actual_mm = minimap#vim#BufferToMap(31, 101, 23)
    " (x/23 == 31/101), but with a 1 offset since lines start at 1
    " (31*23)/101 = 7, +1 == 8
    let expected_mm = 8
    call testify#assert#equals(actual_mm, expected_mm)
endfunction

function! s:minimap_test_calls_to_update_minimap()
    " Save minimap state
    let mmwinnr = bufwinnr('-MINIMAP-')

    call minimap#vim#MinimapClose()
    let g:minimap_run_update_highlight_count = 0
    call minimap#vim#MinimapOpen()
    call testify#assert#equals(1, g:minimap_run_update_highlight_count)

    if mmwinnr == -1
        call minimap#vim#MinimapClose()
    endif
endfunction

call testify#it('Minimap conversion math works as expected',
            \ function('s:minimap_test_utility'))
call testify#it('Opening minimap results in only one call to update_minimap',
            \ function('s:minimap_test_calls_to_update_minimap'))
