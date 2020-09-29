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

### 🛠  Commands

| Flag                   | Description                    |
|------------------------|--------------------------------|
| Minimap                | Show minimap window            |
| MinimapClose           | Close minimap window           |
| MinimapToggle          | Toggle minimap window          |
| MinimapRefresh         | Force refresh minimap window   |
| MinimapUpdateHighlight | Force update minimap highlight |

### ⚙  Options

| Flag                   | Default | Description                                        |
|------------------------|---------|----------------------------------------------------|
| `g:minimap_left`       | `0`     | if set minimap window will append left             |
| `g:minimap_width`      | `10`    | the width of the minimap window in characters      |
| `g:minimap_highlight`  | `Title` | the color of the highlighting for current position |
| `g:minimap_auto_start` | `0`     | if set minimap will show at startup                |

### 💬 F.A.Q

---
#### Highlight and scroll are not working properly.

Check the vim version you are using. `minimap.vim` requires [vim 8.2+](https://github.com/wfxr/minimap.vim/issues/5) or [neovim 0.5.0+](https://github.com/wfxr/minimap.vim/issues/4).

---
#### Integrated with diagnostics or git status plugins?

Not implemented currently but it should be possible. I am a beginner in vim plugin.
I don't known how to implement such features correctly and efficiently.
Welcome to contribute!

---
#### Minimap window is too wide for me, how to use it as a simple scrollbar?

You can decrease the minimap window width:
```vim
let g:minimap_width = 2
```
Or use [scrollbar.nvim](https://github.com/Xuyuanp/scrollbar.nvim) instead if what you want
is a pure scrollbar indicator.

### 📦 Related Projects

* [code-minimap](https://github.com/wfxr/code-minimap): A high performance code minimap render.
* [scrollbar.nvim](https://github.com/Xuyuanp/scrollbar.nvim): A pure scrollbar indicator for neovim (nightly).
* [vim-minimap](https://github.com/severin-lemaignan/vim-minimap): A minimap plugin written in python.

### 📃 License

[MIT](https://wfxr.mit-license.org/2020) (c) Wenxuan Zhang
