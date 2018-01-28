"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  4th of January 2018
" Version:      1.5.0
"
" History of change:
"
" v1.5.0
"   - file clean up
" v1.4.0
"   - omni completion added
"   - tags for dyna added
" v1.3.1
"   - File cleanup
" v1.3.0
"   - PIDTextObject() replaced with GetColumn() function
"   - LsElemSortPid command removed
" v1.2.9
"   - LsDynaComment() function update to be more robust
" v1.2.8
"   - visual block selection for PID column added
"     - new function PIDTextObject()
"     - new mapping ap/ip
" v1.2.7
"   - new commands structure
" v1.2.6
"   - lsdyna_indent#Indent function added
" v1.2.5
"   - better autoformating *PARAMETER keyword
" v1.2.4
"   - LsDynaOffsetId command added
" v1.2.3
"   - LsDynaComment function updated, does not overwrite unnamed register now
" v1.2.2
"   - LsDynaSortbyPart command updated to use search user pid
"   - <M-r> mapping added (remove all comment line from selection)
" v1.2.1
"   - LsDynaSortbyPart command added
" v1.2.0
"   - keyword library functions updated for new library organisation
"   - updates for new autoload file names
"   - LsDynaReverse command added
" v1.1.1
"   - enter button from numeric pad can be used with keyword library as well
" v1.1.0
"   - most of functions moved to autoload
"     - keyword library
"     - include path
"     - curves commands
"     - autoformat function
" v1.0.3
"   - LsDynaLine function updated
"     - folowing keywords are supported now
"       - *PARAMETER
" v1.0.2
"   - LsDynaLine function updated
"     - regular expresion for keyword line updated
"     - folowing keywords are supported now
"       - *ELEMENT_MASS, _PART, _PART_SET
"       - *ELEMENT_BEAM
"       - *ELEMENT_DISCRETE
"       - *ELEMENT_PLOTEL
"       - *ELEMENT_SEATBELT
"       - *ELEMENT_SOLID
"       - *ELEMENT_SHELL
" v1.0.1
"   - GetCompletion function updated
"     - unnamed register is not overwrite by keyword library
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
"    FILETYPE PLUGIN SETTINGS
"-------------------------------------------------------------------------------

" check if the plugin is already load into current buffer
if exists("b:did_ftplugin") | finish | endif
" set flag when ls-dyna filetype plugin is loaded
let b:did_ftplugin = 1
" save current compatible settings
let s:cpo_save = &cpo
" reset vim to default settings
set cpo&vim

"-------------------------------------------------------------------------------
"    VARIABLES
"-------------------------------------------------------------------------------

"set $VIMHOME variable base on OS
if has('win32') || has ('win64')
  let $VIMHOME = $HOME."/vimfiles"
else
  let $VIMHOME = $HOME."/.vim"
endif

"-------------------------------------------------------------------------------
"    COLORS
"-------------------------------------------------------------------------------

"load colors
colorscheme lsdyna
setlocal syntax=lsdyna

"-------------------------------------------------------------------------------
"    MISC SETTINGS
"-------------------------------------------------------------------------------

" allow to change buffers w/o write
setlocal hidden
" use spaces instead tab
setlocal expandtab
" set tab width to 10
setlocal tabstop=10
" set width for < > commands
setlocal shiftwidth=10
" allow for virtual columns
setlocal virtualedit=all
" command line completion (show all possibilities)
setlocal wildmode=list,full
" reset indent rules
setlocal indentexpr=
" always change current directory
setlocal autochdir
" set tags file
set tags=$VIMHOME/.dtags
" set using popup menu for completion
if v:version == '800'
  setlocal completeopt=menu,menuone,noinsert
else
  setlocal completeopt=menu,menuone
endif

"-------------------------------------------------------------------------------
"    FOLDING
"-------------------------------------------------------------------------------

" folding settings
setlocal foldexpr=getline(v:lnum)[0]!~'[*$]'
setlocal foldmethod=expr
setlocal foldminlines=4

"-------------------------------------------------------------------------------
"    AUTOGROUP
"-------------------------------------------------------------------------------

augroup lsdyna
  autocmd!

  " store file as unix
  autocmd BufWrite * set ff=unix

augroup END

"-------------------------------------------------------------------------------
"    MAPPINGS
"-------------------------------------------------------------------------------

