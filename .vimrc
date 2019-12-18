" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

" appearence
set number
set title
syntax on
set ruler           " display cursor position
set wildmenu        " completion
set nofoldenable    " disable fold
if has('conceal')
  set conceallevel=0 concealcursor=
endif

" indent
set autoindent
set expandtab    " replace tab with space

set tabstop=4
set shiftwidth=4

" search
set incsearch    " incremental search
set hlsearch     " highlight
set ignorecase
set smartcase    " 大文字含んでいたら区別
set wrapscan

set noswapfile    " swapファイルをつくらない
nnoremap n nzz    " 検索時にカーソル位置を中央に
nnoremap N Nzz
nnoremap Y y$    " Yでカーソル位置から行末までコピー

" clipboard
set clipboard+=unnamed

" ignore in completion
set wildignorecase  " to ignorecase in e command
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.cmi,*.cmo,*.cma

" autocmd
augroup vimrc
  autocmd!
  au BufNewFile,BufRead *.x setf alex  " set filetype
  au BufNewFile,BufRead *.y setf happy
  au BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} setf markdown
  au BufNewFile,BufRead *.v setf coq
  au BufNewFile,BufRead *.lean setf lean
  au BufNewFile,BufRead *.jl setf julia
  au BufWritePre * call DeleteWhiteSpaces()  " delete whitespace in end of line
  au FileType ocaml,vim set shiftwidth=2
augroup End

augroup leanSetting
  autocmd!
  au BufWritePre *.lean %s/\( \|\W\|^\)not /\1¬/ge              " logical symbols
  au BufWritePre *.lean %s/\( \|\W\|^\)and\( \|$\)/\1∧\2/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)or\( \|$\)/\1∨\2/ge
  au BufWritePre *.lean %s/<->/↔/ge
  au BufWritePre *.lean %s/->/→/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)forall/\1∀/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)exists/\1∃/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)fun/\1λ/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)~=/\1≠/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)nat\( \|$\)/\1ℕ\2/ge     " types
  au BufWritePre *.lean %s/\( \|\W\|^\)int\( \|$\)/\1ℤ\2/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)rat\( \|$\)/\1ℚ\2/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)real\( \|$\)/\1ℝ\2/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)alpha/\1α/ge             " greek letters
  au BufWritePre *.lean %s/\( \|\W\|^\)beta/\1β/ge
  au BufWritePre *.lean %s/\( \|\W\|^\)gamma/\1γ/ge
  au BufWritePre *.lean %s/?(\([^)]\))/⌞\1⌟/ge                  " brackets
  au BufWritePre *.lean %s/{{/⦃/ge
  au BufWritePre *.lean %s/}}/⦄/ge
  au BufWritePre *.lean %s/\\<</⟪/ge
  au BufWritePre *.lean %s/\\>>/⟫/ge
  au BufWritePre *.lean %s/\\</⟨/ge
  au BufWritePre *.lean %s/\\>/⟩/ge
  au BufWritePre *.lean %s/}}/⦄/ge
  au BufWritePre *.lean %s/_1\( \|\W\|$\)/₁\1/ge                " subscripts
  au BufWritePre *.lean %s/_2\( \|\W\|$\)/₂\1/ge
  au BufWritePre *.lean %s/_3\( \|\W\|$\)/₃\1/ge
  au BufWritePre *.lean %s/_4\( \|\W\|$\)/₄\1/ge
  au BufWritePre *.lean %s/_5\( \|\W\|$\)/₅\1/ge
  au BufWritePre *.lean %s/_6\( \|\W\|$\)/₆\1/ge
  au BufWritePre *.lean %s/_7\( \|\W\|$\)/₇\1/ge
  au BufWritePre *.lean %s/_8\( \|\W\|$\)/₈\1/ge
  au BufWritePre *.lean %s/_9\( \|\W\|$\)/₉\1/ge
augroup End

function! DeleteWhiteSpaces()
  let pos = getpos(".")
  %s/\s\+$//ge
  call setpos('.', pos)
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

nnoremap <C-s> :CoqToCursor<CR>

function! OpenMiddleBuffer()
  let ls = map(split(execute(":ls"), "\n"), "get(split(v:val), 0)")
  execute(":b" . str2nr(get(ls, (len(ls)-1)/2)))
endfunction

" keymap
let mapleader = "]"

inoremap jk <Esc>
nnoremap gs  :<C-u>%s///g<Left><Left><Left>
vnoremap gs  :s///g<Left><Left><Left>
nnoremap k   gk
nnoremap j   gj
vnoremap k   gk
vnoremap j   gj
nnoremap 0   g0
nnoremap $   g$
nnoremap ; :
nnoremap : ;

" terminal mode
tnoremap <silent> jk <C-\><C-n>

" open dotfiles by command
command! Zshrc e ~/.zshrc
command! Vimrc e ~/.vimrc
command! Tmuxconf e ~/.tmux.conf
command! Deintoml e ~/dotfiles/config/nvim/dein/toml/dein.toml
command! DeintomlLazy e ~/dotfiles/config/nvim/dein/toml/dein_lazy.toml

if has("mac")
  let g:python_host_prog='/usr/local/bin/python2'
  let g:python3_host_prog='/Users/kotapiku/.pyenv/shims/python'
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
 let s:toml      = s:toml_dir . '/dein.toml'
 let s:lazy_toml = s:toml_dir . '/dein_lazy.toml'

 " TOML を読み込み、キャッシュしておく
 call dein#load_toml(s:toml,      {'lazy': 0})
 call dein#load_toml(s:lazy_toml, {'lazy': 1})

 " Required:
 call dein#end()
 call dein#save_state()

 call map(dein#check_clean(), "delete(v:val, 'rf')")
 call dein#recache_runtimepath()
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
