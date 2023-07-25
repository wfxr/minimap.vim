" MIT (c) Wenxuan Zhang and Zach Nielsen

if exists('g:loaded_minimap')
    finish
endif

if v:version < 800
    echom 'minimap: this plugin requires vim >= 8.'
    finish
endif

if !exists('g:minimap_exec_warning')
    let g:minimap_exec_warning  = 1
endif

if !executable('code-minimap')
    if g:minimap_exec_warning != 0
        echom 'minimap: this plugin requires code-minimap installed.'
    endif

    finish
endif

let g:loaded_minimap = 1

command! Minimap                call minimap#vim#MinimapOpen()
command! MinimapClose           call minimap#vim#MinimapClose()
command! MinimapToggle          call minimap#vim#MinimapToggle()
command! MinimapRefresh         call minimap#vim#MinimapRefresh()
command! MinimapUpdateHighlight call minimap#vim#MinimapUpdateHighlight()
command! MinimapRescan          call minimap#vim#MinimapRescan()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists('g:minimap_auto_start')
    let g:minimap_auto_start = 0
endif

if !exists('g:minimap_left')
    let g:minimap_left = 0
endif

if !exists('g:minimap_width')
    let g:minimap_width = 10
endif

if !exists('g:minimap_window_width_override_for_scaling')
    let g:minimap_window_width_override_for_scaling = 2147483647
endif

if !exists('g:minimap_auto_start_win_enter')
    let g:minimap_auto_start_win_enter = 0
endif

if !exists('g:minimap_base_matchid')
    let g:minimap_base_matchid = 9265454 " magic number
endif

if !exists('g:minimap_search_matchid_safe_range')
    let g:minimap_search_matchid_safe_range = g:minimap_base_matchid + 30000
endif

if !exists('g:minimap_block_filetypes')
    let g:minimap_block_filetypes = ['fugitive', 'nerdtree', 'tagbar', 'fzf']
endif

if !exists('g:minimap_block_buftypes')
    let g:minimap_block_buftypes = ['nofile', 'nowrite', 'quickfix', 'terminal', 'prompt']
endif

if !exists('g:minimap_close_filetypes')
    let g:minimap_close_filetypes = ['startify', 'netrw', 'vim-plug']
endif

if !exists('g:minimap_close_buftypes')
    let g:minimap_close_buftypes = []
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Feature Flags
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists('g:minimap_highlight_range')
    let g:minimap_highlight_range = 1
endif

if !exists('g:minimap_git_colors')
    let g:minimap_git_colors = 0
endif

if !exists('g:minimap_enable_highlight_colorgroup')
    let g:minimap_enable_highlight_colorgroup = 1
endif

if !exists('g:minimap_highlight_search')
    let g:minimap_highlight_search = 0
endif

if !exists('g:minimap_background_processing')
    let g:minimap_background_processing = 0
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Colors
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight minimapCursor            ctermbg=59  ctermfg=228 guibg=#5F5F5F guifg=#FFFF87 |
highlight minimapRange             ctermbg=242 ctermfg=228 guibg=#4F4F4F guifg=#FFFF87 |
highlight minimapDiffRemoved                   ctermfg=197               guifg=#FC1A70 |
highlight minimapDiffAdded                     ctermfg=148               guifg=#A4E400 |
highlight minimapDiffLine                      ctermfg=141               guifg=#AF87FF |
highlight minimapCursorDiffRemoved ctermbg=59  ctermfg=197 guibg=#5F5F5F guifg=#FC1A70 |
highlight minimapCursorDiffAdded   ctermbg=59  ctermfg=148 guibg=#5F5F5F guifg=#A4E400 |
highlight minimapCursorDiffLine    ctermbg=59  ctermfg=141 guibg=#5F5F5F guifg=#AF87FF |
highlight minimapRangeDiffRemoved  ctermbg=242 ctermfg=197 guibg=#4F4F4F guifg=#FC1A70 |
highlight minimapRangeDiffAdded    ctermbg=242 ctermfg=148 guibg=#4F4F4F guifg=#A4E400 |
highlight minimapRangeDiffLine     ctermbg=242 ctermfg=141 guibg=#4F4F4F guifg=#AF87FF

" Need the autocmd because some colorschemes clear all colors, so we need to
" re-add them so they stay valid

