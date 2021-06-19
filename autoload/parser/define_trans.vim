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

function! parser#define_trans#Define_trans() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *DEFINE_TRANSFORMATION keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of define_transformation objects base on keyword object.
  " Members:
  " - self.xxxx  : inherit from parent class
  " - self.id    : kword id
  " - self.title : kword title
  " Methods:
  " - self.xxxx() : inherit from parent class
  " - self.Omni() : set omni-completion dictionary
  " - self.Qf()   : set quickfix dictionary
  " - self.Tag()  : set tag file line
  "-----------------------------------------------------------------------------

  " get rid of members/mehods you do not want to inherit
  call filter(self, 'v:key[0] != "_"')

  " local variables
  let datalines = self.Datalines()

  " new members
  let self.id    = self.name =~? 'TITLE' ? str2nr(datalines[2][:9]) : str2nr(datalines[1][:9])
  let self.title = self.name =~? 'TITLE' ? trim(datalines[1])       : ''
  let self.Qf    = function('<SID>Qf')
  let self.Tag   = function('<SID>Tag')
  let self.Omni  = function('<SID>Omni')

  return [self]

endfunction

"-------------------------------------------------------------------------------
"    METHODS
"-------------------------------------------------------------------------------

function! s:Qf() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Convert keyword object to quickfix item.
  " Returns:
  "   Quickfix list item (:help setqflist()).
  "-----------------------------------------------------------------------------

  let qf = {}
  let qf.bufnr = self.bufnr
  let qf.lnum  = self.first
  let qf.type  = 'K'
  "let qf.text  = self.id.'|'.self.title.'|'.self.type.'|'.self.hide
  let qftext = copy(self)
  call filter(qftext, 'type(v:val) != v:t_func') 
  call remove(qftext, 'lines')
  let qf.text  = string(qftext)

  return qf

endfunction

function! s:Omni() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate omni complete item base on kword.
  " Returns:
  "   Quickfix list item (:help complete-items).
  "-----------------------------------------------------------------------------

  let item = {}
  let item.word = printf("%10s", self.id)
  let item.menu = self.title
  let item.dup  = 1

  return item

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from part object.
  " Returns:
  "   Tag file line (:help tags-file-format).
  "-----------------------------------------------------------------------------

  let tag = self.id."\t".self.file."\t".self.first.";\"\tkind:DEFINE_TRANSFORMATION\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
