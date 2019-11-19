function! s:FetchGerritComments()
  "set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:%m,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %s,%Z%m
  set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:\ %m,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %s,%Z

  "command for fetching gerrit reviews into errorlist
  "
  let gerriturl = systemlist("git remote get-url --push origin")[0]
  let change_id = systemlist("git show --format=%b --quiet | sed -n '/Change-Id/s/Change-Id:\\s\\+'//p")[0]
  let o = matchlist(gerriturl, "ssh://\\([0-9A-Za-z]\\+\\)@\\([0-9A-Za-z\\.]\\+\\):\\(\\d\\+\\)/")
  let gerritcmd = 'ssh ' . o[2] . ' -l ' . o[1] . ' -p ' . o[3] . ' gerrit query --comments --patch-sets ' . change_id
  cexpr system(gerritcmd)
  call setqflist([], 'a', {'title': "Gerrit review comments: https://" . o[2] . "/#/q/" . change_id})
endfunc
command! GerritComments call s:FetchGerritComments()

" post review: https://review.opendev.org/Documentation/cmd-review.html
" post review: https://review.opendev.org/Documentation/rest-api-changes.html#set-review
