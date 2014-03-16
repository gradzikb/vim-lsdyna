"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  1st of March 2014
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
  " serach next keword
  let res = search(reKeyWord, 'W')
  " go to the ond of file if you did not find the keyword
  if res == 0
    normal! G
  endif
  " move back to first data line
  call search(reDataLine,'bW')

endfunction

"-------------------------------------------------------------------------------
"    LINE FORMATING
"-------------------------------------------------------------------------------

" data line format
noremap <buffer><script><silent> <LocalLeader><LocalLeader> :call <SID>LsDynaLine()<CR>

function! s:LsDynaLine() range

  " find keyword
  call search('^\*[a-zA-Z]','b')
  let keyword = getline('.')

  "-----------------------------------------------------------------------------
  if keyword =~? "*DEFINE_CURVE"

    let line = getline(a:firstline)
    let lenLine = len(split(line, '\s*,\s*\|\s\+'))

    " format 8x10 (first line under the keyword)
    if lenLine !=2 && line !~ ","

      let oneline = split(getline(a:firstline))
      for j in range(len(oneline))
        let oneline[j] = printf("%10s", oneline[j])
      endfor
      call setline(a:firstline, join(oneline, ""))
      call cursor(a:firstline, 0)

    " format 2x20
    else

      " get all lines with points
      let points = []
      for i in range(a:firstline, a:lastline)
        let points = points + split(getline(i), '\s*,\s*\|\s\+')
      endfor

      " remove old lines
      execute a:firstline . "," . a:lastline . "delete"
      normal! k

      " save new lines
      for i in range(0, len(points)-1, 2)
        let newLine = printf("%20s%20s", points[i], points[i+1])
        normal! o
        call setline(".", newLine)
      endfor

      call cursor(a:firstline+1, 0)

    endif

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*NODE"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        let newLine = printf("%8s%16s%16s%16s",line[0],line[1],line[2],line[3])
        call setline(i, newLine)
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT_SHELL"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        for j in range(len(line))
          let line[j] = printf("%8s", line[j])
        endfor
        call setline(i, join(line, ""))
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  " standart format line (8x10)
  " allow to use coma as empty col
  else

    for i in range(a:firstline, a:lastline)
      let line = split(getline(i))
      for j in range(len(line))
        let fStr = "%10s"
        if line[j] =~# ","
          if len(line[j]) !=# 1
            let fStr = "%" . line[j][:-2] . "0s"
          endif
          let line[j] = printf(fStr, "")
        else
          let line[j] = printf(fStr, line[j])
        endif
      endfor
      call setline(i, join(line, ""))
    endfor
    call cursor(a:lastline+1, 0)

  endif
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

" act <up> and <down> like Ctrl-p and Ctrl-n
" it has nothing to do with keyword library, it's only because I like it
inoremap <buffer><silent><script><expr> <Down> pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <buffer><silent><script><expr> <Up>   pumvisible() ? "\<C-p>" : "\<Up>"

" mapping for <CR>/<C-Y>
" if g:lsDynaUserComp is true run GetCompletion function
" if g:lsDynaUserComp is false act like <CR>/<C-Y>
inoremap <buffer><silent><script><expr> <CR>
 \ b:lsDynaUserComp ? "\<ESC>:call \<SID>GetCompletion()\<CR>" : "\<CR>"
inoremap <buffer><silent><script><expr> <C-Y>
 \ b:lsDynaUserComp ? "\<ESC>:call \<SID>GetCompletion()\<CR>" : "\<C-Y>"

" set user completion function to run with <C-X><C-U>
setlocal completefunc=LsDynaCompleteKeywords

" user completion function
function! LsDynaCompleteKeywords(findstart, base)

  " run for first function call
  if a:findstart

    " find completion start
    if getline('.')[0] == "*"
      return 1
    else
      return 0
    endif

  else

    " get list of files in the library
    let keylibrary = split(globpath(g:lsdynaKeyLibPath, '*'))
    " keep only file names
    call map(keylibrary, 'fnamemodify(v:val, ":t")')

    " completion loop
    let compKeywords = []
    for key in keylibrary
      if key =~? '^' . a:base
        call add(compKeywords, key)
      endif
    endfor

    " set completion flag
    let b:lsDynaUserComp = 1
    " return list after completion
    return compKeywords

  endif
endfunction

" function to get keyword and insert it from library
function! s:GetCompletion()

    " get keyword from current line
    if getline('.')[0] == "*"
      let keyword = tolower(strpart(getline('.'), 1))
    else
      let keyword = tolower(strpart(getline('.'), 0))
    endif
    " set keyword file path
    let file = g:lsdynaKeyLibPath . keyword

    " check if the file exist and put it
    if filereadable(file)
     execute "read " . file
     normal! kdd
    else
      normal! <C-Y>
    endif

    " reset completion flag
    let b:lsDynaUserComp = 0

endfunction

"-------------------------------------------------------------------------------
"    CURVE COMMANDS
"-------------------------------------------------------------------------------

command! -buffer -range -nargs=* LsDynaShift :call lsdyna_crvs#Offset(<line1>,<line2>,<f-args>)
command! -buffer -range -nargs=* LsDynaScale :call lsdyna_crvs#Scale(<line1>,<line2>,<f-args>)
command! -buffer -range -nargs=* LsDynaResample :call lsdyna_crvs#Resample(<line1>,<line2>,<f-args>)
command! -buffer -range -nargs=* LsDynaAddPoint :call lsdyna_crvs#AddPoint(<line1>,<line2>,<f-args>)

"-------------------------------------------------------------------------------
" restore vim functions
let &cpo = s:cpo_save

"-------------------------------------EOF---------------------------------------
