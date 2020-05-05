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
" cli
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

syntax on
colorscheme lsdyna

"-------------------------------------------------------------------------------
"    MISC SETTINGS
"-------------------------------------------------------------------------------

setlocal nocompatible
setlocal incsearch
setlocal hlsearch
setlocal ignorecase
setlocal smartcase
setlocal hidden
setlocal expandtab
setlocal tabstop=10
setlocal shiftwidth=10
setlocal virtualedit=all
setlocal noautochdir
setlocal noautoindent
setlocal shellslash
setlocal cursorline
setlocal backspace=2
setlocal wildmode=list,full
setlocal textwidth=80
setlocal tags=$VIMHOME/.dtags
setlocal listchars=tab:>-,trail:-
setlocal list
setlocal completeopt=menuone,noinsert
"if v:version == '800'
"  setlocal completeopt=menu,menuone,noinsert
"else
"  setlocal completeopt=menu,menuone
"endif

"-------------------------------------------------------------------------------
"    FOLDING
"-------------------------------------------------------------------------------

setlocal foldexpr=getline(v:lnum)[0]!~'[*$]'
setlocal foldminlines=4
setlocal foldmethod=expr

"-------------------------------------------------------------------------------
"    AUTOGROUP
"-------------------------------------------------------------------------------

augroup lsdyna
  autocmd!
  autocmd BufWrite * set fileformat=unix
  "autocmd BufWritePre * call lsdyna_include#Check()
augroup END

augroup lsdyna-lsManager
  autocmd!
  " format lines in quickfix window
  autocmd BufReadPost quickfix setlocal modifiable | silent call lsdyna_manager#format() | setlocal nomodifiable
  " focus view on quickfix item everytime a cursor is moved
  autocmd FileType qf autocmd CursorMoved <buffer> call lsdyna_manager#SetPosition()
  " clear 'search' highlight for quikfix window and restore it back after close
  autocmd FileType qf setlocal cursorline
  autocmd FileType qf hi search none
  autocmd FileType qf autocmd BufDelete <buffer> hi search term=reverse ctermfg=0 ctermbg=12 guifg=Black guibg=Red
augroup END

"-------------------------------------------------------------------------------
"    MAPPINGS
"-------------------------------------------------------------------------------

