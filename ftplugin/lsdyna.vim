"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  7th of January 2021
" Version:      2.0.0
"-------------------------------------------------------------------------------

" source guard
if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" compatibility option
let s:cpo_save = &cpo
set cpo&vim

"-------------------------------------------------------------------------------
"    GLOBAL VARIABLES
"-------------------------------------------------------------------------------

" path to Acrobat Reader exe file, used with :LsManual
if !exists("g:lsdynaPathAcrobat")
  let g:lsdynaPathAcrobat = '"C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe" /n'
endif
" command used for encryption
if !exists("g:lsdynaEncryptCommand")
  let g:lsdynaEncryptCommand = "gpg --encrypt --armor --rfc2440 --trust-model always --textmode --cipher-algo AES --compress-algo 0 --recipient LSTC"
endif
" completion keywords library
let b:lsdynaLibKeywordsPath = expand('<sfile>:p:h:h')..'/keywords/'
if exists('g:lsdynaLibKeywordsPath')
  let b:lsdynaLibKeywordsPath = b:lsdynaLibKeywordsPath..','..g:lsdynaLibKeywordsPath
endif
let b:lsdynaLibKeywords = lsdyna_complete#libKeywords(b:lsdynaLibKeywordsPath)
" path to directory with Ls-Dyna Manual PDF files
let g:lsdynaPathManual = expand('<sfile>:p:h:h')..'/manuals/'
" global dictionaries used with the plugin
source <sfile>:p:h:h/autoload/lsdyna_dict.vim
" turn on include path auto split function
if !exists("g:lsdynaInclPathAutoSplit")
  let g:lsdynaInclPathAutoSplit = 1
endif
" string used for comment
let g:lsdynaCommentString = '$-->'

"-------------------------------------------------------------------------------
"    COLORS
"-------------------------------------------------------------------------------

syntax on
colorscheme lsdyna

"-------------------------------------------------------------------------------
"    MAIN SETTINGS
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
setlocal listchars=tab:>-,trail:-
setlocal list
setlocal completeopt=menuone,noinsert
"setlocal completepopup=align:item,border:off
"setlocal quickfixtextfunc=lsdyna_manager#QfFormatLine
setlocal omnifunc=lsdyna_complete#Omnifunc
setlocal completefunc=lsdyna_complete#Completefunc
"setlocal formatexpr=lsdyna_misc#Format()
execute 'setlocal tags='..split(&rtp,',')[0]..'/.dtags'
highlight QuickFixLine guifg=NONE guibg=NONE

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
  autocmd VimEnter cd %:p:h
  autocmd BufWrite * set fileformat=unix
  "autocmd BufEnter * silent call lsdyna_tags#Lstags(0, '*')
  autocmd BufEnter * if empty(&filetype) | set filetype=lsdyna | endif
  autocmd CompleteDonePre * call lsdyna_complete#CompleteDone()
augroup END

augroup lsdyna-lsManager
  autocmd!
  " set Qf window look
  autocmd BufReadPost quickfix setlocal modifiable | silent call lsdyna_manager#QfWindow() | setlocal nomodifiable
  "autocmd FileType qf setlocal cursorline
  "autocmd FileType qf highlight QuickFixLine guifg=NONE guibg=NONE
  " focus view on quickfix item everytime a cursor is moved
  autocmd FileType qf autocmd CursorMoved <buffer> call lsdyna_manager#QfSetCursor()
augroup END

"-------------------------------------------------------------------------------
"    MAPPINGS
"-------------------------------------------------------------------------------

