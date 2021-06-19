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

function! parser#define_vector#Define_vector() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *DEFINE_VECTOR keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of define_vector objects base on keyword object.
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

  " list to store all keywords objects
  let vects = []

  if self.type ==? 'VECTOR'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

          let vect       = copy(self)
          let vect.title = ''
          let vect.id    = str2nr(line[:9])
          let vect.lnum  = vect.first + lcount
          let vect.Qf    = function('<SID>Qf')
          let vect.Tag   = function('<SID>Tag')
          let vect.Omni  = function('<SID>Omni')
          call add(vects, vect)
          let dlcount = 0

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'VECTOR_TITLE'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let vect       = copy(self)
          let vect.title = trim(line)
        elseif dlcount == 2
          let vect.id    = str2nr(line[:9])
          let vect.lnum  = vect.first + lcount
          let vect.Qf    = function('<SID>Qf')
          let vect.Tag   = function('<SID>Tag')
          let vect.Omni  = function('<SID>Omni')
          call add(vects, vect)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'VECTOR_NODES'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

          let vect       = copy(self)
          let vect.title = ''
          let vect.id    = str2nr(line[:9])
          let vect.lnum  = vect.first + lcount
          let vect.Qf    = function('<SID>Qf')
          let vect.Tag   = function('<SID>Tag')
          let vect.Omni  = function('<SID>Omni')
          call add(vects, vect)
          let dlcount = 0

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'VECTOR_NODES_TITLE'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let vect       = copy(self)
          let vect.title = trim(line)
        elseif dlcount == 2
          let vect.id    = str2nr(line[:9])
          let vect.lnum  = vect.first + lcount
          let vect.Qf    = function('<SID>Qf')
          let vect.Tag   = function('<SID>Tag')
          let vect.Omni  = function('<SID>Omni')
          call add(vects, vect)
          let dlcount = 0
        endif

      endif
    endfor

  endif

  return vects

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
  let qf.lnum  = self.lnum
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

  let tag = self.id."\t".self.file."\t".self.lnum.";\"\tkind:DEFINE_VECTOR\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