" change 4 -> '$' sign at the line beginning
inoreabbrev 4 <C-R>=(col('.')==1 ? '$' : 4)<CR>
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
" tags mappings (do not jump to the first but always show full list)
nnoremap <C-]> g<C-]>
nnoremap <c-leftmouse> g<c-]>
" check includes before write
command! -nargs=0 -bang W call lsdyna_include#Quit(<bang>0, "w")
command! -nargs=0 -bang WQ call lsdyna_include#Quit(<bang>0, "wq")
cnoreabbrev <expr> w  (getcmdtype()==':' && getcmdline()== 'w') ?  'W' :  'w'
cnoreabbrev <expr> wq (getcmdtype()==':' && getcmdline()=='wq') ? 'WQ' : 'wq'
" autoformat function
noremap <buffer><script><silent> <LocalLeader><LocalLeader> :call lsdyna_autoformat#Autoformat()<CR>
" begining and end lines
inoreabbrev bof $-------------------------------------BOF---------------------------------------
inoreabbrev eof $-------------------------------------EOF---------------------------------------
" maping to open include files
noremap <buffer><silent> gf :call lsdyna_include#Open(line('.'),'b')<CR>
noremap <buffer><silent> gF :call lsdyna_include#Open(line('.'),'s')<CR>
noremap <buffer><silent> gt :call lsdyna_include#Open(line('.'),'t')<CR>
noremap <buffer><silent> gT :call lsdyna_include#Open(line('.'),'T')<CR>
noremap <buffer><silent> gd :call lsdyna_include#Open(line('.'),'d')<CR>
noremap <buffer><silent> gD :call lsdyna_include#Open(line('.'),'D')<CR>
noremap <buffer><silent> g<C-d> :call lsdyna_include#Open(line('.'),'e')<CR>
" plugin text objects
vnoremap <buffer><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
onoremap <buffer><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
" LsManager mappings
noremap <buffer><silent> <F12>* :LsManager *<CR>
noremap <buffer><silent> <F12>. :call lsdyna_manager#Open(g:lsdyna_manager_qflist_old)<CR>
noremap <buffer><silent> <F12><F12> :LsManager include<CR>
noremap <buffer><silent> <F12>C :LsManager constrained<CR>
noremap <buffer><silent> <F12>I :call lsdyna_manager#Open(g:lsdyna_manager_qflist_includes_old)<CR>
noremap <buffer><silent> <F12>P :LsManager parameter<CR>
noremap <buffer><silent> <F12>S :LsManager set<CR>
noremap <buffer><silent> <F12>a :LsManager airbag<CR>
noremap <buffer><silent> <F12>b :LsManager boundary<CR>
noremap <buffer><silent> <F12>c :LsManager contact<CR>
noremap <buffer><silent> <F12>dc :LsManager define_curve<CR>
noremap <buffer><silent> <F12>dC :LsManager define_coordinate<CR>
noremap <buffer><silent> <F12>df :LsManager define_friction<CR>
noremap <buffer><silent> <F12>dt :LsManager define_transformation<CR>
noremap <buffer><silent> <F12>dv :LsManager define_vector<CR>
noremap <buffer><silent> <F12>e :LsManager element<CR>
noremap <buffer><silent> <F12>i :LsManager include<CR>
noremap <buffer><silent> <F12>l :LsManager load<CR>
noremap <buffer><silent> <F12>m :LsManager mat<CR>
noremap <buffer><silent> <F12>n :LsManager node<CR>
noremap <buffer><silent> <F12>p :LsManager part<CR>
noremap <buffer><silent> <F12>s :LsManager section<CR>
noremap <buffer><silent> <F12><C-s> :LsManager sensor<CR>
noremap <buffer><silent> <F12>x :LsManager database_cross_section<CR>
noremap <buffer><silent> <S-F12>* :LsManager! *<CR>
noremap <buffer><silent> <S-F12><F12> :LsManager! include<CR>
noremap <buffer><silent> <S-F12><S-F12> :LsManager! include<CR>
noremap <buffer><silent> <S-F12>C :LsManager! constrained<CR>
noremap <buffer><silent> <S-F12>P :LsManager! parameter<CR>
noremap <buffer><silent> <S-F12>S :LsManager! set<CR>
noremap <buffer><silent> <S-F12>a :LsManager! airbag<CR>
noremap <buffer><silent> <S-F12>b :LsManager! boundary<CR>
noremap <buffer><silent> <S-F12>c :LsManager! contact<CR>
noremap <buffer><silent> <S-F12>dc :LsManager! define_curve<CR>
noremap <buffer><silent> <S-F12>dC :LsManager define_coordinate<CR>
noremap <buffer><silent> <S-F12>df :LsManager! define_friction<CR>
noremap <buffer><silent> <S-F12>dt :LsManager! define_transformation<CR>
noremap <buffer><silent> <S-F12>dv :LsManager! define_vector<CR>
noremap <buffer><silent> <S-F12>e :LsManager! element<CR>
noremap <buffer><silent> <S-F12>i :LsManager! include<CR>
noremap <buffer><silent> <S-F12>l :LsManager! load<CR>
noremap <buffer><silent> <S-F12>m :LsManager! mat<CR>
noremap <buffer><silent> <S-F12>n :LsManager! node<CR>
noremap <buffer><silent> <S-F12>p :LsManager! part<CR>
noremap <buffer><silent> <S-F12>s :LsManager! section<CR>
noremap <buffer><silent> <S-F12>x :LsManager! database_cross_section<CR>
noremap <buffer><silent><expr> <F12>/ ':LsManager '.input('LsManager ').'<CR>'
noremap <buffer><silent><expr> <S-F12>/ ':LsManager! '.input('LsManager ').'<CR>'
" tags
noremap <buffer><silent> <F11> :LsTags<CR>
noremap <buffer><silent> <S-F11> :LsTags!<CR>
" ls-dyna manuall
noremap <buffer><silent> <F1> :call lsdyna_manual#Manual(line('.'))<CR>

"-------------------------------------------------------------------------------
"    COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -nargs=? -bang LsTags
 \ :call lsdyna_tags#Lstags(<bang>0, <f-args>)

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

command! -buffer -nargs=? -bang -complete=file LsCurveWrite
 \ :call lsdyna_curve#curve2xydata(<bang>0, <f-args>)

command! -buffer -range -nargs=* LsNodeScale
 \ :call lsdyna_node#Scale(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeTranslate
 \ :call lsdyna_node#Transl(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodeRotate
 \ :call lsdyna_node#Rotate(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* LsNodePos6p
 \ :call lsdyna_node#Pos6p(<line1>,<line2>,<f-args>)

command! -buffer -nargs=+ -range -complete=file LsNodeReplace
 \ :call lsdyna_node#ReplaceNodes(<line1>,<line2>,<range>,<f-args>)

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

command! -buffer -range -nargs=0 LsEncryptLines
 \ :call lsdyna_encryption#EncryptLines(<line1>,<line2>,<f-args>)

