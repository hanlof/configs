set gfn=Bitstream\ Vera\ Sans\ Mono\ 10
colorscheme sienna
set lines=50 columns=165

set spelllang=en

hi cSpaceError guibg=#f0e0ff

"hi ExtraWhitespace guibg=#f0e0ff
"hi TabCharacters guibg=#f8f0ff

fun! HansRightmouse()
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

menu ToolBar.-sep10- <nop>
menu icon=previous ToolBar.tPrev :tprev<CR>
menu icon=next     ToolBar.tNext :tnext<CR>

menu PopUp.git-grep :Ggrep <cword><CR>
menu PopUp.tag :tag <cword><CR>

set mousemodel=extend
map <C-RightMouse> :popup PopUp<CR>
map <RightMouse> :call HansRightmouse()
"map <RightMouse> :popup PopUp<CR>
map <RightRelease> <nop>

map <C-Tab> gt
map <C-S-Tab> gT

map <S-ScrollWheelUp> [[
map <S-ScrollWheelDown> ]]

map <C-ScrollWheelDown> :cnext<CR>
map <C-ScrollWheelUp> :cprev<CR>

map <C-S-ScrollWheelDown> :SmallerFont<CR>
map <C-S-ScrollWheelUp> :LargerFont<CR>

map <M-Right> >
map <M-Left> <

hi DiffAdd        guibg=#e8ffff
hi DiffChange     guibg=#fff0f0
hi DiffDelete     guibg=LightCyan
hi DiffText       guibg=#ffd0d0

hi Search         guibg=#90ff90
