" Mouse browsing features (wishlist)
"  tnext / tprev
" gD / gd (goto definition)
menu RightClickMenu.Jump\ back <C-o>
menu RightClickMenu.Jump\ forward <C-i>
menu RightClickMenu.-Sep0- :
menu RightClickMenu.Search\ forward :let @/="\\<" . expand("<cword>") . "\\>":call feedkeys("*")
menu RightClickMenu.Search\ backward :let @/="\\<" . expand("<cword>") . "\\>":call feedkeys("#")
menu RightClickMenu.-Sep1- :
menu RightClickMenu.Go\ to\ def 
menu RightClickMenu.Go\ to\ def\ [new\ win] 
menu RightClickMenu.Go\ to\ filename gf
menu RightClickMenu.Go\ to\ filename\ [new\ win] f
menu RightClickMenu.-Sep2- :
menu RightClickMenu.Git\ grep \G
menu RightClickMenu.Git\ blame :Gblame
menu RightClickMenu.-Sep3- :
menu RightClickMenu.Split\ horizontally s
menu RightClickMenu.Split\ vertically v
menu RightClickMenu.Close\ window c
menu RightClickMenu.-Sep4- :
menu RightClickMenu.Toggle\ search\ highlight :set hls!
menu RightClickMenu.Toggle\ quickfix :ToggleQuickFix
"menu RightClickMenu.subMenu.test :echo test
map <expr> <RightMouse> RightClickFunc()

function! PopUpWithHighLight(line, col, win)
  exec a:win . "wincmd w"
  call setpos(".", [0, a:line, a:col, 0])
  let mat = matchadd("IncSearch", "\\<\\w*\\%#\\w*\\>*")
  redraw
  let winid = win_getid()
  popup RightClickMenu
  if win_id2win(winid) != 0
    call matchdelete(mat, winid)
    redraw
  endif
endfunction

function! RightClickFunc()
  call feedkeys("\<LeftMouse>")
  let c          = getchar()
  let s = ':call feedkeys(":call PopUpWithHighLight(' . v:mouse_lnum . ',' . v:mouse_col . ',' . v:mouse_win . ')\<CR>")'
  return s
endfunction

