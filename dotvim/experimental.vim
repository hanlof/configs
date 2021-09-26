set statusline=%<%f\ %h%m%r%=[%n/%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}]\ %-14.(%l,%c%V%)\ %P

"efm for gerrit reviews: set efm=%E\ \ \ \ \ \ file:\ %f,%Z\ \ \ \ \ \ line:\ "%l
set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:%s,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %m,%Z%m
" gerriturl = system("git remote get-url --push origin")
"command for fetching gerrit reviews into errorlist
"echo matchlist("ssh://ehanlof@selngerrit.mo.sw.ericcsson.se:29418/pc/gateway/epg", "ssh://\\([0-9A-Za-z@\\.]\\+\\):\\(\\d\\+\\)/")
cexpr system('ssh gerrit.site.se -p 29418 gerrit query --comments --patch-sets commit:`git show --pretty=%H --no-patch --no-notes --no-abbrev`')

" define tab stuff in language specific files like after/ftplugin/c.vim etc
" big steps when tabbing (2 is too small difference from using spaces)
"set softtabstop=4
" i want 2 spaces to be the standard indentation
"set shiftwidth=2
" tabs are 8 characters. make them visible by coloring them in .gvimrc
"set tabstop=8
"set noexpandtab

"this must be set in after/ftplugin/c.vim to be effective
"set formatoptions-=ro

"set textwidth=78


set mousemodel=extend

map <C-RightMouse> :popup PopUp<CR>
map <RightMouse> :call HansRightmouse()
map <RightRelease> <nop>

menu PopUp.git-grep :Ggrep <cword><CR>
menu PopUp.tag :tag <cword><CR>

function! HansRightmouse()
  " check if the status bar was clicked on instead of a file/directory name
  while getchar(0) != 0
   "clear the input stream
  endwhile
  call feedkeys("\<LeftMouse>")
  let c          = getchar()
  let mouse_lnum = v:mouse_lnum
  let wlastline  = line('w$')
  let lastline   = line('$')

  call feedkeys("\<LeftMouse>")

  popup! PopUp
endfun

au SwapExists * call g:SwapExists()
function! g:SwapExists()
  echo "swap exists!"
  let out = ""
  let servers=serverlist()
  let cmd='map(range(1,bufnr("$")),"fnamemodify(bufname(v:val),\":p\")")'
  let f=expand("<afile>:p")
  for ser in split(serverlist(), '\n')
    let out .= ser
    let a=remote_expr(ser, cmd)
    echomsg ser
    echomsg a . " " . f
  endfor
  echomsg out
  let v:swapchoice=''
endfunction

" au! CursorMoved * call MarkIfWide()
function! MarkIfWide()
  if virtcol("$") > &textwidth
    let &l:colorcolumn=&l:textwidth
  else
    let &l:colorcolumn=""
  endif
endfunction

"au! BufEnter * call g:SetColorOnBuffer()
function! g:SetColorOnBuffer()
  let GitTop = g:GitTopLevel(fnamemodify(expand('%'), ':p:s?[\/]$??'))
  if GitTop == ''
    hi Normal guibg=#f8fff8
    return
  endif
  if GitTop == '/repo/hans/slask'
    hi Normal guibg=#ffffff
  else
    hi Normal guibg=#e8e8f8
  endif
endfunction

" function in dict
function! g:Hans()
  echom 'hej :)'
endfunction
let custom = {
  \'kalle' : {
    \'apa' : function('g:Hans'),
    \'bepa' : function('g:Hans')
  \}
\}
let a = custom['kalle']['apa']()

" XXX consider mouse selection. act on selected text?
" - what if click is outside selection??
function! CallMmenu()
  " first move cursor
  while getchar(0) != 0
   "clear the input stream
  endwhile
  call feedkeys("\<LeftMouse>")
  let c = getchar()
  "echo v:mouse_col v:mouse_lnum v:mouse_win
  let winid = win_getid(v:mouse_win)
  "echo win_gotoid(win_getid(v:mouse_win))
  let bufnr = winbufnr(v:mouse_win)
  let line = getbufline(bufnr, v:mouse_lnum)[0]
  " XXX NOPE! we may not so casually use \%Nv (virtual column matching)
  " XXX Must consider clicking in a different buffer with different tabstop
  " setting
  let cword = matchstr(line, '\i*\%' . v:mouse_col .'v\i\+')
  call cursor(v:mouse_lnum, v:mouse_col)

  let mmenuinput = ":!index_repo\<CR>\n"
  let mmenuinput .= ":ToggleQuickFix\n"
  let mmenuinput .= ":set hlsearch!\n"
  let mmenuinput .= ":Gblame\n"
  let mmenuinput .= ":wincmd close\n"
  if cword != ""
    let mmenuinput .= ":\n"
    let mmenuinput .= ":tag " . cword . "\n"
    let mmenuinput .= ":Ggrep " . cword . "\<CR>\n"
    let mmenuinput .= "/" . cword . "\n"
    let mmenuinput .= "/\\<" . cword . "\\>\n"
  endif
  " XXX check for filenames and enable jumping to other files
  let output = system("/home/ocp/configs/submodules/dmenu/mmenu", mmenuinput)
  if v:shell_error != 0
    echom output
    return ""
  endif

  if empty(output)
    return ""
  endif

  " XXX check output for tag or ggrep and set up <S-MouseDown>/<S-MouseUp>
  " mappings accordingly (tprev/tnext or cprev/cnext)
  return output
endfunction

function! CallMmenu2()
  "let line = getbufline(bufnr, v:mouse_lnum)[0]
  " XXX NOPE! we may not so casually use \%Nv (virtual column matching)
  " XXX Must consider clicking in a different buffer with different tabstop
  " setting
  "let cword = matchstr(line, '\i*\%' . v:mouse_col .'v\i\+')
  "echo cword . "|" . line
  "call cursor(v:mouse_lnum, v:mouse_col)

  set mouse=
  let mmenuinput = ":copen\n"
  let mmenuinput .= ":cclose\n"
  let mmenuinput .= ":echo \'kalle'\n"
  "let output = system("/home/ocp/configs/submodules/dmenu/mmenu", mmenuinput)
  let output=""
  if v:shell_error != 0
    echom output
    return ""
  endif

  call feedkeys(":call system('/home/ocp/configs/submodules/dmenu/mmenu', 'apa')\<CR>")
  set mouse=
  if empty(output)
    return ""
  endif
endfunction

" print syntax elements at cursor, as cursor moves
function! g:T(s)
  let s = {'cParen': '(',
        \  'cCppParen': '(',
        \  'cBlock': '{',
        \  'cBracket': '[',
        \  'cString': '""',
        \  'cInclude': '#inc',
        \  'cPreCondit': '#if',
        \}
  if exists("s['" . a:s . "']")
    return s[a:s]
  else
    return "?" . a:s . "?"
  endif
endfunction
au CursorMoved * echo join(map(synstack(line("."), col(".")), "g:T(synIDattr(v:val, 'name'))"), " ")

" set search pattern when grepping
au QuickfixCmdPost *
      \ let d = getqflist({'all': 1}) |
      \ echo d['title'] |
      \ if match(d['title'], 'grep') |
      \   "let @/ =
      \ endif

