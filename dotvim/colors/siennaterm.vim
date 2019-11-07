" Vim colour scheme
" Maintainer:	Georg Dahn
" Last Change:	26 April 2006
" Version:	1.6
"
" This color scheme has both light and dark styles with harmonic colors
" easy to distinguish. Terminals are not supported, therefore you should
" only try it if you use the GUI version of Vim.
"
" You can choose the style by adding one of the following lines to your
" vimrc or gvimrc file before sourcing the color scheme:
"
" let g:siennaterm_style = 'dark'
" let g:siennaterm_style = 'light'
"
" If none of above lines is given, the light style is choosen.
"
" You can switch between these styles by using the :Colo command, like
" :Colo dark or :Colo light (many thanks to Pan Shizhu).

if exists("g:siennaterm_style")
    let s:siennaterm_style = g:siennaterm_style
else
    let s:siennaterm_style = 'light'
endif

execute "command! -nargs=1 Colo let g:siennaterm_style = \"<args>\" | colo siennaterm"

if s:siennaterm_style == 'dark'
    set background=dark
elseif s:siennaterm_style == 'light'
    set background=light
else
    finish
endif

hi clear

if exists("syntax_on")
  syntax reset
endif

let g:colors_name = 'siennaterm'

if s:siennaterm_style == 'dark'

hi Normal gui=none  ctermfg=188  guifg=Grey85 ctermbg=235  guibg=Grey15

hi Cursor cterm=reverse term=reverse

hi LineNr gui=none  ctermfg=248  guifg=Grey65
hi NonText cterm=bold gui=bold  ctermfg=248  guifg=Grey65 ctermbg=236  guibg=Grey20
hi SpecialKey gui=none  ctermfg=111  guifg=SkyBlue2
hi Title cterm=bold gui=bold  ctermfg=188  guifg=Grey85
hi Visual cterm=bold gui=bold  ctermfg=0  guifg=Black ctermbg=216  guibg=LightSalmon1

hi FoldColumn gui=none  ctermfg=0  guifg=Black ctermbg=180  guibg=Wheat3
hi Folded gui=none  ctermfg=15  guifg=White ctermbg=101  guibg=Wheat4
hi StatusLine cterm=bold gui=bold  cterm=none term=none ctermfg=0  guifg=Black ctermbg=188  guibg=Grey85
hi StatusLineNC gui=none  cterm=none term=none ctermfg=15  guifg=White ctermbg=242  guibg=DimGray
hi VertSplit gui=none  ctermfg=15  guifg=White ctermbg=242  guibg=DimGray
hi Wildmenu cterm=bold gui=bold  ctermfg=15  guifg=White ctermbg=0  guibg=Black

hi Pmenu  ctermbg=245  guibg=Grey55 ctermfg=0  guifg=Black gui=none
hi PmenuSbar  ctermbg=241  guibg=Grey40 guifg=fg gui=none
hi PmenuSel  ctermbg=11  guibg=Yellow2 ctermfg=0  guifg=Black gui=none
hi PmenuThumb  ctermbg=252  guibg=Grey80 guifg=bg gui=none

hi IncSearch gui=none  ctermfg=235  guifg=Grey15 ctermbg=188  guibg=Grey85
hi Search gui=none  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow2

hi MoreMsg cterm=bold gui=bold  ctermfg=120  guifg=PaleGreen2
hi Question cterm=bold gui=bold  ctermfg=120  guifg=PaleGreen2
hi WarningMsg cterm=bold gui=bold  ctermfg=9  guifg=Red

hi Comment gui=italic  ctermfg=74  guifg=SkyBlue3
hi Error gui=none  ctermfg=Black  guifg=White ctermbg=9  guibg=Red2
hi Identifier gui=none  ctermfg=209  guifg=LightSalmon2
hi Special gui=none  ctermfg=111  guifg=SkyBlue2
hi PreProc gui=none  ctermfg=74  guifg=SkyBlue3
hi Todo cterm=bold gui=bold  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow2
hi Type cterm=bold gui=bold  ctermfg=111  guifg=SkyBlue2
hi Underlined gui=underline  ctermfg=33  guifg=DodgerBlue

hi Boolean cterm=bold gui=bold  ctermfg=120  guifg=PaleGreen2
hi Constant gui=none  ctermfg=120  guifg=PaleGreen2
hi Number cterm=bold gui=bold  ctermfg=120  guifg=PaleGreen2
hi String gui=none  ctermfg=120  guifg=PaleGreen2

hi Label cterm=bold gui=bold,underline  ctermfg=209  guifg=LightSalmon2
hi Statement cterm=bold gui=bold  ctermfg=209  guifg=LightSalmon2

