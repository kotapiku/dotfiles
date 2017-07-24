" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

" appearence
set number
set title
syntax on
set ruler    "display cursor position
set wildmenu    "completion

" indent
set autoindent
set cindent
set tabstop=4
set shiftwidth=4
set expandtab    "replace tab with space

" search
set incsearch    "increment
set hlsearch    "highlight
set ignorecase
set wrapscan

set noswapfile    "swapファイルをつくらない
nnoremap n nzz    "検索時にカーソル位置を中央に
nnoremap N Nzz
nnoremap Y y$    "Yでカーソル位置から行末までコピー

" clipboard
set clipboard+=unnamed

" 括弧補完
inoremap { {}<LEFT>
inoremap [ []<LEFT>
inoremap ( ()<LEFT>
" inoremap < <><LEFT>
inoremap " ""<LEFT>
inoremap ' ''<LEFT>
inoremap {<Enter> {}<Left><CR><ESC><S-o>

" caw comment out
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" color scheme
set background=dark
colorscheme solarized

" nerdtree
map <C-n> :NERDTreeToggle<CR>

" buffer
set hidden
nnoremap <silent>bp :bprevious<CR>
nnoremap <silent>bn :bnext<CR>
nnoremap <silent>bb :b#<CR>
nnoremap <silent>bf :bf<CR>
nnoremap <silent>bl :bl<CR>
nnoremap <silent>bm :bm<CR>
nnoremap <silent>bd :bdelete<CR>

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=/Users/kotapiku/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('/Users/kotapiku/.cache/dein')
  call dein#begin('/Users/kotapiku/.cache/dein')

  " Let dein manage dein
  " Required:
  call dein#add('/Users/kotapiku/.cache/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:
  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')
  call dein#add('tyru/caw.vim') " コメントアウト
  call dein#add('Shougo/deoplete.nvim') " 補完
    :let g:deoplete#enable_at_startup = 1
  call dein#add('ryanoasis/vim-devicons')
  call dein#add('tiagofumo/vim-nerdtree-syntax-highlight')
  call dein#add('vim-airline/vim-airline') " ステータスバー
    let g:airline_powerline_fonts = 1
    let g:airline#extensions#tabline#enabled = 1
    set laststatus=2
  call dein#add('vim-airline/vim-airline-themes')
    let g:airline_theme='solarized'
    let g:airline_solarized_bg='dark'
  call dein#add('ctrlpvim/ctrlp.vim')
    let g:ctrlp_show_hidden = 1
  call dein#add('Shougo/denite.nvim')
  call dein#add('scrooloose/nerdtree')
    let NERDTreeShowHidden = 1
    let g:NERDTreeShowBookmarks=1
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    autocmd StdinReadPre * let s:std_in=1
    autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

  " You can specify revision/branch/tag.
  call dein#add('Shougo/vimshell', { 'rev': '3787e5' })

  " Required:
  call dein#end()
  call dein#save_state()
  call deoplete#enable() 
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------
