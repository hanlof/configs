function! g:FetchGerritComments()
  set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:%s,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %m,%Z%m
  set efm=%E\ \ \ \ \ \ file:\ %f,%Z\ \ \ \ \ \ line:\ "%l

  "command for fetching gerrit reviews into errorlist
  "
  let gerriturl = system("git remote get-url --push origin")
  let o = matchlist(gerriturl, "ssh://\\([0-9A-Za-z@\\.]\\+\\):\\(\\d\\+\\)/")
  " XXX fetch Change-Id line from current commit
  cexpr system('ssh ' . o[1] . ' -p ' . o[2] . ' gerrit query --comments --patch-sets commit:`git show --pretty=%H --no-patch --no-notes --no-abbrev`')
  echom 'ssh ' . o[1] . ' -p ' . o[2] . ' gerrit query --comments --patch-sets commit:`git show --pretty=%H --no-patch --no-notes --no-abbrev`'
endfunc

" post review: https://review.opendev.org/Documentation/cmd-review.html
" post review: https://review.opendev.org/Documentation/rest-api-changes.html#set-review
