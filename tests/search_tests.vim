" MIT (c) Wenxuan Zhang
" MIT (c) Zach Nielsen 2021


" Search tests

function! s:minimap_test_search()
    " Execute some searches, then verify that we are grabbing the correct one
    " when we pass in an argument
    " Echo test subject body into a temp file, switch to it, then do searches?
    let test_file = '/tmp/minimap_search_unit_test_file'
    let text = 'This is a test line. It needs to be long enough to register as multiple braille characters.\n'
    let text = text + 'And another, this one is shorter\n'
    let text = text + 'and flows to the next one, then this one has some numbers 123 numbers'
    call bufload(test_file)
    call appendbufline(test_file, 0, text)

    " Test that basic search finds all the matches
    " List format: [ Line Number, Column, Length ]
    " beginning of line
    let search = 'and'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
    " beginning of file
    let search = 'Thi'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
    " end of line
    let search = 'line'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
    " 2x per line
    let search = 'numbers'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
    " Long match
    let search = 'It needs to be long enough to register as multiple braille characters.'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
    " Spanning a line (should fail, not supported yet)
    let search = 'shorter\nand flows'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
    " Test that regex search finds all the matches
    let search = 's.'
    let expected_list = [ [1, 1, 1] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(3, 3, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction

call testify#it('Search tests', function('s:minimap_test_search'))


"
" Utility Tests
"
" Token test to ensure the algebra for mm conversion doesn't change
" unexpectedly

" Add a few more tests for horizontal calculation
" TODO - break that out into a function to be tested

