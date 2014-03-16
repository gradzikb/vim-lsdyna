"-------------------------------------BOF---------------------------------------
"
" Vim syntax file
"
" Language:     Ls-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik (bartosz.gradzik@hotmail.com)
" Contribution: Jakub Pajerski
" Last Change:  1st of January 2014
"
"-------------------------------------------------------------------------------

" if syntax is already loaded
if exists("b:current_syntax")
  finish
endif
let b:current_syntax = "lsdyna"

"-------------------------------------------------------------------------------
"    Ls-Dyna comment
"-------------------------------------------------------------------------------

syntax match LsDynaComment '^[$#].*$'

hi def link LsDynaComment Comment

"-------------------------------------------------------------------------------
"    Ls-Dyna keywords
"-------------------------------------------------------------------------------

syntax match LsDynaKeyword '^*[a-zA-Z].*$' contains=LsDynaKeywordOption
syntax match LsDynaKeywordOption '_.*$' contained
syntax match LsDynaTitle '^[a-zA-Z].*$'

hi def link LsDynaKeyword Statement
hi def link LsDynaKeywordOption Type
hi def link LsDynaTitle Identifier

"-------------------------------------------------------------------------------
"    Ls-Dyna data line
"-------------------------------------------------------------------------------

syntax match LsDyna2Col  '\%11c.\{10}'
syntax match LsDyna4Col  '\%31c.\{10}'
syntax match LsDyna6Col  '\%51c.\{10}'
syntax match LsDyna8Col  '\%71c.\{10}'
syntax match LsDyna10Col '\%91c.\{10}'

hi def link LsDyna2Col Error
hi def link LsDyna4Col Error
hi def link LsDyna6Col Error
hi def link LsDyna8Col Error
hi def link LsDyna10Col Error

"-------------------------------------EOF---------------------------------------
