" Keep Skim's existing window eligible for macOS automatic document tabbing.
" Requires AppleWindowTabbingMode=always (globally or for Skim).
function! vimtex#view#skim_tabs#new() abort
  let l:viewer = vimtex#view#skim#new()
  let l:viewer._start = function('s:start')
  let l:viewer.compiler_callback = function('s:compiler_callback')
  return l:viewer
endfunction

function! s:start(outfile) dict abort
  call vimtex#jobs#run(s:command(a:outfile, 1, 1))
endfunction

function! s:compiler_callback(outfile) dict abort
  call vimtex#jobs#run(s:command(
        \ a:outfile,
        \ g:vimtex_view_automatic && !has_key(self, 'started_through_callback'),
        \ g:vimtex_view_skim_sync))
  let self.started_through_callback = 1
endfunction

function! s:command(outfile, open, sync) abort
  let l:script = [
        \ 'var app = Application("Skim");',
        \ 'var theFile = Path(' . json_encode(a:outfile) . ');',
        \ 'var docs = app.documents.whose({file: {_equals: theFile}});',
        \ 'try { if (docs.length > 0) app.revert(docs); } catch (e) {}',
        \ ]

  if a:open
    if g:vimtex_view_skim_activate
      " Activate before opening: otherwise a background app can create a new
      " window on Vim's Space instead of a tab in the existing Skim window.
      call add(l:script, 'app.activate();')
      call add(l:script, 'delay(0.3);')
    endif
    call add(l:script, 'app.open(theFile);')
  endif

  if a:sync
    call extend(l:script, [
          \ 'if (docs.length > 0) docs[0].go({',
          \ 'to: app.texLines[' . (line('.') - 1) . '],',
          \ 'from: Path(' . json_encode(expand('%:p')) . ')',
          \ (g:vimtex_view_skim_reading_bar ? ', showingReadingBar: true' : ''),
          \ '});',
          \ ])
  endif

  return 'osascript -l JavaScript -e ' . shellescape(join(l:script))
endfunction
