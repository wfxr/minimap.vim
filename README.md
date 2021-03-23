<h1 align="center">📡 minimap.vim</h1>
<p align="center">
    <em>Blazing fast minimap for vim, powered by <a href="https://github.com/wfxr/code-minimap">🛰 code-minimap</a> written in Rust.</em>
</p>

<p align="center">
    <a href="https://github.com/wfxr/minimap.vim/actions?query=workflow%3Aci">
        <img src="https://github.com/wfxr/minimap.vim/workflows/CI/badge.svg" alt="CI"/>
    </a>
    <a href="https://wfxr.mit-license.org/2020">
        <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"/>
    </a>
    <a href="https://github.com/vim/vim">
        <img src="https://img.shields.io/badge/vim-8.2+-yellow.svg" alt="Vim"/>
    </a>
    <a href="https://github.com/neovim/neovim">
        <img src="https://img.shields.io/badge/nvim-0.5.0+-yellow.svg" alt="Neovim"/>
    </a>
    <a href="https://github.com/pre-commit/pre-commit">
        <img src="https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white" alt="pre-commit" />
    </a>
    <a href="https://github.com/wfxr/minimap.vim/graphs/contributors">
        <img src="https://img.shields.io/github/contributors/wfxr/minimap.vim" alt="Contributors"/>
    </a>
</p>

![screenshot](https://raw.githubusercontent.com/wfxr/i/master/minimap-vim.gif)

### ✨ Features

* **Blazing-fast** (see [benchmark](https://github.com/wfxr/code-minimap#benchmark)).
* Dynamic **scaling**.
* Real-time **highlight**.
* It can be used to **scroll** buffer (in vim's way!).

### 📥 Installation

**Requirement**

- [🛰`code-minimap`](https://github.com/wfxr/code-minimap) is required. The plugin receives rendered minimap from it.
- vim8.2+, or neovim 0.5.0+.

Use your favorite plugin manager, [vim-plug](https://github.com/junegunn/vim-plug) for example:

```vim
Plug 'wfxr/minimap.vim'
```

*If you need to install the plugin manually, you can refer to this issue: [#2](https://github.com/wfxr/minimap.vim/issues/2).*

You can use [cargo](https://github.com/rust-lang/cargo) to install 'code-minimap' simultaneously (Only recommended for rust users):

```vim
Plug 'wfxr/minimap.vim', {'do': ':!cargo install --locked code-minimap'}
```

### 📑 Example configuration

```vim
let g:minimap_width = 10
let g:minimap_auto_start = 1
let g:minimap_auto_start_win_enter = 1
```

### 🛠  Commands

| Flag                   | Description                    |
|------------------------|--------------------------------|
| Minimap                | Show minimap window            |
| MinimapClose           | Close minimap window           |
| MinimapToggle          | Toggle minimap window          |
| MinimapRefresh         | Force refresh minimap window   |
| MinimapUpdateHighlight | Force update minimap highlight |

### ⚙  Options

| Flag                             | Default                                                   | Description                                                          |
|----------------------------------|-----------------------------------------------------------|----------------------------------------------------------------------|
| `g:minimap_auto_start`           | `0`                                                       | if set minimap will show at startup                                  |
| `g:minimap_auto_start_win_enter` | `0`                                                       | if set with `g:minimap_auto_start` minimap shows on `WinEnter`       |
| `g:minimap_width`                | `10`                                                      | the width of the minimap window in characters                        |
| `g:minimap_highlight`            | `Title`                                                   | the color group for current position                                 |
| `g:minimap_base_highlight`       | `Normal`                                                  | the base color group for minimap                                     |
| `g:minimap_block_filetypes`      | `['fugitive', 'nerdtree', 'tagbar' ]`                     | disable minimap for specific file types                              |
| `g:minimap_block_buftypes`       | `['nofile', 'nowrite', 'quickfix', 'terminal', 'prompt']` | disable minimap for specific buffer types                            |
| `g:minimap_close_filetypes`      | `['startify', 'netrw', 'vim-plug']`                       | close minimap for specific file types                                |
| `g:minimap_close_buftypes`       | `[]`                                                      | close minimap for specific buffer types                              |
| `g:minimap_left`                 | `0`                                                       | if set minimap window will append left                               |
| `g:minimap_highlight_range`      | `0`                                                       | if set minimap will highlight range of visible lines                 |

### 💬 F.A.Q

---
#### Highlight and scroll are not working properly.

Check the vim version you are using. `minimap.vim` requires [vim 8.2+](https://github.com/wfxr/minimap.vim/issues/5) or [neovim 0.5.0+](https://github.com/wfxr/minimap.vim/issues/4).

---
#### Integrated with diagnostics or git status plugins?

Not implemented currently but it should be possible.
Welcome to contribute!

---
#### Minimap window is too wide for me, how to use it as a simple scrollbar?

You can reduce the width of the minimap window:
```vim
let g:minimap_width = 2
```
Or use [scrollbar.nvim](https://github.com/Xuyuanp/scrollbar.nvim) instead if what you want
is a pure scrollbar indicator.

---
#### I don't like the default highlight group, how to change it?

Choose any one of the highlight groups (or define a new one) and just set it for minimap like this:
```vim
hi MinimapCurrentLine ctermfg=Green guifg=#50FA7B guibg=#32302f
let g:minimap_highlight = 'MinimapCurrentLine'
```

*All existed Highlight groups can be displayed by `:hi`.*

---
#### Minimap shows up as a jumble of characters?

Check that your encoding is set to `utf-8` and not `latin1` (for Vim users).
Also, ensure that you're using a Unicode-compatible font that has Braille characters in it.

---
#### What is `g:minimap_highlight_range` and how do you use it?

You can have the minimap highlight all the visible lines in your current window
by setting `g:minimap_highlight_range`.  If you use Neovim, and your version
is recent enough (after November 7, 2020), you can set this option to update
the highlight when the window is scrolled.

![screenshot-highlight-range](https://raw.githubusercontent.com/wfxr/i/master/minimap-vim-highlight-range.png)
---

### 📦 Related Projects

* [code-minimap](https://github.com/wfxr/code-minimap): A high performance code minimap render.
* [scrollbar.nvim](https://github.com/Xuyuanp/scrollbar.nvim): A pure scrollbar indicator for neovim (nightly).
* [vim-minimap](https://github.com/severin-lemaignan/vim-minimap): A minimap plugin written in python.

### 🌼 Maintainers

| [![wfxr](https://avatars1.githubusercontent.com/u/6105425?s=72)](https://github.com/wfxr) | [![rabirabirara](https://avatars1.githubusercontent.com/u/59306451?s=72)](https://github.com/rabirabirara) |
| :---:                                                                                     | :---:                                                                                                      |
| [wfxr](https://github.com/wfxr)                                                           | [rabirabirara](https://github.com/rabirabirara)                                                            |

### 📃 License

[MIT](https://wfxr.mit-license.org/2020) (c) Wenxuan Zhang
