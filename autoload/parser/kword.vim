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
"    CLASS
"-------------------------------------------------------------------------------

function! parser#kword#Kword() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   General representation of any keyword.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of parts base on keyword object.
  " Members:
  " - self.xxxx  : inherit from parent class
  " - self.id    : kword id
  " - self.title : kword title
  " Methods:
  " - self.xxxx  : inherit from parent class
  " - self.Qf()  : set quickfix dictionary
  " - self.Tag() : set tag file line
  "-----------------------------------------------------------------------------

  " members and methods starting with '_' will not be inherit
  call filter(self, 'v:key[0] != "_"')

  " new members
  let self.id    = 0
  let self.title = ''
  let self.Qf    = function('<SID>Qf')
  let self.Tag   = function('<SID>Tag')

  return [self]

endfunction

"-------------------------------------------------------------------------------
"    METHODS
"-------------------------------------------------------------------------------

function! s:Qf() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Convert part object to quickfix item.
  " Returns:
  "   Quickfix list item (:help setqflist()).
  "-----------------------------------------------------------------------------

  let qf = {}
  let qf.bufnr = self.bufnr
  let qf.lnum  = self.first
  let qf.type  = 'U'
  "let qf.text  = self.name.'|'.self.hide
  let qftext = copy(self)
  call filter(qftext, 'type(v:val) != v:t_func') 
  call remove(qftext, 'lines')
  let qf.text  = string(qftext)

  return qf

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from part object.
  " Returns:
  "   Tag file line (:help tags-file-format).
  "-----------------------------------------------------------------------------
  "
  let tag = self.id."\t".self.file."\t".self.first.";\"\tkind:UNKNOWN\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
