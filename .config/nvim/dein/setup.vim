" Shared bootstrap for terminal Neovim and the VS Code configuration.
let s:cache_home = empty($XDG_CACHE_HOME) ? expand('~/.cache') : $XDG_CACHE_HOME
let s:dein_base = s:cache_home . '/dein'
let s:dein_dir = s:dein_base . '/repos/github.com/Shougo/dein.vim'
let s:toml_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/toml'

if !isdirectory(s:dein_dir)
  call mkdir(fnamemodify(s:dein_dir, ':h'), 'p')
  let s:clone_output = system(['git', 'clone', 'https://github.com/Shougo/dein.vim', s:dein_dir])
  if v:shell_error
    echohl WarningMsg
    echom 'Unable to install dein: ' . s:clone_output
    echohl None
    finish
  endif
endif
execute 'set runtimepath^=' . fnameescape(s:dein_dir)

if dein#load_state(s:dein_base)
  call dein#begin(s:dein_base)
  if exists('g:vscode')
    call dein#add('Shougo/dein.vim')
    call dein#add('tyru/caw.vim')
    nmap <Leader>c <Plug>(caw:hatpos:toggle)
    vmap <Leader>c <Plug>(caw:hatpos:toggle)
  else
    call dein#load_toml(s:toml_dir . '/dein.toml', {'lazy': 0})
    call dein#load_toml(s:toml_dir . '/dein_lazy.toml', {'lazy': 1})
  endif
  call dein#end()
  call dein#save_state()
  call dein#recache_runtimepath()
endif

filetype plugin indent on
syntax enable
if dein#check_install()
  call dein#install()
endif
