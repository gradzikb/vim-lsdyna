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

"-------------------------------------------------------------------------------
"    CLASS
"-------------------------------------------------------------------------------

function! parser#include#Include() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *INCLUDE object.
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
  " Methods:
  " - Qf() : create representation used with setqflist()
  " Comment:
  "   Multi line entries are not supported.
  "   I assume 1st not comment line after *INCLUDE has path
  "   Multi line paths (' +' at the end) are supported.
  "-----------------------------------------------------------------------------

  let path = ''

  " join path, ' +' at the end
  for line in self.Datalines()[1:]
    if line =~? ' +\s*$'
      let path = path . s:Trim(line)[0:-3]
    else
      let path = path . s:Trim(line)
      break
    endif
  endfor

  " resolve path
  let file  = lsdyna_include#Resolve(path)

  " find path line number
  let lnum = 0
  for line in self.lines[1:]
    let lnum += 1
    if line[0] != '$'
      break
    endif
  endfor

  " get rid of members which are not inherit
  call filter(self, 'v:key[0] != "_"')

  " include object
  let incl       = copy(self)
  let incl.lnum  = incl.first + lnum
  let incl.path  = file.path
  let incl.read  = file.read
  let incl.Qf    = function('<SID>Qf')
  let incl.Tag   = function('<SID>Tag')

  return [incl]

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
    let qf.col   = 1
    let qf.text  = 'include'.'|'.self.name.'|'.self.type.'|'.fnamemodify(self.path,':t').'|'.self.read.'|'.self.file

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

"-------------------------------------EOF---------------------------------------
