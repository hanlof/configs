function RepoMatches(test_repo)
  let this_repo = g:SystemList("git remote get-url origin")
  if v:shell_error != 0
      return 0
  endif
  let a = join(this_repo, ' ')
  if match(a, a:test_repo) >= 0
    return 1
  endif
  return 0
endfunction

function LocalGitPathMatches(test_path)
  let this_path = expand("%:p")
  let git_top= g:SystemList("git rev-parse --show-toplevel")[0]
  let this_local_path = substitute(this_path, git_top . "/", "", "")

  return (match(this_local_path, a:test_path) >= 0)
endfunction

function FiletypeIs(test_ft)
  return (a:test_ft == &ft)
endfunction

function AbsPathMatches(test_path)
  let this_path = expand("%:p")
  return (match(this_path, a:test_path) >= 0)
endfunction

" XXX TODO: BufEnter will re-run the setup each time Trun has been called
"           we need a CWDMatches() function that sh
au BufReadPost * call s:SetFileOptions()
function s:SetFileOptions()
  " get git repo
  " get absolute path

  " set these in global variables and then source the autoconfig.vim global script
  " set global utility functions g:PathMatches
  if filereadable("~/.ltweaks.vim")
    source ~/.ltweaks.vim
  endif
endfunction


