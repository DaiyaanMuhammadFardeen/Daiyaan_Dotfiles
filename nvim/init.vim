
" vim:fileencoding=utf-8:foldmethod=marker

"    .s    s.
"          SS.  .s5SSSs.   .s5SSSs.   .s    s.   s.   .s5ssSs.
"    sSs.  S%S        SS.        SS.        SS.  SS.     SS SS.
"    SS`S. S%S  sS    `:;  sS    S%S  sS    S%S  S%S  sS SS S%S
"    SS `S.S%S  SSSs.      SS    S%S  SS    S%S  S%S  SS :; S%S
"    SS  `sS%S  SS         SS    S%S   SS   S%S  S%S  SS    S%S
"    SS    `:;  SS         SS    `:;   SS   `:;  `:;  SS    `:;
"    SS    ;,.  SS    ;,.  SS    ;,.    SS  ;,.  ;,.  SS    ;,.
"    :;    ;:'  `:;;;;;:'  `:;;;;;:'     `:;;:'  ;:'  :;    ;:'


" Git --> https://github.com/DaiyaanMuhammad/Daiyaan_Dotfiles.git



"Vundle Plugins {{{
set rtp+=~/.vim/bundle/Vundle.vim
"git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'one-dark/onedark.nvim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'mboughaba/i3config.vim'
Plugin 'preservim/nerdtree'
Plugin 'neoclide/coc.nvim', {'branch': 'release'}
Plugin 'NLKNguyen/papercolor-theme'
Plugin 'easymotion/vim-easymotion'
Plugin 'lilydjwg/colorizer'
Plugin 'sonph/onehalf', { 'rtp': 'vim' }
Plugin 'xolox/vim-easytags'
Plugin 'xolox/vim-misc'
Plugin 'preservim/tagbar'
Plugin 'https://github.com/morhetz/gruvbox.git'
Plugin 'psliwka/vim-smoothie'
Plugin 'ryanoasis/vim-devicons'
Plugin 'tpope/vim-commentary'
Plugin 'tomasiser/vim-code-dark'
" Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Plugin 'junegunn/fzf.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'
Plugin 'mbbill/undotree'
Plugin 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plugin 'mattn/emmet-vim'
call vundle#end()            " required
filetype indent on
filetype plugin indent on    " required}}}

" Settings {{{
set nocompatible
set foldcolumn=4
set foldmethod=marker
set encoding=utf-8
set mouse=a
filetype on
autocmd BufEnter * lcd %:p:h "Sync the directory with the current file in buffer
autocmd VimEnter * TSEnable highlight
autocmd VimEnter * TSEnable indent
filetype plugin on
set number
set relativenumber
set hidden
set shell=/bin/zsh
set clipboard+=unnamedplus
set background=dark
set t_Co=256
set tw=0
set termguicolors
set splitbelow splitright
set autoindent
set ts=4
set sw=4
set hlsearch
set incsearch
set ignorecase
set smartcase
set smartindent
set lazyredraw
set guifont=JetBrainsMono\ 12
set linebreak
set laststatus=2
set ruler
set wildmenu
set undodir=~/.vim/undodir
set undofile
set autoread
set confirm
set history=1000
set noswapfile
set nowrap
set cursorline
set cursorcolumn
syntax on
set tags+=$HOME/Code/
let g:gruvbox_contrast_dark = 1
let g:gruvbox_bold = 1
let g:gruvbox_italic = 1
let g:gruvbox_transparent_bg = 1
let g:onedark_darker_diagnostics = 1
let g:onedark_diagnostics_undercurl = 1
let g:onedark_italics = 1
let g:codedark_italics = 1

colorscheme onedark
"}}}

" Key mappings {{{1

" Buffers as tabs {{{2
nnoremap <C-l> :bnext<CR>
nnoremap <C-Right> :bnext<CR>
nnoremap <C-h> :bprev<CR>
nnoremap <C-Left> :bprev<CR>
inoremap <C-l> <C-C>:bprev<CR>
inoremap <C-h> <C-C>:bnext<CR>
vnoremap <C-l> <C-C>:bprev<CR>
vnoremap <C-h> <C-C>:bnext<CR>
"}}}2

" Move through windows using Shift+vim keys  {{{2
nnoremap <S-H> <C-W>h
nnoremap <S-Left> <C-W>h
nnoremap <S-J> <C-W>j
nnoremap <S-K> <C-W>k
nnoremap <S-L> <C-W>l
nnoremap <S-Right> <C-W>l
"}}}2

"Saving, quiting and closing  {{{2
noremap <silent> <C-S>          :update<CR>
vnoremap <silent> <C-S>         <C-C>:update<CR>
inoremap <silent> <C-S>         <C-O>:update<CR>
" Alt+q to close buffers
noremap <silent> <M-q>          :bdelete<CR>
vnoremap <silent> <M-q>         <C-C>:bdelete<CR>
inoremap <silent> <M-q>         <C-O>:bdelete<CR>
" Ctrl+q to quit
noremap <silent> <C-q>          :quit<CR>
vnoremap <silent> <C-q>         <C-C>:quit<CR>
inoremap <silent> <C-q>         <C-O>:quit<CR>
" Ctrl+Shift+w to save a file that has root access only
noremap <silent> <C-S-s>          :w !sudo tee %<CR>
vnoremap <silent> <C-S-s>         <C-C>:w !sudo tee %<CR>
inoremap <silent> <C-S-s>         <C-O>:w !sudo tee %<CR>
"}}}2