" change 4 -> '$' sign at the line beginning
inoreabbrev 4 <C-R>=(col('.')==1 ? '$' : 4)<CR>
" comment/uncomment line
noremap <silent><buffer> <M-c> :call lsdyna_misc#CommentLine()<CR>j
noremap <silent><buffer> <c-c> :call lsdyna_misc#CommentLine()<CR>j
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
nnoremap <C-w>] <C-w>g}
nnoremap <c-leftmouse> g<c-]>
" check includes before write
command! -nargs=0 -bang W call lsdyna_include#Quit(<bang>0, "w")
command! -nargs=0 -bang WQ call lsdyna_include#Quit(<bang>0, "wq")
cnoreabbrev <expr> w  (getcmdtype()==':' && getcmdline()== 'w') ?  'W' :  'w'
cnoreabbrev <expr> wq (getcmdtype()==':' && getcmdline()=='wq') ? 'WQ' : 'wq'
" autoformat function
"noremap <buffer><script><silent> <LocalLeader><LocalLeader> :call lsdyna_autoformat#Autoformat()<CR>
noremap <buffer><script><silent> = :call lsdyna_autoformat#Autoformat()<CR>
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
" keyword text objects
vnoremap <buffer><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
onoremap <buffer><silent> ak :call lsdyna_misc#KeywordTextObject()<CR>
" ls-dyna manuall
noremap <buffer><silent> <F1> :call lsdyna_manual#Manual(line('.'))<CR>
" tags
noremap <buffer><silent> <F11> :LsTags<CR>
noremap <buffer><silent> <S-F11> :LsTags!<CR>
" LsManager mappings (F12)
noremap <buffer><silent> <F12>* :LsManager *<CR>
noremap <buffer><silent> <F12>. :call lsdyna_manager#QfOpen(g:lsdyna_qfid_last, 0)<CR>
noremap <buffer><silent> <F12><C-s> :LsManager sensor<CR>
noremap <buffer><silent> <F12><F12> :LsManager include<CR>
noremap <buffer><silent> <F12>C :LsManager constrained<CR>
noremap <buffer><silent> <F12>I :call lsdyna_manager#QfOpen(g:lsdyna_qfid_lastIncl, 0)<CR>
noremap <buffer><silent> <F12>P :LsManager parameter<CR>
noremap <buffer><silent> <F12>S :LsManager set<CR>
noremap <buffer><silent> <F12>a :LsManager airbag<CR>
noremap <buffer><silent> <F12>b :LsManager boundary<CR>
noremap <buffer><silent> <F12>c :LsManager contact<CR>
noremap <buffer><silent> <F12>db :LsManager database<CR>
noremap <buffer><silent> <F12>dC :LsManager define_coordinate<CR>
noremap <buffer><silent> <F12>dc :LsManager define_curve<CR>
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
noremap <buffer><silent> <F12>x :LsManager database_cross_section<CR>
noremap <buffer><silent><expr> <F12>/ ':LsManager '.input('LsManager ').'<CR>'
" LsManager mappings (S-F12)
noremap <buffer><silent> <S-F12>* :LsManager! *<CR>
noremap <buffer><silent> <S-F12><F12> :LsManager! include<CR>
noremap <buffer><silent> <S-F12><S-F12> :LsManager! include<CR>
noremap <buffer><silent> <S-F12>C :LsManager! constrained<CR>
noremap <buffer><silent> <S-F12>P :LsManager! parameter<CR>
noremap <buffer><silent> <S-F12>S :LsManager! set<CR>
noremap <buffer><silent> <S-F12>a :LsManager! airbag<CR>
noremap <buffer><silent> <S-F12>b :LsManager! boundary<CR>
noremap <buffer><silent> <S-F12>c :LsManager! contact<CR>
noremap <buffer><silent> <S-F12>db :LsManager! database<CR>
noremap <buffer><silent> <S-F12>dC :LsManager! define_coordinate<CR>
noremap <buffer><silent> <S-F12>dc :LsManager! define_curve<CR>
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
noremap <buffer><silent><expr> <S-F12>/ ':LsManager! '.input('LsManager ').'<CR>'

"-------------------------------------------------------------------------------
"    COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -nargs=? -bang LsTags
 \ :call lsdyna_tags#Lstags(<bang>0, <f-args>)
cnoreabbrev lt LsTags
cnoreabbrev lt! LsTags!

command! -buffer -range -nargs=* LsCurveOffset
 \ :call lsdyna_curve#Offset(<line1>,<line2>,<f-args>)
