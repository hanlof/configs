" this is needed to get rid of vim inserting a star on each line of a c style
" multiline /* comment block */

" setlocal comments=sO:*\ -,mO:\ \ ,exO:*/,s1:/*,mb:\ ,ex:*/,://

set errorformat=%*[^\"]\"%f\"%*\\D%l:\ %m
set errorformat+=\"%f\"%*\\D%l:\ %m
set errorformat+=%-G%f:%l:\ (Each\ undeclared\ identifier\ is\ reported\ only\ once
set errorformat+=%-G%f:%l:\ for\ each\ function\ it\ appears\ in.)
set errorformat+=%-GIn\ file\ included\ from\ %f:%l:%c
set errorformat+=%-GIn\ file\ included\ from\ %f:%l
set errorformat+=%-Gfrom\ %f:%l:%c
set errorformat+=%-Gfrom\ %f:%l
set errorformat+=%f:%l:%c:%m
set errorformat+=%f(%l):%m
set errorformat+=%f:%l:%m
set errorformat+=%f\"\,line\ %l%*\\D%c%*[^\ ]\ %m
set errorformat+=%D%*\\a[%*\\d]:\ Entering\ directory\ `%f'
set errorformat+=%X%*\\a[%*\\d]:\ Leaving\ directory\ `%f'
set errorformat+=%D%*\\a:\ Entering\ directory\ `%f'
set errorformat+=%X%*\\a:\ Leaving\ directory\ `%f'
set errorformat+=%DMaking\ %*\\a\ in\ %f
set errorformat+=%f\|%l\|\ %m

let s:gitTop = g:GitTopLevel(expand('<afile>:p'))

if '' != s:gitTop
  if 0 == g:IsXRepo(s:gitTop)
    exec 'setlocal tags+=' . s:gitTop . 'slask/TAGS'
    if 0 == stridx(expand('<afile>:p'), s:gitTop . '/slask/example/')
      exec 'setlocal makeprg=cd\ ' . s:gitTop . '/slask/example/build/\;make\ debug=full'
      setlocal errorformat=%-GBuilding%m,%-AFirst\ seen\ in\ target%m,%-Z\ \ \ \ %m,%-GBuildsupportTimeStamp%m,%*[^\"]\"%f\"%*\\D%l:\ %m,\"%f\"%*\\D%l:\ %m,%-G%f:%l:\ (Each\ undeclared\ identifier\ is\ reported\ only\ once,%-G%f:%l:\ for\ each\ function\ it\ appears\ in.),%-GIn\ file\ included\ from\ %f:%l:%c,%-GIn\ file\ included\ from\ %f:%l,%-Gfrom\ %f:%l:%c,%-Gfrom\ %f:%l,%f:%l:%c:%m,%f(%l):%m,%f:%l:%m,\"%f\",\ line\ %l%*\\D%c%*[^\ ]\ %m,%D%*\\a[%*\\d]:\ Entering\ directory\ `%f',%X%*\\a[%*\\d]:\ Leaving\ directory\ `%f',%D%*\\a:\ Entering\ directory\ `%f',%X%*\\a:\ Leaving\ directory\ `%f',%DMaking\ %*\\a\ in\ %f,%f\|%l\|\ %m
    elseif 0 == stridx(expand("<afile>:p"), s:gitTop . "kalle/example")
      exec 'setlocal makeprg=cd\ ' . s:gitTop . '/kalle/example/build\;make debug=full'
    endif
  endif
endif


