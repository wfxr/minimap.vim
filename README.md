🛰  minimap for vim
===============

![screenshot](https://raw.githubusercontent.com/wfxr/i/master/minimap-vim.gif)

### 💠 Features

* Dynamic **scaling**.
* Real-time **highlight**.
* It's **blazing-fast**.
* It can be used to **scroll** buffer (in vim's way!).

### 📥 Installation

Use your favorite plugin manager, [vim-plug](https://github.com/junegunn/vim-plug) for example:

```vim
Plug 'wfxr/minimap.vim'
```

**Note**: [`code-minimap`](https://github.com/wfxr/code-minimap) is required. `minimap.vim` uses it to render minimap at 🚀 speed.

### ⚙  Options

| Flag                   | Default | Description                                        |
|------------------------|---------|----------------------------------------------------|
| `g:minimap_left`       | `0`     | if set minimap window will append left             |
| `g:minimap_width`      | `10`    | the width of the Tagbar window in characters       |
| `g:minimap_highlight`  | `Title` | the color of the highlighting for current position |
| `g:minimap_auto_start` | `0`     | if set minimap will show at startup                |

### 🛠  Commands

| Flag                   | Description                    |
|------------------------|--------------------------------|
| Minimap                | Show minimap window            |
| MinimapClose           | Close minimap window           |
| MinimapToggle          | Toggle minimap window          |
| MinimapRefresh         | Force refresh minimap window   |
| MinimapUpdateHighlight | Force update minimap highlight |


### 📦 dependencies

* [code-minimap](https://github.com/wfxr/code-minimap)

### 📃 License

[MIT](https://wfxr.mit-license.org/2020) (c) Wenxuan Zhang
