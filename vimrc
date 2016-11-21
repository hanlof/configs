set nocp

set laststatus=2
set ruler
set statusline=%<%f\ %h%m%r%=%n\ %-14.(%l,%c%V%)\ %P
set statusline=%<%f\ %h%m%r%=[%n/%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}]\ %-14.(%l,%c%V%)\ %P
"set scrolloff=2
set showcmd

"efm for gerrit reviews: set efm=%E\ \ \ \ \ \ file:\ %f,%Z\ \ \ \ \ \ line:\ "%l
"set efm=%E\ %#file:\ %f,%C\ %#line:\ %l,%-C\ %#reviewer:,%C\ %#name:%s,%C\ %#email:\ %s,%C\ %#email:\ %s,%C\ %#username:\ %m,%Z%m
"command for fetching gerrit reviews into errorlist
"cexpr system('ssh gerrit.site.se -p 29418 gerrit query --comments --patch-sets commit:`git show --pretty=%H --no-patch --no-notes --no-abbrev`')

" never use tabs. insert spaces
"set noexpandtab
" big steps when tabbing (2 is too small difference from using spaces)
"set softtabstop=4
" i want 2 spaces to be the standard indentation
"set shiftwidth=2
" tabs are 8 characters. make them visible by coloring them in .gvimrc

" define tab stuff in language specific files like after/ftplugin/c.vim etc
set tabstop=8
set backspace=2

set splitright

set foldmethod=syntax
set foldcolumn=2
set foldlevel=10


"set textwidth=78

set ignorecase
set smartcase

filetype on
filetype plugin on
filetype indent on

" vims defaults are mostly sane but for switch cases we must let it know whats correct
set cinoptions=l1

" syntax plugin options!
let g:is_bash = 1
let g:load_doxygen_syntax = 1

let c_space_errors = 1
let c_no_tab_space_error = 1

syn on

"this must be set in after/ftplugin/c.vim to be effective
"set formatoptions-=ro

set sessionoptions+=resize,localoptions

set autowrite

set wildmenu

runtime ftplugin/man.vim

nnoremap <F12> :set hls!
inoremap <F12> :set hls!
nnoremap <S-F12> :set list!
inoremap <S-F12> :set list!
nnoremap <C-F12> :set spell!
inoremap <C-F12> :set spell!
nnoremap <F11> :setlocal number!
nnoremap <S-F11> :setlocal relativenumber!
nnoremap <C-F11> :setlocal wrap!

nnoremap <C-S-F11> :setlocal buftype=nofile

nnoremap <F9> :make!
inoremap <F9> :make!
nnoremap <F7> :cprev
inoremap <F7> :cprev
nnoremap <F8> :cnext
inoremap <F8> :cnext

map <F2>g :cs find g <cword>
map <F2>s :cs find s <cword>
map <F2>c :cs find c <cword>
map <F2>t :cs find t <cword>
map <F2>d :cs find d <cword>

map <Leader>G :tab split +:Ggrep\ <cword><CR>
map <Leader>g :tab split +:Ggrep\\\ 

map <F3> :call DmenuOpen("edit")<CR>
map <S-F3> :call DmenuOpen("tabe")<CR>
map <F4> :call DmenuTag("tag")<CR>
map <F3> :call DmenuOpen("sp")<CR>
map g<F3> :call DmenuOpen("tabe")<CR>

map <F6> :let kalle="vert stag ".expand('<cword>')<CR>:exec kalle<CR>
map <S-F6> :let kalle="tab stag ".expand('<cword>')<CR>:exec kalle<CR>

cmap <F8> =g:GitTop

nnoremap <S-F7> :set foldlevel-=1
nnoremap <S-F8> :set foldlevel+=1
nnoremap <C-S-F7> :set foldlevel=0
nnoremap <C-S-F8> :set foldlevel=99

vnoremap <F5>          <Esc>/<C-R>=GetSel()<CR><CR>

function! g:IncludeExprExample(in)
  let top = g:GitTopLevel(fnamemodify('.', ':p:s?[\/]$??'))
  let t2=substitute(a:in,'^b/',top,'g')
  let t=substitute(t2,'^a/',top,'g')
"  let t2=substitute(t,'^/',top . '/','g')
  return t2
endfunction

set includeexpr=g:IncludeExprExample(v:fname)

