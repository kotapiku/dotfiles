" Syntax reloads invalidate bracket results even when the text is unchanged.
if has('nvim') && !exists('g:vscode')
  lua require('dotfiles.tex_performance').invalidate_syntax()
endif
