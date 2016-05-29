"-------------------------------------------------------------------------------
"
" Vim color file
"
" Language:     Ls-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik (bartosz.gradzik@hotmail.com)
" Version:      1.0.0
" Last Change:  22th of May 2016
"
" History of change:
" v1.0.0
"   - initial release
"
"-------------------------------------------------------------------------------

set background=dark
highlight clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "lsdyna"

"-------------------------------------------------------------------------------
"    VIM GROUPS
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" GUI

highlight Normal     guifg=White     guibg=Black    gui=NONE
highlight Search     guifg=Black     guibg=Red      gui=NONE
highlight Visual     guifg=Black     guibg=DarkGray gui=NONE
highlight Folded     guifg=LightGray guibg=Gray40   gui=NONE
highlight Cursor     guifg=bg        guibg=fg       gui=NONE
highlight CursorLine guifg=NONE      guibg=Gray20   gui=NONE
highlight StatusLine guifg=White     guibg=Blue     gui=NONE
highlight Pmenu      guifg=white     guibg=black    gui=NONE
highlight PmenuSel   guifg=black     guibg=white    gui=NONE

"-------------------------------------------------------------------------------
" Terminal

highlight Normal     ctermfg=Gray      ctermbg=Black     cterm=NONE
highlight Search     ctermfg=Black     ctermbg=Red       cterm=NONE
highlight Visual     ctermfg=Black     ctermbg=Gray      cterm=NONE
highlight Folded     ctermfg=Black     ctermbg=Gray      cterm=NONE
highlight Cursor     ctermfg=bg        ctermbg=fg        cterm=NONE
highlight CursorLine ctermfg=NONE      ctermbg=NONE      cterm=Underline
highlight StatusLine ctermfg=Black     ctermbg=White     cterm=NONE
highlight Pmenu      ctermfg=white     ctermbg=black     cterm=NONE
highlight PmenuSel   ctermfg=black     ctermbg=white     cterm=NONE

"-------------------------------------------------------------------------------
"    LS-DYNA HIGHLIGHT COLORS
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" GUI

highlight lsdynaComment       guifg=LightRed guibg=bg    gui=NONE
highlight lsdynaKeywordName   guifg=Yellow   guibg=bg    gui=NONE
highlight lsdynaKeywordOption guifg=Green    guibg=bg    gui=NONE
highlight lsdynaTitle         guifg=Cyan     guibg=bg    gui=NONE
highlight lsdynaColumn        guifg=White    guibg=Brown gui=NONE

"-------------------------------------------------------------------------------
" Terminal

highlight lsdynaComment       ctermfg=Red    ctermbg=bg  cterm=NONE
highlight lsdynaKeywordName   ctermfg=Yellow ctermbg=bg  cterm=NONE
highlight lsdynaKeywordOption ctermfg=Green  ctermbg=bg  cterm=NONE
highlight lsdynaTitle         ctermfg=Cyan   ctermbg=bg  cterm=NONE
highlight lsdynaColumn        ctermfg=Gray   ctermbg=Red cterm=NONE

"-------------------------------------EOF---------------------------------------
