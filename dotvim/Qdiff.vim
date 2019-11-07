command Qdiff call g:Qdiff()

function g:Qdiff()
  set errorformat=\%-G+,
  set errorformat+=\%-P---\ a/%f,
  set errorformat+=\%-Gdiff%.%#,
  set errorformat+=\%-Gindex%.%#,
  set errorformat+=\%-G+++%.%#,
  set errorformat+=\%A@@\ %.%#\ +%l%.%#\ %m,
  set errorformat+=\%C\ ,
  set errorformat+=\%C\-%m,
  set errorformat+=\%Z+%.%#,
  set errorformat+=\%-G\ ,
  set errorformat+=\%-G%.%#
  new

  let g:qdiffWin = win_getid()
  cexpr system("git diff -U0")
  Gdiff!
  let g:qdiffWin2 = win_getid()
  "cwin
  call win_gotoid(g:qdiffWin)
  "exec "au BufWinLeave
  "exec "au BufWinEnter
  " BufWinEnter
endfunction
