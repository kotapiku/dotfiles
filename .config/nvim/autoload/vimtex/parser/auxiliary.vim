" Loaded after VimTeX's implementation by lua/plugins/tex.lua.
if !exists('s:ManualLabels')
  let s:ManualLabels = funcref('vimtex#parser#auxiliary#labels_manual')
endif

function! s:signature(sources) abort
  return luaeval('require("dotfiles.tex_performance").source_signature(_A.root, _A.sources)',
        \ {'root': b:vimtex.root, 'sources': a:sources})
endfunction

function! vimtex#parser#auxiliary#labels_manual() abort
  if !get(b:, 'dotfiles_tex_fast', 0)
    return s:ManualLabels()
  endif

  " Typing a reference does not change the labels in saved project sources.
  " Include every source's nanosecond mtime so external edits also invalidate.
  let l:sources = b:vimtex.get_sources()
  let l:signature = s:signature(l:sources)
  let l:cache = get(b:, 'dotfiles_tex_label_cache', {})
  if get(l:cache, 'tex', '') ==# b:vimtex.tex
        \ && get(l:cache, 'signature', '') ==# l:signature
    return deepcopy(l:cache.labels)
  endif

  " VimTeX's parser cache compares mtimes in seconds. Refresh its volatile
  " cache too, so multiple saves/external edits within one second are visible.
  call vimtex#cache#clear('parser_tex')
  let l:labels = s:ManualLabels()
  " A saved main file may have introduced another included source.
  let l:sources = b:vimtex.get_sources({'refresh': v:true})
  let b:dotfiles_tex_label_cache = {
        \ 'tex': b:vimtex.tex, 'signature': s:signature(l:sources),
        \ 'labels': deepcopy(l:labels)}
  return l:labels
endfunction
