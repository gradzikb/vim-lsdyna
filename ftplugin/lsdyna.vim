"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  30th of January 2016
" Version:      1.2.8
"
" History of change:
"
" v1.2.8
"   - folding improved (commented node/element lines folded as well)
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
"       - *ELEMENT_PLOEL
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
"    PREFERED TAB SETTINGS
"-------------------------------------------------------------------------------

" use spaces instead tab
setlocal expandtab
" set tab width to 10
setlocal tabstop=10
" set width for < > commands
setlocal shiftwidth=10
" do not remove tab space equvivalent but only one sign
setlocal softtabstop=0
" allow for virtual columns
setlocal virtualedit=all

"-------------------------------------------------------------------------------
"    FOLDING
"-------------------------------------------------------------------------------

function! LsDynaFold(lnum)

  " do not fold keyword line
  if getline(a:lnum) =~? '^\*'
    let foldlevel = 0
  " fold comment line with node/element in 1st column
  elseif getline(a:lnum) =~? '^\$\s\{0,7}\d'
    let foldlevel = 1
  " do not fold comment line
  elseif getline(a:lnum) =~? '^\$'
    let foldlevel = 0
  " by default everything is folded
  else
    let foldlevel = 1
  endif

  return foldlevel

endfunction

" folding settings
setlocal foldexpr=LsDynaFold(v:lnum)
setlocal foldmethod=expr
setlocal foldminlines=4

"-------------------------------------------------------------------------------
"    INDENT
"-------------------------------------------------------------------------------

" reset indent rules
setlocal indentexpr=

"-------------------------------------------------------------------------------
"    USEFUL MAPPINGS
"-------------------------------------------------------------------------------

function! s:LsDynaComment()

  if getline('.')[0] == '4'
    let tmpUnnamedReg = @@
    normal! hx
    let @@ = tmpUnnamedReg
    return '$'
  else
    return ''
  endif

endfunction
" change 4 -> $ but only at the beginning of the line
inoreabbrev 4 4<C-R>=<SID>LsDynaComment()<CR>

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
"    INCLUDES
"-------------------------------------------------------------------------------

" always set current working directory respect to open file
augroup lsdyna
  autocmd!
  " set working directory to current file
  cd %:p:h
  autocmd BufNewFile * cd %:p:h
  autocmd BufReadPost * cd %:p:h
  autocmd WinEnter * cd %:p:h
  autocmd TabEnter * cd %:p:h
  autocmd BufWrite * set ff=unix
augroup END

"-------------------------------------------------------------------------------
"    COMMENT FUNCTION
"-------------------------------------------------------------------------------

" prefered Alt-C but not always works ...
noremap <silent><buffer> <M-c> :call <SID>Comment()<CR>j
" ... use Ctrl-C instead
noremap <silent><buffer> <C-c> :call <SID>Comment()<CR>j

function! <SID>Comment() range

  if getline(a:firstline) =~? "^\\$"
    silent execute a:firstline . ',' . a:lastline . 's/^\$//'
  else
    silent execute a:firstline . ',' . a:lastline . 's/^/$/'
  endif

endfunction

"-------------------------------------------------------------------------------
"    TEXT OBJECTS
"-------------------------------------------------------------------------------

" around keyword (ak) and insert keyword (ik) works the same
vnoremap <buffer><script><silent> ik :call <SID>KeywordTextObj()<CR>
onoremap <buffer><script><silent> ik :call <SID>KeywordTextObj()<CR>
vnoremap <buffer><script><silent> ak :call <SID>KeywordTextObj()<CR>
onoremap <buffer><script><silent> ak :call <SID>KeywordTextObj()<CR>

function! s:KeywordTextObj()

 let reKeyWord  = "^\*[A-Za-z_]"
 let reDataLine = "^[^$]\\|^$"

  " find keyword in backword
  call search(reKeyWord,'bWc')
  " start line visual mode
  normal! V
  " serach next keyword
  let res = search(reKeyWord, 'W')
  " go to the end of file if you did not find the keyword
  if res == 0
    normal! G
  endif
  " move back to first data line
  call search(reDataLine,'bW')

endfunction

"-------------------------------------------------------------------------------
"    KEYWORDS LIBRARY
"-------------------------------------------------------------------------------

" allow to use Ctrl-Tab for user completion
inoremap <C-Tab> <C-X><C-U>

" set using popupmenu for completion
setlocal completeopt+=menu
setlocal completeopt+=menuone

" set path to keyword library directory
if !exists("g:lsdynaKeyLibPath")
  let g:lsdynaKeyLibPath = expand('<sfile>:p:h:h') . '/keywords/'
endif

" initialize lsdyna keyword library
" the library is initilized only once per Vim session
if !exists("g:lsdynaKeyLib")
  let g:lsdynaKeyLib =lsdyna_library#initLib(g:lsdynaKeyLibPath)
endif

" set user completion flag
let b:lsDynaUserComp = 0

" set user completion function to run with <C-X><C-U>
setlocal completefunc=lsdyna_library#CompleteKeywords

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
"    LINE FORMATING
"-------------------------------------------------------------------------------

noremap <buffer><script><silent> <LocalLeader><LocalLeader>
 \ :call lsdyna_autoformat#LsDynaLine()<CR>

noremap <buffer><script><silent> >
 \ :<c-u>call lsdyna_indent#Indent("Right")<CR>

noremap <buffer><script><silent> <
 \ :<c-u>call lsdyna_indent#Indent("Left")<CR>

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

command! -buffer -range -nargs=* LsElemSort
 \ :call lsdyna_element#Sort(<line1>,<line2>,<f-args>)

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
