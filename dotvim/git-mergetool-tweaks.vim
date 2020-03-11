function! g:IsMergetool()
  if &diff == 0
    return 0
  endif
  if match(argv(0), 'LOCAL') == -1
    return 0
  endif
  if argc() == 3
    if match(argv(1), 'REMOTE') == -1
      return 0
    endif
  elseif argc() == 4
    if match(argv(1), 'BASE') == -1
      return 0
    endif
    if match(argv(2), 'REMOTE') == -1
      return 0
    endif
  else
    return 0
  endif
  return 1
endfunction

function! g:SetupMergetool()
  " assume we are in the "MERGED" window when this function is called
  nnoremap <F9> :diffget LOCAL<CR>
  nnoremap <F10> :diffget BASE<CR>
  nnoremap <F11> :diffget REMOTE<CR>
  setlocal statusline=%<%f\ %h%m%r%=F9=LOCAL\ F10=BASE\ F11=REMOTE\ [%n/%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}]\ %-14.(%l,%c%V%)\ %P
  " Can't figure out a better way to jump to the first merge conflict
  " except feedkeys(). simply calling vimgrep seems to be eaten up before UI
  " is ready for it to take effect
  call feedkeys(":vimgrep /^=======$/ %\<CR>")
endfunction

if g:IsMergetool()
  " postpone setup until windows are layed out correctly
  autocmd VimEnter * call g:SetupMergetool()
endif