command! -buffer -range -nargs=* -complete=file LsEncryptFile
 \ :call lsdyna_encryption#EncryptFile(<f-args>)

command! -buffer -nargs=+ -bang LsManager
 \ :call lsdyna_manager#Manager(<bang>0, <f-args>)

command! -buffer -nargs=1 LsManual
 \ :call lsdyna_manual#Manual(<f-args>)

" abbreviations for commonly used commands
cnoreabbrev lcs LsCurveScale
cnoreabbrev lco LsCurveOffset
cnoreabbrev lcr LsCurveResample
cnoreabbrev lca LsCurveAddPoint
cnoreabbrev lcm LsCurveMirror
cnoreabbrev lcc LsCurveCut
cnoreabbrev lcw LsCurveWrite
cnoreabbrev lcw! LsCurveWrite!
cnoreabbrev lns LsNodeScale
cnoreabbrev lnt LsNodeTranslate
"cnoreabbrev lnr LsNodeRotate
cnoreabbrev lnr LsNodeReplace
cnoreabbrev lnp LsNodePos6p
cnoreabbrev lnm LsNodeMirror
cnoreabbrev lec LsElemChangePid
cnoreabbrev lef LsElemFindPid
cnoreabbrev ler LsElemReverseNormals
cnoreabbrev lm LsManager
cnoreabbrev lm! LsManager!
cnoreabbrev lt LsTags
cnoreabbrev lt! LsTags!
cnoreabbrev lh LsManual

"-------------------------------------------------------------------------------
"    GLOBAL PLUGIN SETTINGS
"-------------------------------------------------------------------------------

" plugin paths
if !exists("g:lsdynaPathTags")     | let g:lsdynaPathTags     = $VIMHOME."/.dtags"                                       | endif
if !exists("g:lsdynaPathKeywords") | let g:lsdynaPathKeywords = expand('<sfile>:p:h:h') . '/keywords/'                   | endif
if !exists("g:lsdynaPathKvars")    | let g:lsdynaPathKvars    = expand('<sfile>:p:h:h') . '/keywords/dynaKvars.dat'      | endif
if !exists("g:lsdynaPathHeaders")  | let g:lsdynaPathHeaders  = expand('<sfile>:p:h:h') . '/keywords/dynaTagHeaders.dat' | endif
if !exists("g:lsdynaPathManual")   | let g:lsdynaPathManual   = expand('<sfile>:p:h:h') . '/manuals/'                     | endif
if !exists("g:lsdynaPathAcrobat")  | let g:lsdynaPathAcrobat  = '"C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"' | endif

" plugin variables
if !exists("g:lsdynaLibKeywords")  | let g:lsdynaLibKeywords  = lsdyna_complete#libKeywords(g:lsdynaPathKeywords) | endif
if !exists("g:lsdynaLibHeaders")   | let g:lsdynaLibHeaders   = lsdyna_complete#libHeaders(g:lsdynaPathHeaders)   | endif
if !exists("g:lsdynaKvars")        | let g:lsdynaKvars        = lsdyna_kvars#kvars(g:lsdynaPathKvars)             | endif
if !exists("b:lsdynaCompleteType") | let b:lsdynaCompleteType = 'none'                                            | endif

"-------------------------------------------------------------------------------
"    COMPLETION
"-------------------------------------------------------------------------------

" set omni completion functions
setlocal omnifunc=lsdyna_complete#LsdynaComplete
" completion mappings
inoremap <C-Tab> <C-X><C-O>
nnoremap <C-Tab> :call lsdyna_complete#extendLine()<CR>R<C-X><C-O>
inoremap <buffer><silent><expr> <CR>     lsdyna_complete#LsDynaMapEnter()
inoremap <buffer><silent><expr> <kEnter> lsdyna_complete#LsDynaMapEnter()

"-------------------------------------------------------------------------------
"    ENCRYPTION
"-------------------------------------------------------------------------------

if !exists("g:lsdynaEncryptCommand")
  let g:lsdynaEncryptCommand = "gpg --encrypt --armor --rfc2440 --trust-model always --textmode --cipher-algo AES --compress-algo 0 --recipient LSTC"
endif

"-------------------------------------------------------------------------------
"    LS MANAGER
"-------------------------------------------------------------------------------

if !exists('g:lsdyna_manager_qflist_old') | let g:lsdyna_manager_qflist_old = [] | endif
if !exists('g:lsdyna_manager_qflist_includes_old') | let g:lsdyna_manager_qflist_includes_old = [] | endif

"-------------------------------------------------------------------------------

" restore vim functions
let &cpo = s:cpo_save

"-------------------------------------EOF---------------------------------------
