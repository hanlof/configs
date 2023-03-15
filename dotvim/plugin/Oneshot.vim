command OneShot call s:Oneshot()

let s:a = expand("<sfile>:h")
function s:Oneshot()
  let name = systemlist("mktemp /tmp/temp-prog-XXXXXX.c")[0]
  exec "tabedit " . name
  set filetype=c
  let t:progname = fnamemodify(name, ":r")
  let &makeprg="make " . t:progname
  exec "TrunCommand " . t:progname
  command Debug :TermdebugCommand t:progname
  menu WinBar.Comp :Tmake
  menu WinBar.Run :Trun
  menu WinBar.Debug :Debug
  "exec "TermdebugCommand " . t:progname
  let $CFLAGS="-g -std=c99"
  exec "0read " . s:a . "/template.c"
  write
  normal ]]j
endfunction