cnoreabbrev lco LsCurveOffset

command! -buffer -range -nargs=* LsCurveScale
 \ :call lsdyna_curve#Scale(<line1>,<line2>,<f-args>)
cnoreabbrev lcs LsCurveScale

command! -buffer -range -nargs=0 LsCurveMirror
 \ :call lsdyna_curve#Mirror(<line1>,<line2>)
cnoreabbrev lcm LsCurveMirror

command! -buffer -range -nargs=* LsCurveCut
 \ :call lsdyna_curve#Cut(<line1>,<line2>,<f-args>)
cnoreabbrev lcc LsCurveCut

command! -buffer -range -nargs=* LsCurveResample
 \ :call lsdyna_curve#Resample(<line1>,<line2>,<f-args>)
cnoreabbrev lcr LsCurveResample

command! -buffer -range -nargs=1 LsCurveAddPoint
 \ :call lsdyna_curve#Addpoint(<line1>,<line2>,<f-args>)
cnoreabbrev lca LsCurveAddPoint

command! -buffer -nargs=? -bang -complete=file LsCurveWrite
 \ :call lsdyna_curve#curve2xydata(<bang>0, <f-args>)
cnoreabbrev lcw LsCurveWrite
cnoreabbrev lcw! LsCurveWrite!

command! -buffer -range -nargs=* LsNodeScale
 \ :call lsdyna_node#Scale(<line1>,<line2>,<f-args>)
cnoreabbrev lns LsNodeScale

command! -buffer -range -nargs=* LsNodeTranslate
 \ :call lsdyna_node#Transl(<line1>,<line2>,<f-args>)
cnoreabbrev lnt LsNodeTranslate

command! -buffer -range -nargs=* LsNodeRotate
 \ :call lsdyna_node#Rotate(<line1>,<line2>,<f-args>)
cnoreabbrev lnR LsNodeRotate

command! -buffer -range -nargs=* LsNodePos6p
 \ :call lsdyna_node#Pos6p(<line1>,<line2>,<f-args>)
cnoreabbrev lnp LsNodePos6p

command! -buffer -nargs=+ -range -complete=file LsNodeReplace
 \ :call lsdyna_node#ReplaceNodes(<line1>,<line2>,<range>,<f-args>)
cnoreabbrev lnr LsNodeReplace

command! -buffer -range -nargs=* LsNodeMirror
 \ :call lsdyna_node#Mirror(<line1>,<line2>,<f-args>)
cnoreabbrev lnm LsNodeMirror

command! -buffer -range -nargs=* LsElemFindPid
 \ :call lsdyna_element#FindPid(<line1>,<line2>,<f-args>)
cnoreabbrev lef LsElemFindPid

command! -buffer -range -nargs=* LsElemChangePid
 \ :call lsdyna_element#ChangePid(<line1>,<line2>,<f-args>)
cnoreabbrev lec LsElemChangePid

command! -buffer -range -nargs=0 LsElemReverseNormals
 \ :call lsdyna_element#ReverseNormals(<line1>,<line2>)
cnoreabbrev ler LsElemReverseNormals

command! -buffer -range -nargs=+ LsOffsetId
 \ :call lsdyna_offset#Offset(<line1>,<line2>,<f-args>)
cnoreabbrev loi LsOffsetId

command! -buffer -range -nargs=* LsEncryptLines
 \ :call lsdyna_encryption#EncryptLines(<line1>,<line2>,<f-args>)
cnoreabbrev lel LsEncryptLines

command! -buffer -range -nargs=* -complete=file LsEncryptFile
 \ :call lsdyna_encryption#EncryptFile(<f-args>)
"cnoreabbrev lef LsEncryptFile

command! -buffer -nargs=1 -bang LsManager
 \ :call lsdyna_manager#Manager(<bang>0, <f-args>)
cnoreabbrev lm LsManager
cnoreabbrev lm! LsManager!

command! -buffer -nargs=1 LsManual
 \ :call lsdyna_manual#Manual(<f-args>)

