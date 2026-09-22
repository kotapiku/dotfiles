" Keep bibliography folds open initially, and attach the same TexLab server.
setlocal foldenable foldlevel=99
if has('nvim') && !exists('g:vscode')
  lua require('dotfiles.tex').setup_buffer()
  let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
        \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
        \ . 'setlocal foldenable< foldlevel<'
        \ . ' | call luaeval(''require("dotfiles.tex").undo_buffer()'')'
endif
