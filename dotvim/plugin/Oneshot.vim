command OneShot call s:Oneshot()

function s:Oneshot()
  let name = systemlist("mktemp /tmp/temp-prog-XXXXXX.c")[0]
  exec "tabedit " . name
  set filetype=c
  let t:progname = fnamemodify(name, ":r")
  let &makeprg="make " . t:progname
  exec "TrunCommand " . t:progname
endfunction
