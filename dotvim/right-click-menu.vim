" Mouse browsing features (wishlist)
"  tnext / tprev
" Toggle :cwin
" Git grep
" Git blame
" gD / gd (goto definition)
menu PopUp.Search\ forward :call feedkeys("*")
menu PopUp.Search\ backward :call feedkeys("#")
menu PopUp.-Sep1- :
menu PopUp.Go\ to\ def 
menu PopUp.Go\ to\ def\ (new\ win) 
menu PopUp.Go\ to\ filename gf
menu PopUp.Go\ to\ filename\ (new\ win) f
menu PopUp.-Sep2- :
menu PopUp.Git\ grep \G
menu PopUp.Git\ blame :Gblame
menu PopUp.-Sep3- :
menu PopUp.Split\ horizontally s
menu PopUp.Split\ vertically v
menu PopUp.Close\ window c
menu PopUp.-Sep4- :
menu PopUp.Toggle\ search\ highlight :set hls!
menu PopUp.Toggle\ quickfix :ToggleQuickFix
"menu PopUp.-Sep5- :
"menu PopUp.Jump\ back <C-o>
"menu PopUp.Jump\ forward <C-o>
"menu PopUp.subMenu.test :echo test
map <expr> <RightMouse> RightClickFunc()

function! PopUpWithHighLight(line, col, win)
  exec a:win . "wincmd w"
  call setpos(".", [0, a:line, a:col, 0])
  let mat = matchadd("SpellBad", "\\<\\w*\\%#\\w*\\>*")
  redraw
  let winid = win_getid()
  popup PopUp
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

