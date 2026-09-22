" Build project tags asynchronously, with at most one ctags job per project.
let s:jobs = {}
let s:sequence = 0

function! s:warn(message) abort
  echohl WarningMsg
  echomsg '[TeX tags] ' . a:message
  echohl None
endfunction

function! s:ctags() abort
  if exists('s:ctags_bin')
    return s:ctags_bin
  endif
  " Prefer PATH, but also find Homebrew when Vim was started outside a shell.
  for l:bin in [exepath('ctags'), '/opt/homebrew/bin/ctags',
        \ '/usr/local/bin/ctags', exepath('uctags')]
    if executable(l:bin)
          \ && system(shellescape(l:bin) . ' --version') =~# 'Universal Ctags'
      let s:ctags_bin = l:bin
      return l:bin
    endif
  endfor
  if !get(s:, 'warned_missing', 0)
    call s:warn('Universal Ctags is required: brew install universal-ctags')
    let s:warned_missing = 1
  endif
  return ''
endfunction

function! s:root() abort
  let l:root = get(get(b:, 'vimtex', {}), 'root', '')
  if !empty(l:root) && isdirectory(l:root)
    return fnamemodify(l:root, ':p')
  endif
  " Without VimTeX, use the nearest tags/Git root, then the file's directory.
  let l:dir = expand('%:p:h')
  let l:start = l:dir
  while 1
    if filereadable(l:dir . '/tags') || !empty(getftype(l:dir . '/.git'))
      return fnamemodify(l:dir, ':p')
    endif
    let l:parent = fnamemodify(l:dir, ':h')
    if l:parent ==# l:dir
      return fnamemodify(l:start, ':p')
    endif
    let l:dir = l:parent
  endwhile
endfunction

function! s:finish(root, status) abort
  let l:state = remove(s:jobs, a:root)
  " Keep the last usable tags file if ctags fails or is interrupted.
  if a:status != 0 || !filereadable(l:state.output)
    call s:warn('ctags failed for ' . a:root . ' (exit ' . a:status . ')')
  elseif rename(l:state.output, a:root . 'tags') != 0
    call s:warn('Could not replace ' . a:root . 'tags')
  endif
  call delete(l:state.output)
  " A save during generation requires one more pass over the latest files.
  if l:state.pending
    call s:start(a:root, l:state.bin)
  endif
endfunction

function! s:nvim_exit(root, job, status, event) abort
  call s:finish(a:root, a:status)
endfunction

function! s:vim_exit(root, job, status) abort
  call s:finish(a:root, a:status)
endfunction

function! s:start(root, bin) abort
  let s:sequence += 1
  " Use the same directory so replacing tags is atomic.
  let l:output = a:root . '.tags.' . getpid() . '.' . s:sequence
  let s:jobs[a:root] = {'output': l:output, 'pending': 0, 'bin': a:bin}
  let l:command = [a:bin, '-R', '--languages=TeX', '--kinds-TeX=+l',
        \ '--tag-relative=yes', '-f', l:output, '.']
  try
    if has('nvim')
      let l:job = jobstart(l:command, {'cwd': a:root,
            \ 'on_exit': function('s:nvim_exit', [a:root])})
      if l:job <= 0
        call s:finish(a:root, -1)
      endif
    else
      let l:job = job_start(l:command, {'cwd': a:root,
            \ 'out_io': 'null', 'err_io': 'null',
            \ 'exit_cb': function('s:vim_exit', [a:root])})
      if job_status(l:job) ==# 'fail'
        call s:finish(a:root, -1)
      else
        let s:jobs[a:root].job = l:job
      endif
    endif
  catch
    call s:warn(v:exception)
    if has_key(s:jobs, a:root)
      call s:finish(a:root, -1)
    endif
  endtry
endfunction

function! dotfiles#tex_tags#update(force) abort
  if &l:buftype !=# '' || expand('%:e') !=? 'tex'
        \ || !filereadable(expand('%:p'))
    return
  endif
  let l:root = s:root()
  let &l:tags = escape(l:root . 'tags', ' ,;\') . ',' . &g:tags
  if has_key(s:jobs, l:root)
    let s:jobs[l:root].pending = s:jobs[l:root].pending || a:force
    return
  endif
  if !a:force && filereadable(l:root . 'tags')
    return
  endif
  let l:bin = s:ctags()
  if !empty(l:bin)
    call s:start(l:root, l:bin)
  endif
endfunction
