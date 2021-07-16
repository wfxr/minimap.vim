" MIT (c) Wenxuan Zhang

if exists('g:loaded_minimap')
    finish
endif

if v:version < 800
    echom 'minimap: this plugin requires vim >= 8.'
    finish
endif

if !executable('code-minimap')
    echom 'minimap: this plugin requires code-minimap installed.'
    finish
endif

let g:loaded_minimap = 1

command! Minimap                call minimap#vim#MinimapOpen()
command! MinimapClose           call minimap#vim#MinimapClose()
command! MinimapToggle          call minimap#vim#MinimapToggle()
command! MinimapRefresh         call minimap#vim#MinimapRefresh()
command! MinimapUpdateHighlight call minimap#vim#MinimapUpdateHighlight()

if !exists('g:minimap_auto_start')
    let g:minimap_auto_start = 0
endif

if !exists('g:minimap_left')
    let g:minimap_left = 0
endif

if !exists('g:minimap_width')
    let g:minimap_width = 10
endif

if !exists('g:minimap_base_highlight')
    let g:minimap_base_highlight = 'Normal'
endif

if !exists('g:minimap_base_matchid')
    let g:minimap_base_matchid = 9265454 " magic number
endif

if !exists('g:minimap_range_matchid_safe_range')
    let g:minimap_range_matchid_safe_range = g:minimap_base_matchid + 10000
endif

if !exists('g:minimap_git_matchid_safe_range')
    let g:minimap_git_matchid_safe_range = g:minimap_base_matchid + 20000
endif

if !exists('g:minimap_search_matchid_safe_range')
    let g:minimap_search_matchid_safe_range = g:minimap_base_matchid + 30000
endif

if !exists('g:minimap_highlight')
    let g:minimap_highlight = 'Title'
endif

if !exists('g:minimap_block_filetypes')
    let g:minimap_block_filetypes = ['fugitive', 'nerdtree', 'tagbar']
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

if !exists('g:minimap_did_quit')
    let g:minimap_did_quit = 0
endif

if !exists('g:minimap_auto_start_win_enter')
    let g:minimap_auto_start_win_enter = 0
endif

if !exists('g:minimap_highlight_range')
    let g:minimap_highlight_range = 0
endif

if !exists('g:minimap_git_colors')
    let g:minimap_git_colors = 0
endif

if !exists('g:minimap_highlight_search')
    let g:minimap_highlight_search = 0
endif

if !exists('g:minimap_diffadd_color')
    let g:minimap_diffadd_color = 'DiffAdd'
endif

if !exists('g:minimap_diffremove_color')
    let g:minimap_diffremove_color = 'DiffDelete'
endif

if !exists('g:minimap_diff_color')
    let g:minimap_diff_color = 'DiffChange'
endif

if !exists('g:minimap_search_color')
    let g:minimap_search_color = 'Search'
endif

if !exists('g:minimap_cursor_color_priority')
    let g:minimap_cursor_color_priority = 110
endif
if !exists('g:minimap_git_color_priority')
    let g:minimap_git_color_priority = 100
endif
if !exists('g:minimap_search_color_priority')
    let g:minimap_search_color_priority = 120
endif

" Declare mutexes
let g:minimap_getting_window_info = 0
let g:minimap_opening = 0
" Declare id lists - used for storing matchids of color groups
let g:minimap_range_id_list = []
let g:minimap_git_id_list = []
let g:minimap_search_id_list = []
" Declare unit test specific items
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
    " Example mapping for nohlsearch to also clear the minimap search highlighting
    " nnoremap <silent> `` :nohlsearch<CR>:call minimap#vim#ClearColorSearch()<CR>
endif
