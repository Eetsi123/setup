set relativenumber
set number
set termguicolors
set conceallevel=2

set nobackup
set nowb
set noswapfile

set expandtab
set tabstop=4
set shiftwidth=4

let mapleader = ','
nmap <leader>q :q<cr>
nmap <leader>w :w<cr>
map  <Space>   /
map  <C-Space> ?

set mouse=a
set clipboard=unnamedplus

let s:autoload = stdpath('data') .. '/site/autoload'
let s:plug     = s:autoload      .. '/plug.vim'
if filereadable(s:plug) == 0
    execute '!aria2c --dir' s:autoload
        \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    execute 'source' s:plug
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(stdpath('data') .. '/plugged')
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-buffer'

Plug 'simrat39/rust-tools.nvim'
Plug 'digitaltoad/vim-pug'
call plug#end()

lua <<EOFLUA
require('cmp').setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path'     },
        { name = 'buffer'   },
    },
})

require('rust-tools').setup()
EOFLUA

nnoremap <silent> Ö <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> Ä <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> Å <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> ö <cmd>lua vim.diagnostic.goto_prev()<CR>
nnoremap <silent> ä <cmd>lua vim.diagnostic.goto_next()<CR>
nnoremap <silent> å <cmd>lua vim.lsp.buf.code_action()<CR>
