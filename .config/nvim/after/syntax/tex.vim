" Syntax loads after ftplugins and resets its synchronization limits.
if has('nvim') && !exists('g:vscode')
  lua require('dotfiles.tex_performance').apply_syntax()
endif
