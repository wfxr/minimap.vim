# Repository Guidelines

## Project Structure & Module Organization
`plugin/minimap.vim` is the entry point that defines commands, default options, and autocommands. Core implementation lives in `autoload/minimap/vim.vim`; keep public autoload functions named like `minimap#vim#MinimapOpen()` and script-local helpers as `s:helper_name()`. Vim help text belongs in `doc/minimap-vim.txt`. Tests live in `t/` and follow the existing `*_tests.vim` pattern. Shell helpers for external minimap generation are in `bin/`.

## Build, Test, and Development Commands
There is no separate build step for the plugin itself.

- `pre-commit run --all-files`: runs whitespace checks, `vint`, and the local license refresh hook.
- `vim +TestifySuite` or `nvim -c "set rtp+=<path-to-vim-testify>" -c "set rtp+=./" -S <path-to-vim-testify>/plugin/testify.vim +TestifySuite testfile`: runs the full unit suite from the repository root.
- `:TestifyFile`: runs only the current file in `t/` when opened inside Vim/Neovim.

For manual testing, install `code-minimap` and load the plugin in Vim/Neovim, then exercise commands such as `:MinimapToggle` and `:MinimapRefresh`.

## Coding Style & Naming Conventions
Use Vimscript with 4-space indentation and keep the existing guard-and-early-return style. New functions should use `abort`. Prefer descriptive names over abbreviations unless matching existing minimap terminology (`mm`, `win_info`). Keep user-facing Ex commands in `CamelCase` with the `Minimap` prefix. Run `vint` through `pre-commit` before sending changes.

## Testing Guidelines
Tests use [vim-testify](https://github.com/dhruvasagar/vim-testify). Add or update tests for behavior changes, especially around buffer handling, search highlighting, and git diff parsing. Follow the established test naming style: script-local functions like `s:minimap_test_search_history()` registered with `testify#it()`. Run the full suite from the repo root before opening a PR.

## Commit & Pull Request Guidelines
PRs should complete the checklist in `.github/pull_request_template.md`: confirm README/issue review, passing tests, added tests when needed, self-review, and documentation updates. Include a concise description, change type, and your Vim/Neovim test environment.
