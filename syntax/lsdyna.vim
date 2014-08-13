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
"    Items shared among keywords
"-------------------------------------------------------------------------------

syntax match LsDynaComment '^[$#].*$'
syntax match LsDynaTitle '^[a-zA-Z?.].*$' contained
syntax match LsDynaKeyword '^*[a-zA-Z].*$' contains=LsDynaKeywordOption
syntax match LsDynaKeywordOption '_.*$' contained

highlight default link LsDynaComment Comment
highlight default link LsDynaKeyword Statement
highlight default link LsDynaKeywordOption Type
highlight default link LsDynaTitle Identifier

"-------------------------------------------------------------------------------
"    Standard Ls-Dyna keyword
"-------------------------------------------------------------------------------

syntax match LsDynaStdKeyword_02_Col '\%11c.\{10}' contained
syntax match LsDynaStdKeyword_04_Col '\%31c.\{10}' contained
syntax match LsDynaStdKeyword_06_Col '\%51c.\{10}' contained
syntax match LsDynaStdKeyword_08_Col '\%71c.\{10}' contained

highlight default link LsDynaStdKeyword_02_Col Error
highlight default link LsDynaStdKeyword_04_Col Error
highlight default link LsDynaStdKeyword_06_Col Error
highlight default link LsDynaStdKeyword_08_Col Error

syntax cluster LsDynaStdKeywordCluster add=LsDynaComment
syntax cluster LsDynaStdKeywordCluster add=LsDynaKeyword
syntax cluster LsDynaStdKeywordCluster add=LsDynaTitle
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_02_Col
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_04_Col
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_06_Col
syntax cluster LsDynaStdKeywordCluster add=LsDynaStdKeyword_08_Col

syntax region LsDynaStdKeyword start=/^\*[a-zA-z]/ end=/^\*/me=s-1
 \ contains=@LsDynaStdKeywordCluster

"-------------------------------------------------------------------------------
"    *NODE / *AIRBAG_REF_
"-------------------------------------------------------------------------------

syntax match LsDynaNode_02_Col '\%9c.\{16}'  contained
syntax match LsDynaNode_04_Col '\%41c.\{16}' contained
syntax match LsDynaNode_06_Col '\%65c.\{8}'  contained

highlight default link LsDynaNode_02_Col Error
highlight default link LsDynaNode_04_Col Error
highlight default link LsDynaNode_06_Col Error

syntax cluster LsDynaNodeCluster add=LsDynaComment
syntax cluster LsDynaNodeCluster add=LsDynaKeyword
syntax cluster LsDynaNodeCluster add=LsDynaNode_02_Col
syntax cluster LsDynaNodeCluster add=LsDynaNode_04_Col
syntax cluster LsDynaNodeCluster add=LsDynaNode_06_Col

syntax region LsDynaNode start=/\c^\*NODE *$/ end=/^\*/me=s-1
 \ contains=@LsDynaNodeCluster
syntax region LsDynaAirbagRef start=/\c^\*AIRBAG_REF.*$/ end=/^\*/me=s-1
 \ contains=@LsDynaNodeCluster

" following two lines help with syntax highlighting synchronization
" but they slow down VIM performance for big files

"syntax sync match LsDynaNodeSync grouphere LsDynaNode '\c^\*NODE *$'
"syntax sync match LsDynaAirbagRefSync grouphere LsDynaAirbagRef '\c^\*AIRBAG_REF.*$'

"-------------------------------------------------------------------------------
"    *ELEMENT_ / *AIRBAG_SHELL_
"-------------------------------------------------------------------------------

syntax match LsDynaElShell_02_Col '\%9c.\{8}'  contained
syntax match LsDynaElShell_04_Col '\%25c.\{8}' contained
syntax match LsDynaElShell_06_Col '\%41c.\{8}' contained
syntax match LsDynaElShell_08_Col '\%57c.\{8}' contained
syntax match LsDynaElShell_10_Col '\%73c.\{8}' contained

highlight default link LsDynaElShell_02_Col Error
highlight default link LsDynaElShell_04_Col Error
highlight default link LsDynaElShell_06_Col Error
highlight default link LsDynaElShell_08_Col Error
highlight default link LsDynaElShell_10_Col Error

syntax cluster LsDynaElShellCluster add=LsDynaComment
syntax cluster LsDynaElShellCluster add=LsDynaKeyword
syntax cluster LsDynaElShellCluster add=LsDynaElShell_02_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_04_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_06_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_08_Col
syntax cluster LsDynaElShellCluster add=LsDynaElShell_10_Col

syntax region LsDynaElShell start=/\c^\*ELEMENT_.\+ *$/ end=/^\*/me=s-1
 \ contains=@LsDynaElShellCluster
syntax region LsDynaAirbagShell start=/\c^\*AIRBAG_SHELL_.\+ *$/ end=/^\*/me=s-1
 \ contains=@LsDynaElShellCluster

" following two lines help with syntax highlighting synchronization
" but they slow down VIM performance for big files

"syntax sync match LsDynaElShellSync grouphere LsDynaElShell '\c^\*ELEMENT_.\+ *$'
"syntax sync match LsDynaAirbagShellSync grouphere LsDynaAirbagShell '\c^\*AIRBAG_SHELL_.\+ *$'

"-------------------------------------EOF---------------------------------------
