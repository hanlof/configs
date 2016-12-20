set gfn=Bitstream\ Vera\ Sans\ Mono\ 10
colorscheme sienna
set lines=50 columns=165

set spelllang=en

set titlestring=%{getcwd()}\ %{string(map(range(1,tabpagenr('$')),'tabpagewinnr(v:val,\"$\")'))}\ %{v:servername}

"hi ExtraWhitespace guibg=#f0e0ff
"hi TabCharacters guibg=#f8f0ff

"au! BufEnter * call g:SetColorOnBuffer()

hi SpecialKey guifg=#b0b0b0
set listchars=tab:‣\ 
set list
" TODO: modify shift-F12 behaviorto modify listchars, not enable/disable list mode

call matchadd("Error", "\\s\\+$") " whitespace at EOL is bad
call matchadd("Error", " \\+\t")  " space before tab is bad
" TODO: disable/enable EOL-space error while typing (?)


au SwapExists * call g:SwapExists()

function g:SwapExists()
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

function g:SetColorOnBuffer()
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
