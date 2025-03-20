:set nocompatible
:filetype off
:set mouse=a
:set number
:set relativenumber
:set shell=/bin/bash
:set clipboard+=unnamedplus
:set tw =0
:set ts=4
:set sw=4
:set termguicolors
:set autoindent
:set hlsearch
:set incsearch

:set ignorecase
:set smartcase
:set smartindent
:set lazyredraw
:set encoding=utf-8
:set linebreak
:set laststatus=2
:set ruler
:set wildmenu
:set autoread
:set confirm
:set history=1000
:set noswapfile
:set nowrap
:colorscheme one
:syntax enable
:set background=dark
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

:autocmd InsertEnter * set cul
:autocmd InsertLeave * set nocul

set timeoutlen=1000
set ttimeoutlen=0
nnoremap <C-j> :bprev<CR>
nnoremap <C-k> :bnext<CR>
noremap <silent> <C-S>          :update<CR>
vnoremap <silent> <C-S>         <C-C>:update<CR>
inoremap <silent> <C-S>         <C-O>:update<CR>

noremap <silent> <C-q>          :quit<CR>
vnoremap <silent> <C-q>         <C-C>:quit<CR>
inoremap <silent> <C-q>         <C-O>:quit<CR>
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv


"Airline Stuff
let g:airline#extensions#tabline#left_sep = '┃ '
let g:airline#extensions#tabline#left_alt_sep = ' ┃'
let g:airline_theme='onedark'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = 1
let g:airline_detect_paste=1
let g:airline#extensions#bufferline#enabled = 1
let g:airline#extensions#capslock#enabled = 1
let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#unicode#enabled = 1




if !exists('g:airline_symbols')
    let g:airline_symbols = {}
  endif

  let g:airline_extensions = ['branch', 'coc', 'ctrlspace', 'cursormode', 'fzf', 'keymap', 'languageclient', 'netrw', 'po', 'poetv', 'tabline', 'term', 'vimcmake', 'vimtex', 'virtualenv', 'wordcount', 'whitespace']
