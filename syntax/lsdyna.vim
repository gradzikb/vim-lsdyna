"-------------------------------------BOF---------------------------------------
"
" Vim syntax file
"
" Language:     Ls-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik (bartosz.gradzik@hotmail.com)
" Contribution: Jakub Pajerski
" Last Change:  2nd of August 2014
"
" History of change:
" v1.1.0
"   - syntax highlight depends on keyword type now
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

" check if syntax is already loaded
if exists("b:current_syntax") | finish | endif
" set flag when ls-dyna syntax is loaded
let b:current_syntax = "lsdyna"

"-------------------------------------------------------------------------------
"    Keyword lines
"-------------------------------------------------------------------------------

syntax match LsDynaComment '^[$#].*$'
syntax match LsDynaTitle '^[a-zA-Z?.].*$' contained

syntax match LsDynaKeyword '^*[a-zA-Z].*$' contains=LsDynaKeywordOption
syntax match LsDynaKeywordOption '_.*$' contained

"-------------------------------------------------------------------------------
"    Standard Ls-Dyna keyword
"-------------------------------------------------------------------------------

syntax match LsDynaStdKeyword_11_20_Col '\%11c.\{10}' contained
syntax match LsDynaStdKeyword_31_40_Col '\%31c.\{10}' contained
syntax match LsDynaStdKeyword_51_60_Col '\%51c.\{10}' contained
syntax match LsDynaStdKeyword_71_80_Col '\%71c.\{10}' contained

syntax cluster LsDynaStdKeywordCluster add=LsDynaComment
syntax cluster LsDynaStdKeywordCluster add=LsDynaKeyword
syntax cluster LsDynaStdKeywordCluster add=LsDynaTitle
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_11_20_Col
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_31_40_Col
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_51_60_Col
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_71_80_Col

syntax region LsDynaStdKeyword start=/^\*[a-zA-z]/ end=/^\*/me=s-1
 \ contains=@LsDynaStdKeywordCluster

"-------------------------------------------------------------------------------
"    *NODE
"-------------------------------------------------------------------------------

syntax match LsDynaNode_09_24_Col '\%9c.\{16}' contained
syntax match LsDynaNode_41_56_Col '\%41c.\{16}' contained
syntax match LsDynaNode_65_80_Col '\%65c.\{8}' contained

syntax cluster LsDynaNodeCluster add=LsDynaComment
syntax cluster LsDynaNodeCluster add=LsDynaKeyword
syntax cluster LsDynaNodeCluster add=LsDynaNode_09_24_Col
syntax cluster LsDynaNodeCluster add=LsDynaNode_41_56_Col
syntax cluster LsDynaNodeCluster add=LsDynaNode_65_80_Col

syntax region LsDynaNode start=/\c^\*NODE *$/ end=/^\*/me=s-1
 \ contains=@LsDynaNodeCluster

syntax sync match LsDynaNodeSync grouphere LsDynaNode '\c^\*NODE *$'

"-------------------------------------------------------------------------------
"    *ELEMENT_
"-------------------------------------------------------------------------------

syntax match LsDynaElShell_09_16_Col '\%9c.\{8}' contained
syntax match LsDynaElShell_25_32_Col '\%25c.\{8}' contained
syntax match LsDynaElShell_41_48_Col '\%41c.\{8}' contained
syntax match LsDynaElShell_57_64_Col '\%57c.\{8}' contained
syntax match LsDynaElShell_73_80_Col '\%73c.\{8}' contained

syntax cluster LsDynaElShellCluster add=LsDynaComment
syntax cluster LsDynaElShellCluster add=LsDynaKeyword
syntax cluster LsDynaElShellCluster add=LsDynaElShell_09_16_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_25_32_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_41_48_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_57_64_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_73_80_Col

syntax region LsDynaElShell start=/\c^\*ELEMENT_[a-zA-Z]\+ *$/ end=/^\*/me=s-1
 \ contains=@LsDynaElShellCluster

syntax sync match LsDynaElShellSync grouphere LsDynaElShell '\c^\*ELEMENT_[a-zA-Z]\+ *$'

"-------------------------------------------------------------------------------
"    *ELEMENT_MASS
"-------------------------------------------------------------------------------

syntax match LsDynaElMass_09_16_Col '\%9c.\{8}' contained
syntax match LsDynaElMass_33_40_Col '\%33c.\{8}' contained

syntax cluster LsDynaElMassCluster add=LsDynaComment
syntax cluster LsDynaElMassCluster add=LsDynaKeyword
syntax cluster LsDynaElMassCluster add=LsDynaElMass_09_16_Col
syntax cluster LsDynaElMassCluster add=LsDynaElMass_33_40_Col

syntax region LsDynaElMass start=/\c^\*ELEMENT_MASS *$/ end=/^\*/me=s-1
 \ contains=@LsDynaElMassCluster

syntax sync match LsDynaElMassSync grouphere LsDynaElMass '\c^\*ELEMENT_MASS *$'

"-------------------------------------------------------------------------------
"    *ELEMENT_MASS_PART
"-------------------------------------------------------------------------------

syntax match LsDynaElMassPart_09_24_Col '\%9c.\{16}' contained
syntax match LsDynaElMassPart_41_56_Col '\%41c.\{16}' contained

syntax cluster LsDynaElMassPartCluster add=LsDynaComment
syntax cluster LsDynaElMassPartCluster add=LsDynaKeyword
syntax cluster LsDynaElMassPartCluster add=LsDynaElMassPart_09_24_Col
syntax cluster LsDynaElMassPartCluster add=LsDynaElMassPart_41_56_Col

syntax region LsDynaElMassPart start=/\c^\*ELEMENT_MASS_PART.*$/ end=/^\*/me=s-1
 \ contains=@LsDynaElMassPartCluster

syntax sync match LsDynaElMassPartSync grouphere LsDynaElMass '\c^\*ELEMENT_MASS_PART.*$'

"-------------------------------------------------------------------------------
"    HIGHLIGHTS
"-------------------------------------------------------------------------------

hi def link LsDynaComment Comment
hi def link LsDynaKeyword Statement
hi def link LsDynaKeywordOption Type
hi def link LsDynaTitle Identifier
hi def link LsDynaNode_09_24_Col Error
hi def link LsDynaNode_41_56_Col Error
hi def link LsDynaNode_65_80_Col Error
hi def link LsDynaElShell_09_16_Col Error
hi def link LsDynaElShell_25_32_Col Error
hi def link LsDynaElShell_41_48_Col Error
hi def link LsDynaElShell_57_64_Col Error
hi def link LsDynaElShell_73_80_Col Error
hi def link LsDynaStdKeyword_11_20_Col Error
hi def link LsDynaStdKeyword_31_40_Col Error
hi def link LsDynaStdKeyword_51_60_Col Error
hi def link LsDynaStdKeyword_71_80_Col Error
hi def link LsDynaElMass_09_16_Col Error
hi def link LsDynaElMass_33_40_Col Error
hi def link LsDynaElMassPart_09_24_Col Error
hi def link LsDynaElMassPart_41_56_Col Error

"-------------------------------------EOF---------------------------------------