if g:minimap_enable_highlight_colorgroup == 1
    augroup MinimapColorSchemes
        autocmd!
        autocmd ColorScheme *
            \ highlight minimapCursor            ctermbg=59  ctermfg=228 guibg=#5F5F5F guifg=#FFFF87 |
            \ highlight minimapRange             ctermbg=242 ctermfg=228 guibg=#4F4F4F guifg=#FFFF87 |
            \ highlight minimapDiffRemoved                   ctermfg=197               guifg=#FC1A70 |
            \ highlight minimapDiffAdded                     ctermfg=148               guifg=#A4E400 |
            \ highlight minimapDiffLine                      ctermfg=141               guifg=#AF87FF |
            \ highlight minimapCursorDiffRemoved ctermbg=59  ctermfg=197 guibg=#5F5F5F guifg=#FC1A70 |
            \ highlight minimapCursorDiffAdded   ctermbg=59  ctermfg=148 guibg=#5F5F5F guifg=#A4E400 |
            \ highlight minimapCursorDiffLine    ctermbg=59  ctermfg=141 guibg=#5F5F5F guifg=#AF87FF |
            \ highlight minimapRangeDiffRemoved  ctermbg=242 ctermfg=197 guibg=#4F4F4F guifg=#FC1A70 |
            \ highlight minimapRangeDiffAdded    ctermbg=242 ctermfg=148 guibg=#4F4F4F guifg=#A4E400 |
            \ highlight minimapRangeDiffLine     ctermbg=242 ctermfg=141 guibg=#4F4F4F guifg=#AF87FF
    augroup END
endif

if !exists('g:minimap_base_highlight')
    let g:minimap_base_highlight = 'Normal'
endif

" Change setting name, backwards compatibility
if exists('g:minimap_highlight')
    let g:minimap_cursor_color = g:minimap_highlight
endif
if !exists('g:minimap_cursor_color')
    let g:minimap_cursor_color = 'minimapCursor'
endif

if !exists('g:minimap_range_color')
    let g:minimap_range_color = 'minimapRange'
endif

if !exists('g:minimap_search_color')
    let g:minimap_search_color = 'Search'
endif

if !exists('g:minimap_diffremove_color')
    let g:minimap_diffremove_color = 'minimapDiffRemoved'
endif

if !exists('g:minimap_diffadd_color')
    let g:minimap_diffadd_color = 'minimapDiffAdded'
endif

if !exists('g:minimap_diff_color')
    let g:minimap_diff_color = 'minimapDiffLine'
endif

if !exists('g:minimap_cursor_diffremove_color')
    let g:minimap_cursor_diffremove_color = 'minimapCursorDiffRemoved'
endif

if !exists('g:minimap_cursor_diffadd_color')
    let g:minimap_cursor_diffadd_color = 'minimapCursorDiffAdded'
endif

if !exists('g:minimap_cursor_diff_color')
    let g:minimap_cursor_diff_color = 'minimapCursorDiffLine'
endif

if !exists('g:minimap_range_diffremove_color')
    let g:minimap_range_diffremove_color = 'minimapRangeDiffRemoved'
endif

if !exists('g:minimap_range_diffadd_color')
    let g:minimap_range_diffadd_color = 'minimapRangeDiffAdded'
endif

if !exists('g:minimap_range_diff_color')
    let g:minimap_range_diff_color = 'minimapRangeDiffLine'
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Priorities
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists('g:minimap_cursor_color_priority')
    let g:minimap_cursor_color_priority = 110
endif
if !exists('g:minimap_search_color_priority')
    let g:minimap_search_color_priority = 120
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Global variables and containers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Declare mutexes
let g:minimap_getting_window_info = 0
let g:minimap_did_quit = 0
let g:minimap_opening = 0
" Declare id lists - used for storing matchids of color groups
let g:minimap_range_id_list = []
let g:minimap_git_id_list = []
let g:minimap_search_id_list = []
let g:minimap_match_id_list = []
" key: mm_line, val: { 'state': state bitmap, 'id': match id for this coloring }
let g:minimap_line_state_table = {}

let g:minimap_run_update_highlight_count = 0

if g:minimap_auto_start == 1
    augroup MinimapAutoStart
        au!
        au BufWinEnter * Minimap
        if g:minimap_auto_start_win_enter == 1
            au WinEnter * Minimap
        endif
    augroup end
endif

" Mappings to make searching update with * or #
if g:minimap_highlight_search != 0
    nnoremap <silent> * *:call minimap#vim#UpdateColorSearch(1)<CR>
    nnoremap <silent> # #:call minimap#vim#UpdateColorSearch(1)<CR>
    nnoremap <silent> g* g*:call minimap#vim#UpdateColorSearch(1)<CR>
    nnoremap <silent> g# g#:call minimap#vim#UpdateColorSearch(1)<CR>
    " Example mapping for nohlsearch to also clear the minimap search highlighting
    " nnoremap <silent> `` :nohlsearch<CR>:call minimap#vim#ClearColorSearch()<CR>
endif
