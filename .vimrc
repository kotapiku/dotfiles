" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

" appearence
set number
set title
syntax on
set ruler           "display cursor position
set wildmenu        "completion
set nofoldenable    "disable fold

" indent
set autoindent
set cindent
set expandtab    "replace tab with space

set tabstop=4
set shiftwidth=4

" search
set incsearch    "incremental search
set hlsearch     "highlight
set ignorecase
set smartcase    "大文字含んでいたら区別
set wrapscan

set noswapfile    "swapファイルをつくらない
nnoremap n nzz    "検索時にカーソル位置を中央に
nnoremap N Nzz
nnoremap Y y$    "Yでカーソル位置から行末までコピー

" clipboard
set clipboard+=unnamed

" ignore in completion
set wildignorecase  "to ignorecase in e command
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.cmi,*.cmo,*.cma

" autocmd
augroup vimrc
  autocmd!
  au BufNewFile,BufRead *.x setf alex  " set filetype
  au BufNewFile,BufRead *.y setf happy
  au BufWritePre * :%s/\s\+$//ge       " delete whitespace in end of line
  au FileType ocaml,vim set shiftwidth=2
augroup End

" nerdtree
nnoremap <Space>n :NERDTreeToggle<CR>

" defx
autocmd FileType defx call s:defx_my_settings()
  function! s:defx_my_settings() abort
	" Define mappings
	nnoremap <silent><buffer><expr> <CR>
	\ defx#do_action('open')
	nnoremap <silent><buffer><expr> c
	\ defx#do_action('copy')
	nnoremap <silent><buffer><expr> m
	\ defx#do_action('move')
	nnoremap <silent><buffer><expr> p
	\ defx#do_action('paste')
	nnoremap <silent><buffer><expr> K
	\ defx#do_action('new_directory')
	nnoremap <silent><buffer><expr> N
	\ defx#do_action('new_file')
	nnoremap <silent><buffer><expr> d
	\ defx#do_action('remove')
	nnoremap <silent><buffer><expr> r
	\ defx#do_action('rename')
	nnoremap <silent><buffer><expr> x
	\ defx#do_action('execute_system')
	nnoremap <silent><buffer><expr> .
	\ defx#do_action('toggle_ignored_files')
	nnoremap <silent><buffer><expr> h
	\ defx#do_action('cd', ['..'])
	nnoremap <silent><buffer><expr> ~
	\ defx#do_action('cd')
	nnoremap <silent><buffer><expr> q
	\ defx#do_action('quit')
	nnoremap <silent><buffer><expr> <Space>
	\ defx#do_action('toggle_select') . 'j'
	nnoremap <silent><buffer><expr> *
	\ defx#do_action('toggle_select_all')
	nnoremap <silent><buffer><expr> j
	\ line('.') == line('$') ? 'gg' : 'j'
	nnoremap <silent><buffer><expr> k
	\ line('.') == 1 ? 'G' : 'k'
	nnoremap <silent><buffer><expr> <C-l>
	\ defx#do_action('redraw')
  endfunction

" buffer
set hidden
set nosol   " buffer間をカーソル位置を保存して移動
nnoremap <Space>bp :bp<CR>
nnoremap <Space>bn :bn<CR>
nnoremap <Space>bb :b#<CR>
nnoremap <Space>bf :bf<CR>
nnoremap <Space>bm :call OpenMiddleBuffer()<CR>
nnoremap <Space>bl :bl<CR>
nnoremap <Space>bd :bp<bar>bd#<CR>

function OpenMiddleBuffer()
  let ls = map(split(execute(":ls"), "\n"), "get(split(v:val), 0)")
  execute(":b" . str2nr(get(ls, (len(ls)-1)/2)))
endfunction

" keymap
let mapleader = "\\"
inoremap jk <Esc>
nnoremap gs  :<C-u>%s///g<Left><Left><Left>
vnoremap gs  :s///g<Left><Left><Left>
nnoremap k   gk
nnoremap j   gj
vnoremap k   gk
vnoremap j   gj
nnoremap gk  k
nnoremap gj  j
vnoremap gk  k
vnoremap gj  j
nnoremap ; :
nnoremap : ;

" terminal mode
tnoremap <silent> jk <C-\><C-n>

if has("mac")
  let g:python_host_prog='/usr/local/bin/python2'
  let g:python3_host_prog='/Users/kotapiku/.pyenv/shims/python3'
elseif has("unix")
  let g:python_host_prog='/usr/bin/python'
  let g:python3_host_prog='/usr/bin/python3'
endif

if has("nvim")
"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
let s:dein_path = $HOME . '/dotfiles/config/nvim/dein'
let s:dein_repo_path = s:dein_path . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_repo_path)
  execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_path
endif

execute 'set runtimepath^=' . s:dein_repo_path

" Required:
if dein#load_state(s:dein_path)

" XDG base direcory compartible
 let g:dein#cache_directory = $HOME . '/.cache/dein'

 " dein begin
 call dein#begin(s:dein_path)
 let s:toml_dir  = s:dein_path . '/toml'
 let s:lazy_toml = s:toml_dir . '/dein_lazy.toml'
 if has("mac")
   let s:toml      = s:toml_dir . '/dein.toml'
 elseif has("unix")
   let s:toml      = s:toml_dir . '/dein_unix.toml'
 endif

 " TOML を読み込み、キャッシュしておく
 call dein#load_toml(s:toml,      {'lazy': 0})
 call dein#load_toml(s:lazy_toml, {'lazy': 1})

 " Required:
 call dein#end()
 call dein#save_state()

 call map(dein#check_clean(), "delete(v:val, 'rf')")
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------
endif

set background=dark
colorscheme gruvbox

set clipboard=unnamedplus