".../ctags-5.8/readtags -t .git/tags -l |
" Find a tag and pass it to cmd
function! DmenuTag(cmd)
  let top = g:GitTopLevel(fnamemodify('.', ':p:s?[\/]$??'))
  let fname = system("~/bin/readtags2 -t " . top . "/.git/tags -l | ~/dmenu/dmenu-4.5/dmenu -sb purple -i -l 50 -p " . a:cmd)

"  Xlib:  extension "XINERAMA" missing on display ":1011.0"
  let fname2 = substitute(fname, '\n$', '', '')
  " first substitute in the case of two "lines" (<CR> or NULL character present at the end)
  let fname = substitute(fname2, "Xlib:  extension \"XINERAMA\" missing.*\".*.\"\..", '', '')
  " the first pattern will not cover the case of one line, hence another substitute
  let fname = substitute(fname, "Xlib:  extension \"XINERAMA\" missing.*\".*.\"\.", '', '')

  if empty(fname)
    return
  endif

  execute a:cmd . " " . split(fname, " ")[0]
endfunction

" Find a file and pass it to cmd
function! DmenuOpen(cmd)
  let top = g:GitTopLevel(fnamemodify('.', ':p:s?[\/]$??'))
  let fname = system("git ls-files --full-name " . top . " | ~/dmenu/dmenu-4.5/dmenu -i -l 50 -p " . a:cmd)

"  Xlib:  extension "XINERAMA" missing on display ":1011.0"
  let fname2 = substitute(fname, '\n$', '', '')
  " first substitute in the case of two "lines" (<CR> or NULL character present at the end)
  let fname = substitute(fname2, "Xlib:  extension \"XINERAMA\" missing.*\".*.\"\..", '', '')
  " the first pattern will not cover the case of one line, hence another substitute
  let fname = substitute(fname, "Xlib:  extension \"XINERAMA\" missing.*\".*.\"\.", '', '')

  if empty(fname)
    return
  endif
  execute a:cmd . " " . top . "/" . fname
endfunction

function! MarkIfWide()
  if virtcol("$") > &textwidth
    let &l:colorcolumn=&l:textwidth
  else
    let &l:colorcolumn=""
  endif
endfunction

function! GetSel()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]

  if lnum1 != lnum2
    echo 'Multi line'
    return ""
  endif

  let sel = getline(lnum1)[ col1 - 1: col2 - 1]
  return sel
endfunction

" get git top-level dir
function! g:GitTopLevel(path) abort
  let fn = fnamemodify(a:path,':s?[\/]$??')
  let ofn = ""
  let nfn = fn
  while fn != ofn
    if filereadable(fn . '/.git/HEAD')
      return fn
    endif
    let ofn = fn
    let fn = fnamemodify(ofn,':h')
  endwhile
  return ''
endfunction

function! g:IsXRepo(path)
  silent execute '!git --git-dir ' . a:path . '/.git rev-parse -q --verify XXXXXXX^{commit}'
  return v:shell_error
endfunction


let list = []
let list += [{'hej': 'nisse'}]
let list += [{'hej2': 'kalle'}]

let g:GitTop = g:GitTopLevel(fnamemodify('.', ':p:s?[\/]$??'))

if g:GitTop != ''
  exec 'set path+=' . g:GitTop
endif

"au! BufEnter * call g:SetColorOnBuffer()

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

" au! CursorMoved * call MarkIfWide()

cscope add /repo/hans/slask/.git/cscope.out /repo/hans/slask

set cscopequickfix=s-,c-,d-,i-,t-,e-


if &diff
  "might wanna check if the buffers LOCAL, BASE and REMOTE exists... ?
  nnoremap <F7> ?<<<<<<<<CR>
  nnoremap <F8> /<<<<<<<<CR>
  nnoremap <F9> :diffget LOCAL<CR>
  nnoremap <F10> :diffget BASE<CR>
  nnoremap <F11> :diffget REMOTE<CR>
  setlocal statusline=%<%f\ %h%m%r%=F9=LOCAL\ F10=BASE\ F11=REMOTE\ [%n/%{len(filter(range(1,bufnr('$')),'buflisted(v:val)'))}]\ %-14.(%l,%c%V%)\ %P
endif

" colorscheme siennaterm