" Alt+j/k to move line/lines up and down {{{2
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
"}}}2

" Plugin Mappings {{{2
" easy-motion trigger
map <S-e> <Plug>(easymotion-prefix)e
map <S-w> <Plug>(easymotion-prefix)w
map <S-b> <Plug>(easymotion-prefix)b
map <S-f> <Plug>(easymotion-prefix)s
" Hex color colorizer
inoremap <C-c> "+y
nnoremap <C-c> "+y
vnoremap <C-c> "+y

inoremap <C-a> <esc>ggVG
" Toggle nerd tree
nnoremap <M-e> :NERDTreeToggle<CR>
" Undo tree
nnoremap <leader>u :UndotreeToggle<CR>
"}}}2

" <++> Guided navigation {{{2
noremap <leader><space> <Esc>/<++><Enter>"_c4l
inoremap <leader><space> <Esc>/<++><Enter>"_c4l
vnoremap <leader><space> <Esc>/<++><Enter>"_c4l
"2}}}

"Misc {{{2
noremap <return> i<return><Esc>

"Fix trailling whitespaces and mixed indenting
map <F8> :%s/\s\+$//e<cr>gg=G:<cr>:noh<cr>

" Make search results appear at the center of the screen
:nnoremap n nzz
:nnoremap N Nzz
:nnoremap * *zz
:nnoremap # #zz
:nnoremap g* g*zz
:nnoremap g# g#zz

" Clear search history
"inoremap " ""<left>
"inoremap " ""<left>
"inoremap ' ''<left>
"inoremap ( ()<left>
"inoremap [ []<left>
"inoremap { {}<left>
"inoremap ' ''<left>
"inoremap ( ()<left>
"inoremap [ []<left>
"inoremap { {}<left>

"2}}}

" Arrowkeys to scroll the entire document instead of lines {{{2
nnoremap <left> 2z<left>
vnoremap <left> 2z<left>
nnoremap <right> 2z<right>
vnoremap <right> 2z<right>
nnoremap <up> <C-y>
vnoremap <up> <C-y>
nnoremap <down> <C-e>
vnoremap <down> <C-e>
" 2}}}

" Vim-airline Plugin {{{1
let g:airline#extensions#tabline#left_sep = "\uE0B4 "
let g:airline#extensions#tabline#left_alt_sep = "\uE0B5 "
let g:airline_left_sep = "\uE0B4"
let g:airline_right_sep = "\uE0B6"
let g:airline_theme='onedark'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = 0
let g:airline_detect_paste=1
let g:airline#extensions#bufferline#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#capslock#enabled = 1
let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#csv#enabled = 1
let g:airline#extensions#undotree#enabled = 1
let g:airline#extensions#fzf#enabled = 1
let g:airline#extensions#nvimlsp#enabled = 1
let g:airline#extensions#quickfix#enabled = 1
let g:airline#extensions#term#enabled = 1
let g:airline#extensions#fugitiveline#enabled = 1
let g:airline#extensions#unicode#enabled = 1
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:rainbow_active = 1
"}}}1

" Vim-easymotion Plugin{{{
let g:EasyMotion_use_upper = 1
let g:EasyMotion_smartcase = 1
let g:EasyMotion_use_smartsign_us = 1
"}}}

" Vim-Tabnine plugin {{{
set completeopt-=preview
"}}}

let g:goyo_width=100
let g:goyo_height=95

let g:coc_global_extensions = [
			\ 'coc-pairs',
			\ 'coc-eslint',
			\ 'coc-tabnine',
			\ 'coc-tsserver',
			\ 'coc-prettier',
			\ ]

inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
set laststatus=2 statusline=%02n:%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P

inoremap <expr> <cr> getline(".")[col(".")-2:col(".")-1]=="{}" ? "<cr><esc>O" : "<cr>"

"command! -range -nargs=1 Comment :execute "'<,'>normal! <C-v>0I" . <f-args> . "<Esc><Esc>"
"nnoremap <C-/> <esc>:Comment
"vnoremap <C-/> <esc>:Comment
"nnoremap <C-/> <esc>:Comment



autocmd FileType c let b:coc_pairs_disabled = ['<']
autocmd FileType cpp let b:coc_pairs_disabled = ['<']
nmap <F2> :TagbarToggle<CR>
let g:PaperColor_Theme_Options = {
			\   'theme': {
			\     'default.dark': {
			\       'transparent_background': 1,
			\			'allow_bold':1,
			\			'allow_italic':1
			\     }
			\   }
			\ }

nmap <F5> :source ~/.config/nvim/init.vim <cr>
map <F3> :noh<CR>
let g:user_emmet_install_global = 0
autocmd FileType html,css,php EmmetInstall
set expandtab
set tabstop=4
set shiftwidth=4
