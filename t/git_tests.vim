" MIT (c) Wenxuan Zhang
" MIT (c) Zach Nielsen 2021

" Git tests
function! s:minimap_test_git_multiline()
    " Multiline Changes
    let git_line = '@@ -97,97 +97,97 @@'
    let expected_dictionary = { 'start': 33, 'end': 65, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 201, 67)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Multiline Deletions
    let git_line = '@@ -97,97 +97,0 @@'
    let expected_dictionary = { 'start': 33, 'end': 33, 'color': g:minimap_diffremove_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 201, 67)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Multiline Additions
    let git_line = '@@ -97,0 +97,97 @@'
    let expected_dictionary = { 'start': 33, 'end': 65, 'color': g:minimap_diffadd_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 201, 67)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
endfunction
function! s:minimap_test_git_short_file()
    " Very short file, change
    let git_line = '@@ -0 +0 @@'
    let expected_dictionary = { 'start': 0, 'end': 1, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1, 1)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very short file, deletion
    let git_line = '@@ -1 +0,0 @@'
    let expected_dictionary = { 'start': 0, 'end': 0, 'color': g:minimap_diffremove_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1, 1)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very short file, addition
    let git_line = '@@ -0,0 +0 @@'
    let expected_dictionary = { 'start': 0, 'end': 1, 'color': g:minimap_diffadd_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1, 1)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
endfunction
function! s:minimap_test_git_long_file()
    " Very long file, change at beginning
    let git_line = '@@ -0 +0 @@'
    let expected_dictionary = { 'start': 1, 'end': 1, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, delete at beginning
    let git_line = '@@ -0 +0,0 @@'
    let expected_dictionary = { 'start': 1, 'end': 1, 'color': g:minimap_diffremove_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, add at beginning
    let git_line = '@@ -0,0 +0 @@'
    let expected_dictionary = { 'start': 1, 'end': 1, 'color': g:minimap_diffadd_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, change at middle
    let git_line = '@@ -5000 +5000 @@'
    let expected_dictionary = { 'start': 49, 'end': 49, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, delete at middle
    let git_line = '@@ -5000 +5000,0 @@'
    let expected_dictionary = { 'start': 49, 'end': 49, 'color': g:minimap_diffremove_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, add at middle
    let git_line = '@@ -5000,0 +5000 @@'
    let expected_dictionary = { 'start': 49, 'end': 49, 'color': g:minimap_diffadd_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, change at end
    let git_line = '@@ -10000 +10000 @@'
    let expected_dictionary = { 'start': 97, 'end': 98, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, remove at end
    let git_line = '@@ -10000 +10000,0 @@'
    let expected_dictionary = { 'start': 97, 'end': 97, 'color': g:minimap_diffremove_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Very long file, add at end
    let git_line = '@@ -10000,0 +10000 @@'
    let expected_dictionary = { 'start': 97, 'end': 98, 'color': g:minimap_diffadd_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 10000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
endfunction
function! s:minimap_test_git_span_mm_border()
    " Do two lines, one line apart, but spanning a minimap line increment. We
    " should get 2 minimap lines in this case.
    let git_line = '@@ -51,2 51,2 @@'
    let expected_dictionary = { 'start': 5, 'end': 6, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    let git_line = '@@ -51,0 +51,2 @@'
    let expected_dictionary = { 'start': 5, 'end': 6, 'color': g:minimap_diffadd_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
    " Removals are always one line, since the content of the file is altered.
    let git_line = '@@ -51,2 +51,0 @@'
    let expected_dictionary = { 'start': 5, 'end': 5, 'color': g:minimap_diffremove_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
endfunction
function! s:minimap_test_git_string_extras()
    " Test that what goes after the @@ does not need to be formattted
    let git_line = '@@ -533,74 +533,6 @@ It should not matter, @@ what goes after the @@'
    let expected_dictionary = { 'start': 52, 'end': 53, 'color': g:minimap_diff_color }
    let actual_dictionary = minimap#vim#MinimapParseGitDiffLine(git_line, 1000, 97)
    call testify#assert#equals(actual_dictionary, expected_dictionary)
endfunction

call testify#it('Git - Multiline diff',               function('s:minimap_test_git_multiline'))
call testify#it('Git - Short file diff',              function('s:minimap_test_git_short_file'))
call testify#it('Git - Long file diff',               function('s:minimap_test_git_long_file'))
call testify#it('Git - Diff spans minimap lines',     function('s:minimap_test_git_span_mm_border'))
call testify#it('Git - Extras in string are ignored', function('s:minimap_test_git_string_extras'))
