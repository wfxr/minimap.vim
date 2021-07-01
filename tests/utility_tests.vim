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

call testify#it('Utility tests', function('s:minimap_test_utility'))
