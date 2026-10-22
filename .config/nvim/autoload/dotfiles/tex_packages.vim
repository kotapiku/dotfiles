" Optimize VimTeX's package parser while retaining its regex and option rules.
let s:cache = {}
let s:cache_order = []
let s:package_pattern = '\v\\%(usep|RequireP)ackage\s*%(\[([^[\]]*)\])?\s*\{\s*\zs%([^{}]+\S)\ze\s*\}'

function! s:script_id(file) abort
  for l:script in getscriptinfo()
    if resolve(l:script.name) ==# resolve(a:file)
      return l:script.sid
    endif
  endfor
  return -1
endfunction

function! dotfiles#tex_packages#install(vimtex_dir) abort
  let l:file = a:vimtex_dir . '/autoload/vimtex/state/class.vim'
  let l:sid = s:script_id(l:file)
  if l:sid < 0
    execute 'source ' . fnameescape(l:file)
    let l:sid = s:script_id(l:file)
  endif
  let l:parser = '<SNR>' . l:sid . '_parse_packages'
  let l:options = '<SNR>' . l:sid . '_parse_optionlist'
  if !exists('*' . l:parser) || !exists('*' . l:options)
    return 0
  endif
  let l:definition = execute('function ' . l:parser)
  if stridx(l:definition, 'dotfiles#tex_packages#parse') >= 0
    return 1
  endif
  " This narrow hook targets VimTeX v2.18. Keep upstream behavior if it changes.
  if stridx(l:definition, 'matchstrlist') < 0
        \ || stridx(l:definition, "'" . s:package_pattern . "'") < 0
        \ || stridx(l:definition,
        \   'g:vimtex#re#not_comment .. g:vimtex#re#not_bslash') < 0
        \ || stridx(l:definition, 'parse_optionlist') < 0
    return 0
  endif
  let s:ParseOptions = funcref(l:options)
  execute join([
        \ 'function! ' . l:parser . '(preamble_joined) abort',
        \ '  return dotfiles#tex_packages#parse(a:preamble_joined)',
        \ 'endfunction'], "\n")
  return 1
endfunction

function! dotfiles#tex_packages#parse(preamble) abort
  let l:pattern = g:vimtex#re#not_comment . g:vimtex#re#not_bslash
        \ . s:package_pattern
  let l:key = l:pattern . "\n" . a:preamble
  if has_key(s:cache, l:key)
    " Each project may add packages read from its own .fls file.
    return deepcopy(s:cache[l:key])
  endif

  " Reject ordinary text before attempting the expensive look-behind guards.
  " The look-ahead is zero-width and adds no captures to the original pattern.
  let l:prefilter = '\v%(\\%(usep|RequireP)ackage)@='
  let l:packages = {}
  for l:match in matchstrlist([a:preamble], l:prefilter . l:pattern,
        \ {'submatches': v:true})
    let l:options = s:ParseOptions(l:match.submatches[0])
    for l:package in map(split(l:match.text, ','), {_, name -> trim(name)})
      let l:packages[l:package] = l:options
    endfor
  endfor
  " Bound memory when opening many unrelated documents in one editor session.
  if len(s:cache_order) >= 32
    call remove(s:cache, remove(s:cache_order, 0))
  endif
  let s:cache[l:key] = deepcopy(l:packages)
  call add(s:cache_order, l:key)
  return l:packages
endfunction
