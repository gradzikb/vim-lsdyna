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

function! parser#contact#Contact() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *CONTACT_ keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of contacts base on keyword object.
  " Members:
  " - self.xxxx  : inherit from parent class
  " - self.id    : kword id
  " - self.title : kword title
  " Methods:
  " - self.xxxx() : inherit from parent class
  " - self.Qf()   : set quickfix dictionary
  " - self.Tag()  : set tag file line
  "-----------------------------------------------------------------------------

  " members and methods starting with '_' will not be inherit
  call filter(self, 'v:key[0] != "_"')

  " local variables
  let datalines  = self.Datalines()

  " child class memebrs
  let self.id    = self.name =~? '_ID\|_TITLE' ? str2nr(datalines[1][:9]) : 0
  let self.title = self.name =~? '_ID\|_TITLE' ? trim(datalines[1][10:])  : ''
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
    let qf.type  = 'K'
    "let qf.text  = self.id.'|'.self.title.'|'.self.type.'|'.self.hide
    let qftext = copy(self)
    call filter(qftext, 'type(v:val) != v:t_func') 
    call remove(qftext, 'lines')
    let qf.text  = string(qftext)

  return qf

endfunction

"-------------------------------------------------------------------------------

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from part object.
  " Returns:
  "   Tag file line (:help tags-file-format).
  "-----------------------------------------------------------------------------

  let tag = self.id."\t".self.file."\t".self.first.";\"\tkind:CONTACT\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