command! -buffer -range -nargs=? -bang LsKwordDelete
 \ :call lsdyna_misc#KwordDelete(<bang>0, <range>, <line1>, <line2>, <f-args>)
cnoreabbrev lkd LsKwordDelete
cnoreabbrev lkd! LsKwordDelete!

command! -buffer -range -nargs=? -bang LsKwordComment
 \ :call lsdyna_misc#KwordComment(<bang>0, <range>, <line1>, <line2>, <f-args>)
cnoreabbrev lkc LsKwordComment
cnoreabbrev lkc! LsKwordComment!

command! -buffer -nargs=+ -range=% LsMakeMarkers
 \ :call lsdyna_misc#MakeMarkers(<line1>, <line2>, <f-args>)
cnoreabbrev lmm LsMakeMarkers

command! -buffer -nargs=1 LsCmdExec
 \ :call lsdyna_misc#KwordExecCommand(<f-args>)
cnoreabbrev lce LsCmdExec

command! -buffer -nargs=? -bang LsInclComment
 \ :call lsdyna_include#CommentIncludes(<bang>0, <f-args>)
cnoreabbrev lic LsInclComment
cnoreabbrev lic! LsInclComment!

command! -buffer -range -nargs=1 LsElemFormat
 \ :call lsdyna_element#ConvertI8I10(<line1>,<line2>,<f-args>)
cnoreabbrev leF LsElemFormat

command! -buffer -range -nargs=1 LsNodeFormat
 \ :call lsdyna_node#ConvertI8I10(<line1>,<line2>,<f-args>)
cnoreabbrev lnf LsNodeFormat

"-------------------------------------------------------------------------------
"    COMPLETION
"-------------------------------------------------------------------------------

" omni-completion
inoremap <Tab> <ESC>:<C-u>call lsdyna_complete#OmnifunctPre('')<CR>a<C-x><C-o>
nnoremap <Tab> :<C-u>call lsdyna_complete#OmnifunctPre('')<CR>:<C-u>call lsdyna_complete#extendLine()<CR>s<C-x><C-o>
inoremap <S-Tab> <ESC>:<C-u>call lsdyna_complete#OmnifunctPre('i')<CR>a<C-x><C-o>
nnoremap <S-Tab> :<C-u>call lsdyna_complete#OmnifunctPre('i')<CR>:<C-u>call lsdyna_complete#extendLine()<CR>s<C-x><C-o>

inoremap <C-Tab> <ESC>:<C-u>call lsdyna_complete#OmnifunctPre('i')<CR>a<C-x><C-o>
inoremap <C-Tab> :<C-u>call lsdyna_complete#OmnifunctPre('i')<CR>:<C-u>call lsdyna_complete#extendLine()<CR>s<C-x><C-o>

" mappings below olways works in terminal
inoremap <C-x><c-o> <ESC>:<C-u>call lsdyna_complete#OmnifunctPre('')<CR>a<C-x><C-o>
nnoremap <C-x><c-o> :<C-u>call lsdyna_complete#OmnifunctPre('')<CR>:<C-u>call lsdyna_complete#extendLine()<CR>s<C-x><C-o>
inoremap <C-x><C-q> <ESC>:<C-u>call lsdyna_complete#OmnifunctPre('i')<CR>a<C-x><C-o>
nnoremap <C-x><C-q> :<C-u>call lsdyna_complete#OmnifunctPre('i')<CR>:<C-u>call lsdyna_complete#extendLine()<CR>s<C-x><C-o>

" user filename completion
"inoremap <C-x><c-f> <ESC>:<C-u>call lsdyna_complete#CompletefuncPre()<CR>A<C-x><C-u>
inoremap <expr> <C-x><C-f> getline('.')[0]=='$' ? '<C-x><C-f>' : '<ESC>:<C-u>call lsdyna_complete#CompletefuncPre()<CR>A<C-x><C-u>'

"-------------------------------------------------------------------------------

" restore vim functions
let &cpo = s:cpo_save

"-------------------------------------EOF---------------------------------------
