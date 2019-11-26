command Tmake :call s:Tmake()

function s:TmakeWriteWin()
  if &modifiable && &modified
    write
  endif
endfunction

" XXX TODO: can the callbacks be defined as s: (script local) functions somehow?
" XXX TODO: maybe use 'autowriteall' instead of just 'autowrite' ?!?
function s:Tmake()
  if term_getstatus('tmakebuffer') == "running"
    call term_sendkeys('tmakebuffer', "\<C-C>")
    return
  endif
  cexpr ""
  call setqflist([], 'a', { 'title': 'Tmake: "' . &makeprg . '"'})
  let tmakeWin = bufwinnr('tmakebuffer')
  let g:startbuf = bufnr('%')
  if &autowrite
    windo call s:TmakeWriteWin()
  endif
  let termOptions = { "term_name": "tmakebuffer", "term_rows": 5, "callback": "g:Tmake_processoutput", "exit_cb": "g:Tmake_exit" }
  if tmakeWin != -1
    " Open in current tmakebuffer if it exists.
    exec tmakeWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  endif
  let ret = term_start(&makeprg, termOptions)
  if !exists("w:original_statusline")
    let w:original_statusline = &statusline
  endif
  let sl="%#Todo#"
  let sl.=w:original_statusline
  let &l:statusline = sl
  let &l:winfixheight = 1
  exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

function g:Tmake_processoutput(chan, msg)
  let msgs = split(a:msg, "\r")
  for msg in msgs
    if msg[0] == "\n"
      let msg = msg[1:]
    endif
    let msg = substitute(msg, '\e\[[0-9;]\{-}[mK]', '', 'g')
    caddexpr msg
  endfor
endfunc

function g:Tmake_exit(job, code)
  let tmakeWin = bufwinnr('tmakebuffer')
  exec tmakeWin . "wincmd w"
  let sl = ""
  if a:code == 0
    let sl .= "%#StatusLineTerm#"
  else
    let sl .= "%#ErrorMsg#"
  endif
  let sl .= w:original_statusline
  let &l:statusline = sl
  exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

