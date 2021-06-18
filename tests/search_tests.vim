" MIT (c) Wenxuan Zhang
" MIT (c) Zach Nielsen 2021


" Search tests

" Execute some searches, then verify that we are grabbing the correct one
" when we pass in an argument
" Echo test subject body into a temp file, switch to it, then do searches?
let test_file = '/tmp/minimap_search_unit_test_file'
call bufload(test_file)
call appendbufline(test_file, 0, text)

" Test that basic search finds all the matches
" - beginning of line
" - beginning of file
" - end of line
" - 2x per line
" - Spanning a line (should fail, not supported yet)

" Test that regex search finds all the matches

"
" Utility Tests
"
" Token test to ensure the algebra for mm conversion doesn't change
" unexpectedly

" Add a few more tests for horizontal calculation
" TODO - break that out into a function to be tested

