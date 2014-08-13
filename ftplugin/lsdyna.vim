"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  12th of August 2014
" Version:      1.1.0
"
" History of change:
" v1.1.0
"   - most of functions moved to autoload
"     - keyword library
"     - include path
"     - curves commands
"     - autoformat function
"
" History of change:
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

" Fold all lines that do not begin with * (keyword),# and $ (comment)
setlocal foldexpr=getline(v:lnum)!~?\"\^[*#$]\"
setlocal foldmethod=expr
setlocal foldminlines=4

"-------------------------------------------------------------------------------
"    USEFUL MAPPINGS
"-------------------------------------------------------------------------------

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

 " go to end of the line
  normal! $
  " find keyword in backword
  call search(reKeyWord,'bW')
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

" set user completion flag
let b:lsDynaUserComp = 0

" set user completion function to run with <C-X><C-U>
setlocal completefunc=library#CompleteKeywords

" mapping for <CR>/<C-Y>
" if g:lsDynaUserComp is true run GetCompletion function
" if g:lsDynaUserComp is false act like <CR>/<C-Y>
inoremap <buffer><silent><script><expr> <CR>
 \ b:lsDynaUserComp ? "\<ESC>:call library#GetCompletion()\<CR>" : "\<CR>"
inoremap <buffer><silent><script><expr> <C-Y>
 \ b:lsDynaUserComp ? "\<ESC>:call library#GetCompletion()\<CR>" : "\<C-Y>"

" act <up> and <down> like Ctrl-p and Ctrl-n
" it has nothing to do with keyword library, it's only because I like it
inoremap <buffer><silent><script><expr> <Down>
 \ pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <buffer><silent><script><expr> <Up>
 \ pumvisible() ? "\<C-p>" : "\<Up>"

"-------------------------------------------------------------------------------
"    LINE FORMATING
"-------------------------------------------------------------------------------

noremap <buffer><script><silent> <LocalLeader><LocalLeader>
 \ :call autoformat#LsDynaLine()<CR>

"-------------------------------------------------------------------------------
"    CURVE COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -range -nargs=* LsDynaShift
 \ :call curves#Offset(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsDynaScale
 \ :call curves#Scale(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsDynaResample
 \ :call curves#Resample(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsDynaAddPoint
 \ :call curves#AddPoint(<line1>,<line2>,<f-args>)

command! -buffer -range LsDynaSwap
 \ :call curves#Swap(<line1>,<line2>)

"-------------------------------------------------------------------------------
"    INCLUDE PATH
"-------------------------------------------------------------------------------

noremap <buffer><script><silent> gf
 \ :call includepath#IncludePath()<CR>gf

noremap <buffer><script><silent> <C-W>f
 \ :call includepath#IncludePath()<CR><C-W>f

"-------------------------------------------------------------------------------
" restore vim functions
let &cpo = s:cpo_save

"-------------------------------------EOF---------------------------------------