hi htmlBold cterm=bold gui=bold
hi htmlItalic gui=italic
hi htmlUnderline gui=underline
hi htmlBoldItalic cterm=bold gui=bold,italic
hi htmlBoldUnderline cterm=bold gui=bold,underline
hi htmlBoldUnderlineItalic cterm=bold gui=bold,underline,italic
hi htmlUnderlineItalic gui=underline,italic

elseif s:siennaterm_style == 'light'

hi Normal gui=none  ctermfg=0  guifg=Black ctermbg=15  guibg=White

hi Cursor cterm=reverse term=reverse

hi Search ctermbg=48

hi DiffText ctermbg=251 ctermfg=none
hi DiffChange ctermbg=253 ctermfg=none
hi DiffAdd ctermbg=255 ctermfg=none
hi DiffDelete ctermbg=250 ctermfg=247

hi LineNr gui=none  ctermfg=248  guifg=DarkGray
hi NonText cterm=bold gui=bold  ctermfg=248  guifg=DarkGray ctermbg=7  guibg=Grey95
hi SpecialKey gui=none  ctermfg=189 guifg=RoyalBlue4
hi Title cterm=bold gui=bold  ctermfg=0  guifg=Black
hi Visual cterm=bold gui=bold  ctermfg=0  guifg=Black ctermbg=209  guibg=Sienna1

hi FoldColumn gui=none  ctermfg=0  guifg=Black ctermbg=223  guibg=Wheat2
hi Folded gui=none  ctermfg=0  guifg=Black ctermbg=223  guibg=Wheat1
hi StatusLine cterm=bold gui=bold  term=none cterm=none ctermfg=15  guifg=White ctermbg=0  guibg=Black
hi StatusLineNC gui=none term=none cterm=none ctermfg=15  guifg=White ctermbg=242  guibg=DimGray
hi VertSplit gui=none  ctermfg=15  guifg=White ctermbg=242  guibg=DimGray
hi Wildmenu cterm=bold gui=bold  ctermfg=0  guifg=Black ctermbg=15  guibg=White

hi Pmenu  ctermbg=248  guibg=Grey65 ctermfg=0  guifg=Black gui=none
hi PmenuSbar  ctermbg=8  guibg=Grey50 guifg=fg gui=none
hi PmenuSel  ctermbg=11  guibg=Yellow ctermfg=0  guifg=Black gui=none
hi PmenuThumb  ctermbg=250  guibg=Grey75 guifg=fg gui=none

hi IncSearch gui=none  ctermfg=15  guifg=White ctermbg=0  guibg=Black
hi Search gui=none  ctermbg=158 guifg=Black guibg=Yellow
hi QuickFixLine ctermbg=11 ctermfg=0 term=reverse

hi MoreMsg cterm=bold gui=bold  ctermfg=28  guifg=ForestGreen
hi Question cterm=bold gui=bold  ctermfg=28  guifg=ForestGreen
hi WarningMsg cterm=bold gui=bold  ctermfg=9  guifg=Red

hi Comment gui=italic  ctermfg=62  guifg=RoyalBlue3
hi Error gui=none  ctermfg=Black  guifg=White ctermbg=9  guibg=Red2
hi Identifier gui=none  ctermfg=94  guifg=Sienna4
hi Special gui=none  ctermfg=24  guifg=RoyalBlue4
hi PreProc gui=none  ctermfg=62  guifg=RoyalBlue3
hi Todo cterm=bold gui=bold  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow
hi Type cterm=bold gui=bold  ctermfg=24  guifg=RoyalBlue4
hi Underlined gui=underline  ctermfg=21  guifg=Blue

hi Boolean cterm=bold gui=bold  ctermfg=28  guifg=ForestGreen
hi Constant gui=none  ctermfg=28  guifg=ForestGreen
hi Number cterm=bold gui=bold  ctermfg=28  guifg=ForestGreen
hi String gui=none  ctermfg=28  guifg=ForestGreen

hi Label cterm=bold gui=bold,underline  ctermfg=94  guifg=Sienna4
hi Statement cterm=bold gui=bold  ctermfg=94  guifg=Sienna4

hi htmlBold cterm=bold gui=bold
hi htmlItalic gui=italic
hi htmlUnderline gui=underline
hi htmlBoldItalic cterm=bold gui=bold,italic
hi htmlBoldUnderline cterm=bold gui=bold,underline
hi htmlBoldUnderlineItalic cterm=bold gui=bold,underline,italic
hi htmlUnderlineItalic gui=underline,italic

endif