" change 4 -> '$' sign at the line beginning
inoreabbrev 4 4<C-R>=lsdyna_misc#CommentSign()<CR>
" comment/uncomment line
noremap <silent><buffer> <M-c> :call lsdyna_misc#CommentLine()<CR>j
" put empty comment line below
nnoremap <silent><buffer> <LocalLeader>c o$<ESC>0
" put empty comment line above
nnoremap <silent><buffer> <LocalLeader>C O$<ESC>0
" put separator line above
nnoremap <silent><buffer> <LocalLeader>1 o$-------------------------------------------------------------------------------<ESC>0
nnoremap <silent><buffer> <LocalLeader>2 o$-------10--------20--------30--------40--------50--------60--------70--------80<ESC>0
" put separator line below
nnoremap <silent><buffer> <LocalLeader>! O$-------------------------------------------------------------------------------<ESC>0
nnoremap <silent><buffer> <LocalLeader>@ O$-------10--------20--------30--------40--------50--------60--------70--------80<ESC>0
" put title separator line below
nnoremap <silent><buffer> <LocalLeader>0 o$<ESC>79a-<ESC>yypO$<ESC>A    
" put title separator line above
nnoremap <silent><buffer> <LocalLeader>) O$<ESC>79a-<ESC>yypO$<ESC>A    
" jump to next keyword
nnoremap <silent><buffer> [[ ?^\*\a<CR>:nohlsearch<CR>zz
" jump to previous keyword
nnoremap <silent><buffer> ]] /^\*\a<CR>:nohlsearch<CR>zz
" remove all comment lines from selection
vnoremap <silent><buffer> <M-r> :g/^\$/d<CR>:nohlsearch<CR>
" tags mappings (do not jump to the first but always show full list)
nnoremap <C-]> g<C-]>
nnoremap <c-leftmouse> g<c-]>
" check includes before write
cnoremap w<CR> <C-u>call lsdyna_include#quit("w")<CR>
cnoremap wq<CR> <C-u>call lsdyna_include#quit("wq")<CR>
" autoformat function
noremap <buffer><script><silent> <LocalLeader><LocalLeader> :call lsdyna_autoformat#Autoformat()<CR>
" open include file in current window
noremap <buffer><script><silent> gf :call lsdyna_include#expandPath()<CR>gf
" open include file in separate window
noremap <buffer><script><silent> gF :call lsdyna_include#expandPath()<CR><C-w>f<C-w>H
" open include directory in current window
noremap <buffer><script><silent> gd :execute "edit ".fnamemodify(getline("."), ":p:h")<CR>
" open include directory in separate window
noremap <buffer><script><silent> gD :execute "vertical split ".fnamemodify(getline("."), ":p:h")<CR><C-w>L
" text object around keyword (ak) and insert keyword (ik) works the same
vnoremap <buffer><script><silent> ik :call lsdyna_misc#KeywordTextObject()<CR>
onoremap <buffer><script><silent> ik :call lsdyna_misc#KeywordTextObject()<CR>
vnoremap <buffer><script><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
onoremap <buffer><script><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
" text object around column (ac) and insert column (ic) works the same
vnoremap <buffer><script><silent> ac :call lsdyna_misc#ColumnTextObject()<CR>
onoremap <buffer><script><silent> ac :call lsdyna_misc#ColumnTextObject()<CR>
vnoremap <buffer><script><silent> ic :call lsdyna_misc#ColumnTextObject()<CR>
onoremap <buffer><script><silent> ic :call lsdyna_misc#ColumnTextObject()<CR>
" begining and end lines
inoreabbrev bof $-------------------------------------BOF---------------------------------------
inoreabbrev eof $-------------------------------------EOF---------------------------------------

"-------------------------------------------------------------------------------
"    COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -nargs=* LsTags
 \ :call lsdyna_tags#cmdlstags(<f-args>)

command! -buffer -range -nargs=* LsCurveOffset
 \ :call lsdyna_curve#Offset(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsCurveScale
 \ :call lsdyna_curve#Scale(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=0 LsCurveMirror
 \ :call lsdyna_curve#Mirror(<line1>,<line2>)

