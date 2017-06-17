set statusline=%<%f\ %h%m%r%=[%n/%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}]\ %-14.(%l,%c%V%)\ %P

"efm for gerrit reviews: set efm=%E\ \ \ \ \ \ file:\ %f,%Z\ \ \ \ \ \ line:\ "%l
set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:%s,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %m,%Z%m
"command for fetching gerrit reviews into errorlist
cexpr system('ssh gerrit.site.se -p 29418 gerrit query --comments --patch-sets commit:`git show --pretty=%H --no-patch --no-notes --no-abbrev`')

"set textwidth=78

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

" colorscheme siennaterm
