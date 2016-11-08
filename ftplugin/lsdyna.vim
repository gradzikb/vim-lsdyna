"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  5th of November 2016
" Version:      1.3.1
"
" History of change:
"
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
"    COLORS
"-------------------------------------------------------------------------------

"load colors
colorscheme lsdyna

"-------------------------------------------------------------------------------
"    MISC SETTINGS
"-------------------------------------------------------------------------------

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

"-------------------------------------------------------------------------------
"    FOLDING
"-------------------------------------------------------------------------------

" folding settings
setlocal foldexpr=getline(v:lnum)[0]!~'[*$]'
setlocal foldmethod=expr
setlocal foldminlines=4

"-------------------------------------------------------------------------------
"    USEFUL MAPPINGS
"-------------------------------------------------------------------------------

" comment/uncomment line
noremap <silent><buffer> <M-c> :call lsdyna_misc#CommentLine()<CR>j
" change 4 -> $ but only at the beginning of the line
inoreabbrev 4 4<C-R>=lsdyna_misc#CommentSign()<CR>

" mapping for separation lines
nnoremap <silent><buffer> <LocalLeader>c o$<ESC>0
nnoremap <silent><buffer> <LocalLeader>C O$<ESC>0
nnoremap <silent><buffer> <LocalLeader>1 o$<ESC>79a-<ESC>0
nnoremap <silent><buffer> <LocalLeader>! O$<ESC>79a-<ESC>0
nnoremap <silent><buffer> <LocalLeader>2 o
 \$-------10--------20--------30--------40
 \--------50--------60--------70--------80<ESC>0
nnoremap <silent><buffer> <LocalLeader>@ O
 \$-------10--------20--------30--------40
 \--------50--------60--------70--------80<ESC>0
nnoremap <silent><buffer> <LocalLeader>3 o
 \$--------\|---------\|---------\|---------\|
 \---------\|---------\|---------\|---------\|<ESC>0
nnoremap <silent><buffer> <LocalLeader># O
 \$--------\|---------\|---------\|---------\|
 \---------\|---------\|---------\|---------\|<ESC>0
nnoremap <silent><buffer> <LocalLeader>0 o$<ESC>79a-<ESC>yypO$<ESC>A    
nnoremap <silent><buffer> <LocalLeader>) O$<ESC>79a-<ESC>yypO$<ESC>A    

" jump to previous keyword
nnoremap <silent><buffer> [[ ?^\*\a<CR>:nohlsearch<CR>zz
" jump to next keyword
nnoremap <silent><buffer> ]] /^\*\a<CR>:nohlsearch<CR>zz

" remove all comment lines from selection
vnoremap <silent><buffer> <M-r> :g/^\$/d<CR>:nohlsearch<CR>
"
inoreabbrev bof $-------------------------------------BOF---------------------------------------
inoreabbrev eof $-------------------------------------EOF---------------------------------------

"-------------------------------------------------------------------------------
"    AUTOGROUP
"-------------------------------------------------------------------------------

augroup lsdyna
  autocmd!
  " store file as unix
  autocmd BufWrite * set ff=unix
augroup END

"-------------------------------------------------------------------------------
"    TEXT OBJECTS
"-------------------------------------------------------------------------------

" around keyword (ak) and insert keyword (ik) works the same
vnoremap <buffer><script><silent> ik :call lsdyna_misc#KeywordTextObject()<CR>
onoremap <buffer><script><silent> ik :call lsdyna_misc#KeywordTextObject()<CR>
vnoremap <buffer><script><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
onoremap <buffer><script><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>

" around column (ac) and insert column (ic) works the same
vnoremap <buffer><script><silent> ac :call lsdyna_misc#ColumnTextObject()<CR>
onoremap <buffer><script><silent> ac :call lsdyna_misc#ColumnTextObject()<CR>
vnoremap <buffer><script><silent> ic :call lsdyna_misc#ColumnTextObject()<CR>
onoremap <buffer><script><silent> ic :call lsdyna_misc#ColumnTextObject()<CR>

"-------------------------------------------------------------------------------
"    KEYWORDS LIBRARY
"-------------------------------------------------------------------------------