command! -buffer -range -nargs=* LsCurveCut
 \ :call lsdyna_curve#Cut(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsCurveResample
 \ :call lsdyna_curve#Resample(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=1 LsCurveAddPoint
 \ :call lsdyna_curve#Addpoint(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeScale
 \ :call lsdyna_node#Scale(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeTranslate
 \ :call lsdyna_node#Transl(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeRotate
 \ :call lsdyna_node#Rotate(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodePos6p
 \ :call lsdyna_node#Pos6p(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeMirror
 \ :call lsdyna_node#Mirror(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsElemFindPid
 \ :call lsdyna_element#FindPid(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsElemChangePid
 \ :call lsdyna_element#ChangePid(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=0 LsElemReverseNormals
 \ :call lsdyna_element#ReverseNormals(<line1>,<line2>)

command! -buffer -range -nargs=+ LsOffsetId
 \ :call lsdyna_offset#Offset(<line1>,<line2>,<f-args>)

command! -buffer -nargs=0 LsInclCheckPath
 \ :call lsdyna_include#checkIncl()

command! -buffer -nargs=0 LsIncl2Buff
 \ :call lsdyna_include#incl2buff()

" abbreviations for commonly used commands
cnoreabbrev lcs LsCurveScale
cnoreabbrev lco LsCurveOffset
cnoreabbrev lcr LsCurveResample
cnoreabbrev lca LsCurveAddPoint
cnoreabbrev lcm LsCurveMirror
cnoreabbrev lcc LsCurveCut

cnoreabbrev lns LsNodeScale
cnoreabbrev lnt LsNodeTranslate
cnoreabbrev lnr LsNodeRotate
cnoreabbrev lnp LsNodePos6p
cnoreabbrev lnm LsNodeMirror

cnoreabbrev lec LsElemChangePid
cnoreabbrev lef LsElemFindPid
cnoreabbrev ler LsElemReverseNormals

"-------------------------------------------------------------------------------
"    COMPLETION
"-------------------------------------------------------------------------------

" set search method
" 't' : use tag file only
" 'b' : use current buffer only
" 'B' : use all open buffers
" 'i' : like 'B' but add *INCLUDE files as new buffers
if !exists("g:lsdynaSearchMode") | let g:lsdynaSearchMode = 'i' | endif

" set global paths
if !exists("g:lsdynaPathTags")     | let g:lsdynaPathTags     = $VIMHOME."/.dtags"                                       | endif
if !exists("g:lsdynaPathKeywords") | let g:lsdynaPathKeywords = expand('<sfile>:p:h:h') . '/keywords/'                   | endif
if !exists("g:lsdynaPathKvars")    | let g:lsdynaPathKvars    = expand('<sfile>:p:h:h') . '/keywords/dynaKvars.dat'      | endif
if !exists("g:lsdynaPathHeaders")  | let g:lsdynaPathHeaders  = expand('<sfile>:p:h:h') . '/keywords/dynaTagHeaders.dat' | endif

" set variables
if !exists("g:lsdynaLibKeywords")  | let g:lsdynaLibKeywords  = lsdyna_complete#libKeywords(g:lsdynaPathKeywords) | endif
if !exists("g:lsdynaLibHeaders")   | let g:lsdynaLibHeaders   = lsdyna_complete#libHeaders(g:lsdynaPathHeaders)   | endif
if !exists("g:dtags")              | let g:dtags              = lsdyna_tags#dynatags()                            | endif
if !exists("g:kvars")              | let g:kvars              = lsdyna_kvars#kvars(g:lsdynaPathKvars)             | endif
if !exists("b:lsdynaCompleteType") | let b:lsdynaCompleteType = 'none'                                            | endif

" set omni completion functions
setlocal omnifunc=lsdyna_complete#LsdynaComplete

" completion mappings
inoremap <C-Tab> <C-X><C-O>
nnoremap <C-Tab> :call lsdyna_complete#extendLine()<CR>R<C-X><C-O>
inoremap <buffer><silent><expr> <CR>     lsdyna_complete#LsDynaMapEnter()
inoremap <buffer><silent><expr> <kEnter> lsdyna_complete#LsDynaMapEnter()
inoremap <buffer><silent><expr> <C-Y>    lsdyna_complete#lsdynamapCtrly()

"-------------------------------------------------------------------------------

" restore vim functions
let &cpo = s:cpo_save

"-------------------------------------EOF---------------------------------------
