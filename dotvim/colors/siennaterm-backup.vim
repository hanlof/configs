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
" let g:sienna_style = 'dark'
" let g:sienna_style = 'light'
"
" If none of above lines is given, the light style is choosen.
"
" You can switch between these styles by using the :Colo command, like
" :Colo dark or :Colo light (many thanks to Pan Shizhu).

if exists("g:sienna_style")
    let s:sienna_style = g:sienna_style
else
    let s:sienna_style = 'light'
endif

execute "command! -nargs=1 Colo let g:sienna_style = \"<args>\" | colo sienna"

if s:sienna_style == 'dark'
    set background=dark
elseif s:sienna_style == 'light'
    set background=light
else
    finish
endif

hi clear
 
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = 'sienna'

if s:sienna_style == 'dark'
hi Normal gui=none  ctermfg=188  guifg=Grey85 ctermbg=235  guibg=Grey15


hi Cursor  ctermfg=0  guifg=Black ctermbg=188  guibg=Grey85

hi LineNr gui=none  ctermfg=248  guifg=Grey65

hi NonText gui=bold  ctermfg=248  guifg=Grey65 ctermbg=236  guibg=Grey20

hi SpecialKey gui=none  ctermfg=111  guifg=SkyBlue2

hi Title gui=bold  ctermfg=188  guifg=Grey85

hi Visual gui=bold  ctermfg=0  guifg=Black ctermbg=216  guibg=LightSalmon1


hi FoldColumn gui=none  ctermfg=0  guifg=Black ctermbg=180  guibg=Wheat3

hi Folded gui=none  ctermfg=15  guifg=White ctermbg=101  guibg=Wheat4

hi StatusLine gui=bold  cterm=none term=none ctermfg=0  guifg=Black ctermbg=188  guibg=Grey85

hi StatusLineNC gui=none  cterm=none term=none ctermfg=15  guifg=White ctermbg=242  guibg=DimGray

hi VertSplit gui=none  ctermfg=15  guifg=White ctermbg=242  guibg=DimGray

hi Wildmenu gui=bold  ctermfg=15  guifg=White ctermbg=0  guibg=Black


hi Pmenu  ctermbg=245  guibg=Grey55 ctermfg=0  guifg=Blackgui=none
 
hi PmenuSbar  ctermbg=241  guibg=Grey40 guifg=fg gui=none
 
hi PmenuSel  ctermbg=11  guibg=Yellow2 ctermfg=0  guifg=Blackgui=none
 
hi PmenuThumb  ctermbg=252  guibg=Grey80 guifg=bg gui=none    
 

hi IncSearch gui=none  ctermfg=235  guifg=Grey15 ctermbg=188  guibg=Grey85

hi Search gui=none  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow2


hi MoreMsg gui=bold  ctermfg=120  guifg=PaleGreen2

hi Question gui=bold  ctermfg=120  guifg=PaleGreen2

hi WarningMsg gui=bold  ctermfg=9  guifg=Red


hi Comment gui=italic  ctermfg=74  guifg=SkyBlue3

hi Error gui=none  ctermfg=15  guifg=White ctermbg=9  guibg=Red2

hi Identifier gui=none  ctermfg=209  guifg=LightSalmon2

hi Special gui=none  ctermfg=111  guifg=SkyBlue2

hi PreProc gui=none  ctermfg=74  guifg=SkyBlue3

hi Todo gui=bold  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow2

hi Type gui=bold  ctermfg=111  guifg=SkyBlue2

hi Underlined gui=underline  ctermfg=33  guifg=DodgerBlue


hi Boolean gui=bold  ctermfg=120  guifg=PaleGreen2

hi Constant gui=none  ctermfg=120  guifg=PaleGreen2

hi Number gui=bold  ctermfg=120  guifg=PaleGreen2

hi String gui=none  ctermfg=120  guifg=PaleGreen2


hi Label gui=bold,underline  ctermfg=209  guifg=LightSalmon2

hi Statement gui=bold  ctermfg=209  guifg=LightSalmon2


