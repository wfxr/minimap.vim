" MIT (c) Wenxuan Zhang
" MIT (c) Zach Nielsen 2021

" Search tests
function! s:minimap_test_search()
    let testview = winsaveview()
    let testfile = expand('%')

    " Create the subjest of our search
    let test_file = '/tmp/minimap_search_unit_test_file'
    let text =        'This is a test line and it needs to be long enough to register as multiple braille characters.\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'pad height\n'
    let text = text . 'And another, this one is shorter\n'
    let text = text . 'and flows to the numbers line, this one, this one has some numbers 1234 numbers'
    execute 'silent !echo "' . text . '" > ' . test_file
    execute 'edit ' . test_file

    let win_info = { 'winid': 0, 'height': 12, 'mm_height': 3,
                    \ 'max_width': 91, 'mm_max_width': 9}

    " Test that basic search finds all the matches
    " List format: [ Line Number, Column, Length ]
    " beginning of line
    let search = 'and'
    let expected_list = [ [1, 4, 3], [3, 1, 3], [3, 1, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    " beginning of file
    let search = 'Thi'
    let expected_list = [ [1, 1, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    " end of line
    let search = 'line'
    let expected_list = [ [1, 4, 3], [3, 7, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    " Multiple per line
    let search = 'numbers'
    let expected_list = [ [3, 4, 3], [3, 16, 3], [3, 22, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    " Spanning a line (should be empty, not supported yet)
    let search = 'shorter\nand flows'
    let expected_list = [ ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    " Many results
    let search = 'a'
    let expected_list = [ [1, 1, 3], [1, 4, 3], [1, 19, 3], [1, 22, 3],
                \ [1, 25, 3], [1, 25, 3], [1, 1, 3], [1, 1, 3], [1, 1, 3],
                \ [2, 1, 3], [2, 1, 3], [2, 1, 3], [2, 1, 3], [3, 1, 3],
                \ [3, 1, 3], [3, 1, 3], [3, 1, 3], [3, 1, 3], [3, 16, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    call testify#assert#equals(19, len(expected_list))
    " Long match
    let search = 'it needs to be long enough to register as multiple braille characters.'
    let expected_list = [ [1, 7, 21] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, search)
    call testify#assert#equals(actual_list, expected_list)

    " Verify that we are grabbing the correct one when we pass in an argument
    " (We only use 1 and 2, so only those need to be tested)
    normal! /test
    normal! /height

    " height
    let expected_list = [ [1, 1, 3], [1, 1, 3], [1, 1, 3],
                \ [2, 1, 3], [2, 1, 3], [2, 1, 3], [2, 1, 3],
                \ [3, 1, 3], [3, 1, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, 1)
    call testify#assert#equals(actual_list, expected_list)
    call testify#assert#equals(9, len(expected_list))
    " test
    let expected_list = [ [1, 1, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(win_info, 2)
    call testify#assert#equals(actual_list, expected_list)

    " Return to this file
    execute 'buffer ' . testfile
    call winrestview(testview)
endfunction

call testify#it('Search tests', function('s:minimap_test_search'))
