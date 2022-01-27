set relativenumber
set number

set nobackup
set nowb
set noswapfile

set expandtab
set tabstop=4
set shiftwidth=4

let mapleader = ","
nmap <leader>q :q<cr>
nmap <leader>w :w<cr>
map  <Space>   /
map  <C-Space> ?

set mouse=a
set clipboard=unnamedplus

call plug#begin(stdpath('data') . '/plugged')
Plug 'joshdick/onedark.vim'
Plug 'RRethy/vim-hexokinase', { 'do': 'make hexokinase' }

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-buffer'
Plug 'simrat39/rust-tools.nvim'

Plug 'digitaltoad/vim-pug'
Plug 'udalov/kotlin-vim'
call plug#end()

set termguicolors
colorscheme onedark

let g:Hexokinase_highlighters = [ 'sign_column' ]

set completeopt=menuone,noinsert,noselect
set shortmess+=c
set signcolumn=yes
set conceallevel=2

lua <<EOFLUA
require('lspconfig').kotlin_language_server.setup({
    cmd = { "/home/eetu/src/kotlin-language-server/server/build/install/server/bin/kotlin-language-server" },
})
require('rust-tools').setup()
require('cmp').setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path'     },
        { name = 'buffer'   },
    },
})
EOFLUA

nnoremap <silent> Ö <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> Ä <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> ö <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> ä <cmd>lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap <silent> å <cmd>lua vim.lsp.buf.code_action()<CR>
