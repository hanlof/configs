" TODO: support command Tmake with optional make command and likewise :Trun " with optional run command!
" XXX TODO: maybe use 'autowriteall' instead of just 'autowrite' ?!?
command Tmake :call s:Tmake()
command Trun :call s:Trun()
command! -nargs=+ TrunCommand :call s:SetTrunCommand(<q-args>)
command! -nargs=+ TmakeCommand :call s:SetTmakeCommand(<q-args>)

" features:
" use global setting for what to run
" if term_getstatus(...) is 'running' then send (configurable) kill sequence
"   to that channel
" start in new window if bufwinnr(...) is -1
" set up WinBar menu (clickable buttons)
" displays status line with colored exit status
" misc UI tweaks such as 'foldcolumn' and clearmatches()
" feed output to quickfix window
function s:GenericTermWindow(cmd, feed_to_qf)
  let curtab=tabpagenr()
  let windowids=gettabinfo(curtab)[0]["windows"]
  echo filter(windowids,'gettabwinvar(curtab,v:val,"cmd")=="make"')
endfunction

function! s:SetTrunCommand(cmd)
  let g:Trun_command = a:cmd
endfunction

function! s:SetTmakeCommand(cmd)
  let g:Tmake_command = a:cmd
endfunction

function s:TmakeWriteWin()
  if &modifiable && &modified
    write
  endif
endfunction

function g:Trun_StatusLine() abort
  let focused = g:statusline_winid == win_getid(winnr())
  let color = focused ? "%#StatusLine#" : "%#StatusLineNC#"
  return color . "%<%f %#TrunEC#[%{g:Trun_exitcode}]" . color . " %=%n %-14.(%l,%c%V%) %P"
endfunction

function g:Tmake_StatusLine() abort
  let focused = g:statusline_winid == win_getid(winnr())
  let color = focused ? "%#StatusLine#" : "%#StatusLineNC#"
  return color . "%<%f %#TmakeEC#[%{g:Tmake_exitcode}]" . color . " %=%n %-14.(%l,%c%V%) %P"
endfunction

function s:Trun()
  if !exists('g:Trun_command')
    echom "Please set g:Trun_command. Hint: :TrunCommand"
    return
  endif
  if exists('g:Trun_killseq')
    echom "aoeuaoeu"
    let killseq = g:Trun_killseq
  else
    let killseq = "\<C-C>"
  endif
  if term_getstatus(g:Trun_command) == "running"
    call term_sendkeys(g:Trun_command, killseq)
    return
  endif
  let trunWin = bufwinnr(g:Trun_command)
  let g:startbuf = bufnr('%')
  let termOptions = { "term_name": g:Trun_command, 'exit_cb': function('s:Trun_exit') }
  if trunWin != -1
    exec trunWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  else
    let termOptions = extend(termOptions, { 'term_rows': 10 })
  endif
  let cmd = 'bash -c "' . g:Trun_command . '"'
  let ret = term_start(cmd, termOptions)
  menu WinBar.Run :Trun
  menu WinBar.Cgetbuf :cgetbuffer
  menu WinBar.Close :wincmd c
  let g:Trun_exitcode = '?'
  let &l:statusline = "%!Trun_StatusLine()"
  let &l:winfixheight = 1
  let &l:foldcolumn = 0
  hi link TrunEC Search
  call clearmatches()
  exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

function s:Tmake()
  if exists('g:Tmake_command')
    let makecmd = g:Tmake_command
  else
    let makecmd = &makeprg
  endif
  if term_getstatus(makecmd) == "running"
    call term_sendkeys(makecmd, "\<C-C>")
    return
  endif
  cexpr ""
  call setqflist([], 'a', { 'title': 'Tmake: ' . makecmd})
  let tmakeWin = bufwinnr(makecmd)
  let g:startbuf = bufnr('%')
  if &autowrite
    windo call s:TmakeWriteWin()
  endif
  let termOptions = { "term_name": makecmd, "callback": function('s:Tmake_processoutput'), "exit_cb": function('s:Tmake_exit') }
  if tmakeWin != -1
    exec tmakeWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  else
    let termOptions = extend(termOptions, { "term_rows": 5 })
  endif
  let cmd = 'bash -c "' . makecmd . '"'
  topleft let ret = term_start(cmd, termOptions)
  let g:Tmake_exitcode = '?'
  let &l:statusline = "%!Tmake_StatusLine()"
  hi link TmakeEC Search
  menu WinBar.Build :Tmake
  menu WinBar.Small :4wincmd _
  menu WinBar.Big :15wincmd _
  menu WinBar.Cwin :cwin
  let &l:winfixheight = 1
  exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

function s:Tmake_processoutput(chan, msg)
  let msgs = split(a:msg, "\r")
  for msg in msgs
    " newline tweaks
    if msg[0] == "\n"
      let msg = msg[1:]
    endif
    " strip ansi colors
    let msg = substitute(msg, '\e\[[0-9;]\{-}[mK]', '', 'g')
    caddexpr msg
  endfor
endfunc

function s:Tmake_exit(job, code)
  let a = job_info(a:job)
  if a['termsig'] != ''
    let g:Tmake_exitcode = 'sig' . a['termsig']
  elseif a:code == 0
    let g:Tmake_exitcode = 'success'
  else
    let g:Tmake_exitcode = 'fail: ' . a:code
  endif
  if a:code == 0
    hi link TmakeEC StatusLineTerm
  else
    hi link TmakeEC ErrorMsg
  endif
  "exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

" TODO: parse exitcode and show signal numbers etc
" TODO: try to avoid using g:, rather use a window variable
function s:Trun_exit(job, code)
  let a = job_info(a:job)
  if a['termsig'] != ''
    let g:Trun_exitcode = 'sig' . a['termsig']
  elseif a:code == 0
    let g:Trun_exitcode = 'success'
  else
    let g:Trun_exitcode = a:code
  endif
  if a:code == 0
    hi link TrunEC StatusLineTerm
  else
    hi link TrunEC ErrorMsg
  endif
  " echom 'sig ' . a['termsig'] . " - val " . a['exitval']
endfunction
