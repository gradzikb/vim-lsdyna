"-------------------------------------BOF---------------------------------------
"
" Vim syntax file
"
" Language:     Ls-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik (bartosz.gradzik@hotmail.com)
" Version:      1.2.1
" Last Change:  24.05.2016
"
" History of change:
" v1.2.1
"   - *ELEMENT_SEATBELT supported
" v1.2.0
"   - new highlight groups used
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

syntax match lsdynaComment '^\$.*$'
syntax match lsdynaTitle '^\([.\/]\|\w\).*$' contained
syntax match lsdynaKeywordName '^\*\a.*$' contains=lsdynaKeywordOption
syntax match lsdynaKeywordOption '_.*$' contained

highlight default link lsdynaComment lsdynaComment
highlight default link lsdynaKeywordName lsdynaKeywordName
highlight default link lsdynaKeywordOption lsdynaKeywordOption
highlight default link lsdynaTitle lsdynaTitle

"-------------------------------------------------------------------------------
"    Standard Ls-Dyna keyword
"-------------------------------------------------------------------------------

syntax match lsdynaKeyword_02_Col '\%11c.\{10}' contained
syntax match lsdynaKeyword_04_Col '\%31c.\{10}' contained
syntax match lsdynaKeyword_06_Col '\%51c.\{10}' contained
syntax match lsdynaKeyword_08_Col '\%71c.\{10}' contained

highlight default link lsdynaKeyword_02_Col lsdynaColumn
highlight default link lsdynaKeyword_04_Col lsdynaColumn
highlight default link lsdynaKeyword_06_Col lsdynaColumn
highlight default link lsdynaKeyword_08_Col lsdynaColumn

syntax cluster lsdynaKeywordCluster add=lsdynaComment
syntax cluster lsdynaKeywordCluster add=lsdynaKeywordName
syntax cluster lsdynaKeywordCluster add=lsdynaTitle
syntax cluster lsdynaKeywordCluster add=lsdynaKeyword_02_Col
syntax cluster lsdynaKeywordCluster add=lsdynaKeyword_04_Col
syntax cluster lsdynaKeywordCluster add=lsdynaKeyword_06_Col
syntax cluster lsdynaKeywordCluster add=lsdynaKeyword_08_Col

syntax region lsdynaKeywordReg start=/^\*\a/ end=/^\*/me=s-1
 \ contains=@lsdynaKeywordCluster

"-------------------------------------------------------------------------------
"    Nodes i10
"-------------------------------------------------------------------------------

syntax match lsdynaNodeI10_02_Col '\%11c.\{16}'  contained
syntax match lsdynaNodeI10_04_Col '\%43c.\{16}' contained
syntax match lsdynaNodeI10_06_Col '\%67c.\{10}'  contained

highlight default link lsdynaNodeI10_02_Col lsdynaColumn
highlight default link lsdynaNodeI10_04_Col lsdynaColumn
highlight default link lsdynaNodeI10_06_Col lsdynaColumn

syntax cluster lsdynaNodeI10Cluster add=lsdynaComment
syntax cluster lsdynaNodeI10Cluster add=lsdynaKeywordName
syntax cluster lsdynaNodeI10Cluster add=lsdynaNodeI10_02_Col
syntax cluster lsdynaNodeI10Cluster add=lsdynaNodeI10_04_Col
syntax cluster lsdynaNodeI10Cluster add=lsdynaNodeI10_06_Col

syntax region lsdynaNodeI10Reg
 \ start = /\c^\*\(NODE\|AIRBAG_REFERENCE_GEOMETRY\) %\s*$/
 \ end = /^\*/me=s-1
 \ contains = @lsdynaNodeI10Cluster

"-------------------------------------------------------------------------------
"    Nodes
"-------------------------------------------------------------------------------

syntax match lsdynaNode_02_Col '\%9c.\{16}'  contained
syntax match lsdynaNode_04_Col '\%41c.\{16}' contained
syntax match lsdynaNode_06_Col '\%65c.\{8}'  contained

highlight default link lsdynaNode_02_Col lsdynaColumn
highlight default link lsdynaNode_04_Col lsdynaColumn
highlight default link lsdynaNode_06_Col lsdynaColumn

syntax cluster lsdynaNodeCluster add=lsdynaComment
syntax cluster lsdynaNodeCluster add=lsdynaKeywordName
syntax cluster lsdynaNodeCluster add=lsdynaNode_02_Col
syntax cluster lsdynaNodeCluster add=lsdynaNode_04_Col
syntax cluster lsdynaNodeCluster add=lsdynaNode_06_Col

syntax region lsdynaNodeI10Reg
 \ start = /\c^\*\(NODE\|AIRBAG_REFERENCE_GEOMETRY\)\s*$/
 \ end = /^\*/me=s-1
 \ contains = @lsdynaNodeCluster

"-------------------------------------------------------------------------------
"    Elements
"-------------------------------------------------------------------------------

syntax match lsdynaElem_02_Col '\%9c.\{8}'  contained
syntax match lsdynaElem_04_Col '\%25c.\{8}' contained
syntax match lsdynaElem_06_Col '\%41c.\{8}' contained
syntax match lsdynaElem_08_Col '\%57c.\{8}' contained
syntax match lsdynaElem_10_Col '\%73c.\{8}' contained

highlight default link lsdynaElem_02_Col lsdynaColumn
highlight default link lsdynaElem_04_Col lsdynaColumn
highlight default link lsdynaElem_06_Col lsdynaColumn
highlight default link lsdynaElem_08_Col lsdynaColumn
highlight default link lsdynaElem_10_Col lsdynaColumn

syntax cluster lsdynaElemCluster add=lsdynaComment
syntax cluster lsdynaElemCluster add=lsdynaKeywordName
syntax cluster lsdynaElemCluster add=lsdynaElem_02_Col
syntax cluster lsdynaElemCluster add=lsdynaElem_04_Col
syntax cluster lsdynaElemCluster add=lsdynaElem_06_Col
syntax cluster lsdynaElemCluster add=lsdynaElem_08_Col
syntax cluster lsdynaElemCluster add=lsdynaElem_10_Col

syntax region lsdynaElemReg start=/\c^\*ELEMENT_.*$/ end=/^\*/me=s-1
 \ contains=@lsdynaElemCluster
syntax region lsdynaAirbagShellReg start=/\c^\*AIRBAG_SHELL_.\+ *$/ end=/^\*/me=s-1
 \ contains=@lsdynaElemCluster
syntax region lsdynaElemBeltSlipReg start=/\c^\*ELEMENT_SEATBELT_\a\+\s*$/ end=/^\*/me=s-1
 \ contains=@lsdynaKeywordCluster

"-------------------------------------------------------------------------------
"    Elements I10
"-------------------------------------------------------------------------------

syntax region lsdynaElemI10Reg start=/\c^\*ELEMENT_\w\+ %\s*$/ end=/^\*/me=s-1
 \ contains=@lsdynaKeywordCluster
syntax region lsdynaAirbagShellReg start=/\c^\*AIRBAG_SHELL_\w\+ %\s*$/ end=/^\*/me=s-1
 \ contains=@lsdynaKeywordCluster
syntax region lsdynaElemI10BeltSlipReg start=/\c^\*ELEMENT_SEATBELT_\w\+ %\s*$/ end=/^\*/me=s-1
 \ contains=@lsdynaKeywordCluster

"-------------------------------------EOF---------------------------------------
