set statusline=%<%f\ %h%m%r%=[%n/%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}]\ %-14.(%l,%c%V%)\ %P

"efm for gerrit reviews: set efm=%E\ \ \ \ \ \ file:\ %f,%Z\ \ \ \ \ \ line:\ "%l
set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:%s,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %m,%Z%m
"command for fetching gerrit reviews into errorlist
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

" set xterm cursor color to black.
silent !echo -en '\e]12;black\x7'

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

function! g:IsXRepo(path)
  silent execute '!git --git-dir ' . a:path . '/.git rev-parse -q --verify XXXXXXX^{commit}'
  return v:shell_error
endfunction

" au! CursorMoved * call MarkIfWide()
function! MarkIfWide()
  if virtcol("$") > &textwidth
    let &l:colorcolumn=&l:textwidth
  else
    let &l:colorcolumn=""
  endif
endfunction

function! g:Hans()
  echom 'hej :)'
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

" a dict...
let custom = {
  \'kalle' : {
    \'apa' : function('g:Hans'),
    \'bepa' : function('g:Hans')
  \}
\}
let a = custom['kalle']['apa']()

" colorscheme siennaterm
