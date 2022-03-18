" TODO: support command Tmake with optional make command and likewise :Trun " with optional run command!
" XXX TODO: maybe use 'autowriteall' instead of just 'autowrite' ?!?
command Tmake :call s:Tmake()
command Trun :call s:Trun()
command! -nargs=+ TrunCommand :call s:SetTrunCommand(<q-args>)
command! -nargs=+ TmakeCommand :call s:SetTmakeCommand(<q-args>)

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

function s:Trun()
  if !exists('g:Trun_command')
    echom "Please set g:Trun_command. Hint: :TrunCommand"
    return
  endif
  if term_getstatus(g:Trun_command) == "running"
    call term_sendkeys(g:Trun_command, "\<C-C>")
    return
  endif
  let tmakeWin = bufwinnr(g:Trun_command)
  let g:startbuf = bufnr('%')
  let termOptions = { "term_name": g:Trun_command, 'exit_cb': function('s:Trun_exit') }
  if tmakeWin != -1
    " Open in current tmakebuffer if it exists.
    exec tmakeWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  else
    let termOptions = extend(termOptions, { 'term_rows': 10 })
  endif
  let cmd = 'sh -c "' . g:Trun_command . '"'
  let ret = term_start(cmd, termOptions)
  menu WinBar.Run :Trun
  menu WinBar.Cgetbuf :cgetbuffer
  menu WinBar.Close :wincmd c
  let g:Trun_exitcode = '?'
  let &l:statusline = "%<Trun: %f [%{g:Trun_exitcode}] %m%r%=%n %-14.(%l,%c%V%) %P"
  let &l:winfixheight = 1
  let &l:foldcolumn = 0
  call clearmatches()
  exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

function s:Tmake()
  if term_getstatus('tmakebuffer') == "running"
    call term_sendkeys('tmakebuffer', "\<C-C>")
    return
  endif
  cexpr ""
  call setqflist([], 'a', { 'title': 'Tmake: ' . &makeprg})
  let tmakeWin = bufwinnr('tmakebuffer')
  let g:startbuf = bufnr('%')
  if &autowrite
    windo call s:TmakeWriteWin()
  endif
  let termOptions = { "term_name": "tmakebuffer", "callback": function('s:Tmake_processoutput'), "exit_cb": function('s:Tmake_exit') }
  if tmakeWin != -1
    " Open in current tmakebuffer if it exists.
    exec tmakeWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  else
    let termOptions = extend(termOptions, { "term_rows": 5 })
  endif
  if exists('g:Tmake_command')
    let makecmd = g:Tmake_command
  else
    let makecmd = &makeprg
  endif
  let cmd = 'sh -c "' . makecmd . '"'
  topleft let ret = term_start(cmd, termOptions)
  hi link Tmake Todo
  let &l:statusline = "%#Tmake#%<%f  %m%r%=%n %-14.(%l,%c%V%) %P"
  let sl="%#Todo#"
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
    if msg[0] == "\n"
      let msg = msg[1:]
    endif
    let msg = substitute(msg, '\e\[[0-9;]\{-}[mK]', '', 'g')
    caddexpr msg
  endfor
endfunc

function s:Tmake_exit(job, code)
  let tmakeWin = bufwinnr('tmakebuffer')
  exec tmakeWin . "wincmd w"
  if a:code == 0
    hi link Tmake StatusLineTerm
  else
    hi link Tmake ErrorMsg
  endif
  exec bufwinnr(g:startbuf) . "wincmd w"
endfunction

" TODO: parse exitcode and show signal numbers etc
" TODO: try to avoid using g:, rather use a window variable
function s:Trun_exit(job, code)
  let a = job_info(a:job)
  if a['termsig'] != ''
    let g:Trun_exitcode = 'sig' . a['termsig']
  else
    let g:Trun_exitcode = a:code
  endif
  " echom 'sig ' . a['termsig'] . " - val " . a['exitval']
endfunction
