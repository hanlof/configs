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

let timer = timer_start(1000, 'UpdateStatusBar',{'repeat':-1})
function! UpdateStatusBar(timer)
  execute 'let &ro = &ro'
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

function g:QuickTerm_status_line() abort
  let focused = g:statusline_winid == win_getid(winnr())
  let color = focused ? "%#StatusLine#" : "%#StatusLineNC#"

  let buf = getwininfo(g:statusline_winid)[0]['bufnr']
  let exit_st = getbufvar(buf, 'exit_status')
  let exit_col = getbufvar(buf, 'exit_col')
  let timedelta = reltime(getbufvar(buf, 'exit_time'), reltime())[0]

  return color . "%< " . bufname(buf) . " %#" . exit_col . "#[" . exit_st . "/" . timedelta . "]" . color . " %=%n %-14.(%l,%c%V%) %P"
endfunction

function s:SetupTermWindow(name)
  let tmp = "menu WinBar.Run :" . a:name . "\<CR>" | exec tmp
  menu WinBar.Small :4wincmd _
  menu WinBar.Big :15wincmd _
  menu WinBar.Cgetbuf :cgetbuffer
  menu WinBar.QFix :cwin
  menu WinBar.Close :wincmd c

  let &l:foldcolumn = 0
  let b:exit_col = a:name
  let tmp = "hi link " . a:name . " Search" | exec tmp
  let b:exit_status = '?'
  let b:exit_time = reltime()
  let &l:statusline = "%!QuickTerm_status_line()"
  call clearmatches()
  let &l:winfixheight = 1
endfunction

function s:SameTermFindWin(command)
  let term_buffers = term_list() " array of buffer numbers that are terminals
  let tabpage_buffers = tabpagebufferlist() "buffers in windows in tab
  let tabpage_windows = gettabinfo() " window ID:s in tab
  let a = getbufinfo(1) " struct that holds a windows key
  let b = getwininfo(1001) " struct that holds win-number, buf-number and tab-number
  let c = job_info() " list with all jobs
endfunction

function s:SameTermLaunch(command)
endfunction


" non-generic things:
" Note: Preparations such as finding starting command and writing buffers are
" left to be done before the term/window related things
"
" - what to execute
" -- buffer name (if different)
" - how to kill (if it should be killed when restarting?)
" -- signal or input key sequence
" - how to process output
" - starting rows (generic term options?)
function s:Trun()
  " first find the window
  " if there is no window then create it and skip to starting job
  "
  " then find if the job is running
  " then perform relevant job stopping actions and return
  " - term_setkill() can be used as well as term_start() option "term_kill"
  " - but this only sets a signal. can not be configured to send input to the job
  "
  " starting the job:
  " * find the correct window
  " save old window and switch to correct window
  " use term_start in current window
  " set up the window options
  " * jump back to old window

  " find options
  if !exists('g:Trun_command')
    echom "Please set g:Trun_command. Hint: :TrunCommand"
    return
  else
    let runcmd = g:Trun_command
  endif
  if exists('g:Trun_killseq')
    let killseq = g:Trun_killseq
  else
    let killseq = "\<C-C>"
  endif

  " XXX can use buffer number
  " XXX use built in term kill command instead?
  if term_getstatus(g:Trun_command) == "running"
    call term_sendkeys(g:Trun_command, killseq)
    return
  endif

  " find the buffer for this instance
  " XXX TODO this will find the current window if the run command
  " matches the name of the file in the current buffer
  let quickterm_instance = "Trun"
  let trunBufs = filter(term_list(), "getbufvar(v:val, 'QuickTerm_instance') == quickterm_instance")
  if len(trunBufs) > 0
    let trunWin = bufwinnr(trunBufs[0])
  else
    let trunWin = -1
  endif

  let original_winid = win_getid()

  " construct command
  let cmd = 'bash -c "' . g:Trun_command . '"'


  let termOptions = { "term_name": g:Trun_command, 'exit_cb': function('s:QuickTerm_job_exit_cb') }
  if trunWin != -1
    exec trunWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  else
    let termOptions = extend(termOptions, { "term_rows": 5 })
  endif

  let ret = term_start(cmd, termOptions)

  let b:QuickTerm_instance = "Trun"

  call s:SetupTermWindow("Trun")

  call win_gotoid(original_winid)
endfunction

function s:Tmake()
  " Tmake specific!
  if !exists('g:Tmake_command')
    let makecmd = &makeprg
  else
    let makecmd = g:Tmake_command
  endif
  if &autowrite
    windo call s:TmakeWriteWin()
  endif
  cexpr ""
  call setqflist([], 'a', { 'title': 'Tmake: ' . makecmd})


  if term_getstatus(makecmd) == "running"
    call term_sendkeys(makecmd, "\<C-C>")
    return
  endif

  " find the buffer for this instance
  " XXX TODO this will find the current window if the run command
  " matches the name of the file in the current buffer
  let tmakeWin = bufwinnr(makecmd)
  " find current window
  let original_winid = win_getid()
  " construct command
  let cmd = 'bash -c "' . makecmd . '"'


  let termOptions = { "term_name": makecmd, "callback": function('s:Tmake_processoutput'), "exit_cb": function('s:QuickTerm_job_exit_cb') }
  if tmakeWin != -1
    exec tmakeWin . "wincmd w"
    let termOptions = extend(termOptions, { 'curwin': 1 })
  else
    let termOptions = extend(termOptions, { "term_rows": 7 })
  endif

  let ret = term_start(cmd, termOptions)

  call s:SetupTermWindow("Tmake")

  call win_gotoid(original_winid)
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

function s:Exit_code_to_string(job, code)
  let a = job_info(a:job)
  if a['termsig'] != ''
    return 'sig' . a['termsig']
  elseif a:code == 0
    return 'success'
  else
    return 'fail: ' . a:code
  endif
endfunction

" TODO: probably move some stuff to the statusline function and just save stuff here
function s:QuickTerm_job_exit_cb(job, code)
  let alljobs = map(term_list(), "{'ji': job_info(term_getjob(v:val)), 'buf': v:val}")
  let ji = job_info(a:job)
  let filteredjobs = filter(alljobs, "v:val['ji']['process'] == " . ji['process'])
  if len(filteredjobs) == 0
    echoerr "Can't find job in QuickTerm_job_exit_cb()"
    return
  else
    let buf = filteredjobs[0]['buf']
  endif

  call setbufvar(buf, 'exit_status', s:Exit_code_to_string(a:job, a:code))
  call setbufvar(buf, 'exit_time', reltime())
  let ec_col = getbufvar(buf, 'exit_col')
  if a:code == 0
    exec "hi link " . ec_col . " StatusLineTerm"
  else
    exec "hi link " . ec_col . " ErrorMsg"
  endif
endfunction
