" MIT (c) Wenxuan Zhang
" MIT (c) Zach Nielsen 2021


" Define the minimap dimensions
let s:win_info = { 'winid': 0, 'height': 12, 'mm_height': 3,
                \ 'working_width': 91, 'mm_max_width': 9, 'max_width': 91}
" Save the current view for restoring
let s:testview = winsaveview()
let s:testfile = expand('%')

if has('win32')
    let s:tempfolder = fnamemodify(expand('$TEMP'), ':p:h')
else
    let s:tempfolder = '/tmp'
endif

" Search tests
function! s:minimap_test_search()
    " Create the subjest of our search
    let test_file = s:tempfolder . '/minimap_search_unit_test_file'
    let text = [ 'This is a test line and it needs to be long enough to register as multiple braille characters.'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'pad height'
             \ , 'And another, this one is shorter'
             \ , 'and flows to the numbers line, this one, this one has some numbers 1234 numbers']
    call writefile(text, test_file)
    execute 'edit ' . test_file
endfunction
function! s:minimap_test_search_beginning_of_file()
    " Beginning of file
    let search = '\cThi'
    let expected_list = [ [1, 1, 3], [3, 4, 3], [3, 10, 3], [3, 13, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_beginning_of_line()
    " Test that basic search finds all the matches
    " List format: [ Line Number, Column, Length ] (of the minimap)
    " Beginning of line (\c ignores case since one is capitalized)
    let search = '\cand'
    let expected_list = [ [1, 4, 3], [3, 1, 3], [3, 1, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_end_of_line()
    " End of line
    let search = 'line'
    let expected_list = [ [1, 4, 3], [3, 7, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_multi_per_line()
    " Multiple per line
    let search = 'numbers'
    let expected_list = [ [3, 4, 3], [3, 16, 3], [3, 22, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_spanning_a_line()
    " Spanning a line (should be empty, not supported yet)
    let search = 'shorter\nand flows'
    let expected_list = [ ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_many_results()
    " Many results. \c means case insensitive
    let search = '\ca'
    let expected_list = [ [1, 1, 3], [1, 4, 3], [1, 19, 3], [1, 22, 3],
                \ [1, 25, 3], [1, 25, 3], [1, 1, 3], [1, 1, 3], [1, 1, 3],
                \ [2, 1, 3], [2, 1, 3], [2, 1, 3], [2, 1, 3], [3, 1, 3],
                \ [3, 1, 3], [3, 1, 3], [3, 1, 3], [3, 1, 3], [3, 16, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
    call testify#assert#equals(19, len(expected_list))
endfunction
function! s:minimap_test_search_long_match()
    " Long match
    let search = 'it needs to be long enough to register as multiple braille characters.'
    let expected_list = [ [1, 7, 21] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, search)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_history()
    " Verify that we are grabbing the correct one when we pass in an argument
    " (We only use 1 and 2, so only those need to be tested)
    call histadd('search', 'one is shorter')
    call histadd('search', 'height')

    " height
    let expected_list = [ [1, 1, 3], [1, 1, 3], [1, 1, 3],
                \ [2, 1, 3], [2, 1, 3], [2, 1, 3], [2, 1, 3],
                \ [3, 1, 3], [3, 1, 3] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, 1)
    call testify#assert#equals(actual_list, expected_list)
    call testify#assert#equals(9, len(expected_list))
    " test
    let expected_list = [ [3, 4, 6] ]
    let actual_list = minimap#vim#MinimapColorSearchGetSpans(s:win_info, 2)
    call testify#assert#equals(actual_list, expected_list)
endfunction
function! s:minimap_test_search_tear_down()
    " Return to this file
    execute 'buffer ' . s:testfile
    call winrestview(s:testview)
endfunction

call testify#it('Search setup', function('s:minimap_test_search'))
call testify#it('Search - Beginning of file',    function('s:minimap_test_search_beginning_of_file'))
call testify#it('Search - Beginning of line',    function('s:minimap_test_search_beginning_of_line'))
call testify#it('Search - End of line',          function('s:minimap_test_search_end_of_line'))
call testify#it('Search - Multi match per line', function('s:minimap_test_search_multi_per_line'))
call testify#it('Search - Spanning a line',      function('s:minimap_test_search_spanning_a_line'))
call testify#it('Search - Many results',         function('s:minimap_test_search_many_results'))
call testify#it('Search - Long Match',           function('s:minimap_test_search_long_match'))
call testify#it('Search - History',              function('s:minimap_test_search_history'))
call testify#it('Search tear down', function('s:minimap_test_search_tear_down'))
