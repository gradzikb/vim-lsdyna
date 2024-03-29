"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  23.10 2019
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
"    LOCAL FUNCTIONS
"-------------------------------------------------------------------------------

function! s:Trim(string)

  "-----------------------------------------------------------------------------
  " Function to trim empty signs on string
  "-----------------------------------------------------------------------------

  let string = substitute(a:string,'^\s\+','','')
  let string = substitute(string,'\s\+$','','')
  return string

endfunction

function! s:Slash(path, sign)

  "-----------------------------------------------------------------------------
  " Function to set path separators
  "-----------------------------------------------------------------------------

  if a:sign == 'u'
    let path = substitute(a:path,'\','/','g')
  elseif a:sign ='w'
    let path = substitute(a:path,'/','\','g')
  endif
  return path

endfunction

"-------------------------------------------------------------------------------
"    CLASS
"-------------------------------------------------------------------------------

function! parser#include_path#Include_path() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *INCLUDE_PATH object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of include objects base on keyword object.
  " Members:
  " - self.first : kword 1st line number
  " - self.last  : kword last line number
  " - self.bufnr : buffer number
  " - self.file  : full file path
  " - self.name  : kword name
  " - self.type  : kword type
  " - self.path  : include file path
  " - self.read  : read status
  " - self.lnum  : include file path line number
  " - self.lvl   : include tree level
  " Methods:
  " - Qf() : create representation used with setqflist()
  " Comment:
  "   Multi line entries are not supported.
  "   I assume 1st not comment line after *INCLUDE has path
  "   Multi line paths (' +' at the end) are supported.
  "-----------------------------------------------------------------------------

  let path = ''
  let incls = []

  for i in range(1, len(self.lines)-1)

    " comment line
    if self.lines[i][0] ==? '$' 
      continue
    endif

    let pathlnum1 = empty(path) ? i : pathlnum1 " line offset from kword line where path start

    " include path (partial or full)
    if self.lines[i] =~? ' +\s*$'
      let path ..= self.lines[i][:-3]->trim()
      continue
    else
      let path ..= self.lines[i]->trim() 
    endif

    let pathlnum2 = i                           " line offset from kword line where path end

    " include object
    call filter(self, 'v:key[0] != "_"') " clean up abstract class
    let incl = copy(self)
    " members
    let incl.path      = path
    let incl.pathraw   = path
    let incl.lnum      = incl.first + pathlnum2
    let incl.pathlnum1 = pathlnum1
    let incl.pathlnum2 = pathlnum2
    let incl.read      = <SID>IsDirectory(path)
    " methods 
    let incl.Qf      = function('<SID>Qf')
    let incl.Tag     = function('<SID>Tag')
    let incl.SetPath = function('parser#include#SetPath')
    call add(incls, incl)

    let path = ''

  endfor

  return incls

endfunction

"-------------------------------------------------------------------------------
"    METHODS
"-------------------------------------------------------------------------------

function! s:Qf() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Convert kword object to quickfix item.
  " Returns:
  "   Quickfix list item (dict, see :help setqflist())
  "   - self.bufnr : buffer number
  "   - self.lnum  : part id line number
  "   - self.col   : column cursor position
  "   - self.text  : kword_name|kword_type|kword_id|kword_title
  "-----------------------------------------------------------------------------

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.lnum
    let qf.type  = 'I'
    let qf.col   = 1
    "let qf.text  = fnamemodify(self.path,':h:t').'|'.self.read.'|'.self.type.'|'.self.file.'|'.self.hide
    let qftext = copy(self)
    call filter(qftext, 'type(v:val) != v:t_func') 
    call remove(qftext, 'lines')
    let qf.text  = string(qftext)

  return qf

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from include object.
  " Returns:
  "   Tag string
  "-----------------------------------------------------------------------------

  let tag = fnamemodify(self.path,':p:t')."\t".self.file."\t".self.lnum.";\"\tkind:INCLUDE\ttitle:"
  return tag

endfunction

function! s:IsDirectory(path)

  "-----------------------------------------------------------------------------
  " Method:
  "   ?
  " Returns:
  "   ?
  "-----------------------------------------------------------------------------

  if has('win32') || has('win64')
    " when I am on Windows I ignore linux absolute path
    if a:path[0] == '/'
      return -1
    endif
  else
    " when I am on Linux I ignore Windows absolute path
    if a:path[0] == '\' || a:path[0:1] =~? '\a:'
      return -1
    endif
  endif

  return isdirectory(a:path)

endfunction

"-------------------------------------EOF---------------------------------------
