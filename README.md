# dubzline.nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

My statusline. There are many like it...

## Installation

### [vim-plug](https://github.com/junegunn/vim-plug)

```lua
Plug 'dubzland/dubzline.nvim'
" For icons "
Plug 'nvim-tree/nvim-web-devicons'
" For git symbols "
Plug 'lewis6991/gitsigns.nvim'
```

### [paq](https://github.com/savq/paq-nvim)

```lua
require "paq" {
  'dubzland/dubzline.nvim',
  requires = {
    'nvim-tree/nvim-web-devicons',
    'lewis6991/gitsigns.nvim',
  }
}
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'dubzland/dubzline.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'lewis6991/gitsigns.nvim',
  }
}
```