hi htmlBold gui=bold
 
hi htmlItalic gui=italic
 
hi htmlUnderline gui=underline
 
hi htmlBoldItalic gui=bold,italic
 
hi htmlBoldUnderline gui=bold,underline
 
hi htmlBoldUnderlineItalic gui=bold,underline,italic
 
hi htmlUnderlineItalic gui=underline,italic
 
elseif s:sienna_style == 'light'
hi Normal gui=none  ctermfg=0  guifg=Black ctermbg=15  guibg=White


hi Cursor  ctermfg=15  guifg=White ctermbg=0  guibg=Black

hi LineNr gui=none  ctermfg=248  guifg=DarkGray

hi NonText gui=bold  ctermfg=248  guifg=DarkGray ctermbg=7  guibg=Grey95

hi SpecialKey gui=none  ctermfg=24  guifg=RoyalBlue4

hi Title gui=bold  ctermfg=0  guifg=Black

hi Visual gui=bold  ctermfg=0  guifg=Black ctermbg=209  guibg=Sienna1


hi FoldColumn gui=none  ctermfg=0  guifg=Black ctermbg=223  guibg=Wheat2

hi Folded gui=none  ctermfg=0  guifg=Black ctermbg=223  guibg=Wheat1

hi StatusLine gui=bold  term=none cterm=none ctermfg=15  guifg=White ctermbg=0  guibg=Black

hi StatusLineNC gui=none term=none cterm=none ctermfg=15  guifg=White ctermbg=242  guibg=DimGray

hi VertSplit gui=none  ctermfg=15  guifg=White ctermbg=242  guibg=DimGray

hi Wildmenu gui=bold  ctermfg=0  guifg=Black ctermbg=15  guibg=White


hi Pmenu  ctermbg=248  guibg=Grey65 ctermfg=0  guifg=Blackgui=none
 
hi PmenuSbar  ctermbg=8  guibg=Grey50 guifg=fg gui=none
 
hi PmenuSel  ctermbg=11  guibg=Yellow ctermfg=0  guifg=Blackgui=none
 
hi PmenuThumb  ctermbg=250  guibg=Grey75 guifg=fg gui=none
 

hi IncSearch gui=none  ctermfg=15  guifg=White ctermbg=0  guibg=Black

hi Search gui=none  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow


hi MoreMsg gui=bold  ctermfg=28  guifg=ForestGreen

hi Question gui=bold  ctermfg=28  guifg=ForestGreen

hi WarningMsg gui=bold  ctermfg=9  guifg=Red


hi Comment gui=italic  ctermfg=62  guifg=RoyalBlue3

hi Error gui=none  ctermfg=15  guifg=White ctermbg=9  guibg=Red

hi Identifier gui=none  ctermfg=94  guifg=Sienna4

hi Special gui=none  ctermfg=24  guifg=RoyalBlue4

hi PreProc gui=none  ctermfg=62  guifg=RoyalBlue3

hi Todo gui=bold  ctermfg=0  guifg=Black ctermbg=11  guibg=Yellow

hi Type gui=bold  ctermfg=24  guifg=RoyalBlue4

hi Underlined gui=underline  ctermfg=21  guifg=Blue


hi Boolean gui=bold  ctermfg=28  guifg=ForestGreen

hi Constant gui=none  ctermfg=28  guifg=ForestGreen

hi Number gui=bold  ctermfg=28  guifg=ForestGreen

hi String gui=none  ctermfg=28  guifg=ForestGreen


hi Label gui=bold,underline  ctermfg=94  guifg=Sienna4

hi Statement gui=bold  ctermfg=94  guifg=Sienna4


hi htmlBold gui=bold
 
hi htmlItalic gui=italic
 
hi htmlUnderline gui=underline
 
hi htmlBoldItalic gui=bold,italic
 
hi htmlBoldUnderline gui=bold,underline
 
hi htmlBoldUnderlineItalic gui=bold,underline,italic
 
hi htmlUnderlineItalic gui=underline,italic
 
endif