" set user completion function to run with <C-X><C-U>
setlocal completefunc=lsdyna_library#CompleteKeywords
" allow to use Ctrl-Tab for user completion
inoremap <C-Tab> <C-X><C-U>
" set using popup menu for completion
setlocal completeopt+=menu
setlocal completeopt+=menuone

" set path to keyword library directory
if !exists("g:lsdynaKeyLibPath")
  let g:lsdynaKeyLibPath = expand('<sfile>:p:h:h') . '/keywords/'
endif

" initialize lsdyna keyword library
" the library is initialized only once per Vim session
if !exists("g:lsdynaKeyLib")
  let g:lsdynaKeyLib =lsdyna_library#initLib(g:lsdynaKeyLibPath)
endif

" set user completion flag
let b:lsDynaUserComp = 0

" mapping for <CR>/<C-Y>/<kEnter>
" if g:lsDynaUserComp is true run GetCompletion function
" if g:lsDynaUserComp is false act like <CR>/<C-Y>/<kEnter>
inoremap <buffer><silent><script><expr> <CR>
 \ b:lsDynaUserComp ? "\<ESC>:call lsdyna_library#GetCompletion()\<CR>" : "\<CR>"
inoremap <buffer><silent><script><expr> <C-Y>
 \ b:lsDynaUserComp ? "\<ESC>:call lsdyna_library#GetCompletion()\<CR>" : "\<C-Y>"
inoremap <buffer><silent><script><expr> <kEnter>
 \ b:lsDynaUserComp ? "\<ESC>:call lsdyna_library#GetCompletion()\<CR>" : "\<kEnter>"

" act <up> and <down> like Ctrl-p and Ctrl-n
inoremap <buffer><silent><script><expr> <Down>
 \ pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <buffer><silent><script><expr> <Up>
 \ pumvisible() ? "\<C-p>" : "\<Up>"

"-------------------------------------------------------------------------------
"    LINE FORMATTING
"-------------------------------------------------------------------------------

noremap <buffer><script><silent> <LocalLeader><LocalLeader>
 \ :call lsdyna_autoformat#Autoformat()<CR>

"-------------------------------------------------------------------------------
"    CURVE COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -range -nargs=* LsCurveShift
 \ :call lsdyna_curves#Shift(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsCurveScale
 \ :call lsdyna_curves#Scale(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsCurveResample
 \ :call lsdyna_curves#Resample(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsCurveAddPoint
 \ :call lsdyna_curves#AddPoint(<line1>,<line2>,<f-args>)

command! -buffer -range LsCurveSwapXY
 \ :call lsdyna_curves#SwapXY(<line1>,<line2>)

command! -buffer -range LsCurveRevers
 \ :call lsdyna_curves#Reverse(<line1>,<line2>)

"-------------------------------------------------------------------------------
"    NODE COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -range -nargs=* LsNodeScale
 \ :call lsdyna_node#Scale(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeShift
 \ :call lsdyna_node#Shift(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeReflect
 \ :call lsdyna_node#Reflect(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeOffsetId
 \ :call lsdyna_element#OffsetId(<line1>,<line2>,<f-args>)

"-------------------------------------------------------------------------------
"    ELEMENT COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -range -nargs=* LsElemFindPid
 \ :call lsdyna_element#FindPid(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsElemOffsetId
 \ :call lsdyna_element#OffsetId(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsElemChangePid
 \ :call lsdyna_element#ChangePid(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=0 LsElemReverseNormals
 \ :call lsdyna_element#ReverseNormals(<line1>,<line2>)

"-------------------------------------------------------------------------------
"    INCLUDE PATH
"-------------------------------------------------------------------------------

noremap <buffer><script><silent> gf
 \ :call lsdyna_include#ExpandPath()<CR>gf

noremap <buffer><script><silent> gF
 \ :call lsdyna_include#ExpandPath()<CR><C-w>f<C-w>H

command! -buffer -nargs=0 LsCheckPath
 \ :call lsdyna_include#CheckPath()

"-------------------------------------------------------------------------------

" restore vim functions
let &cpo = s:cpo_save

"-------------------------------------EOF---------------------------------------
