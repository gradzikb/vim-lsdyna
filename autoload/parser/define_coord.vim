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

function! parser#define_coord#Define_coord() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *DEFINE_COORDINATE keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of define_coord objects base on keyword object.
  " Members:
  " - self.xxxx  : inherit from parent class
  " - self.id    : kword id
  " - self.title : kword title
  " - self.lnum  : line number with id
  " Methods:
  " - self.xxxx() : inherit from parent class
  " - self.Omni() : set omni-completion dictionary
  " - self.Qf()   : set quickfix dictionary
  " - self.Tag()  : set tag file line
  "-----------------------------------------------------------------------------

  " get rid of members/mehods you do not want to inherit
  call filter(self, 'v:key[0] != "_"')

  " list to store all coordinate objects
  let coords = []

  "-----------------------------------------------------------------------------
  if self.type ==? 'COORDINATE_NODES'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

          let coord       = copy(self)
          let coord.title = ''
          let coord.id    = str2nr(line[:9])
          let coord.lnum  = coord.first + lcount
          let coord.Qf    = function('<SID>Qf')
          let coord.Tag   = function('<SID>Tag')
          let coord.Omni  = function('<SID>Omni')
          call add(coords, coord)
          let dlcount = 0

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'COORDINATE_NODES_TITLE'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let coord       = copy(self)
          let coord.title = trim(line)
        elseif dlcount == 2
          let coord.id    = str2nr(line[:9])
          let coord.lnum  = coord.first + lcount
          let coord.Qf    = function('<SID>Qf')
          let coord.Tag   = function('<SID>Tag')
          let coord.Omni  = function('<SID>Omni')
          call add(coords, coord)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'COORDINATE_SYSTEM'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let coord       = copy(self)
          let coord.title = ''
          let coord.id    = str2nr(line[:9])
          let coord.lnum  = coord.first + lcount
        elseif dlcount == 2
          let coord.Qf    = function('<SID>Qf')
          let coord.Tag   = function('<SID>Tag')
          let coord.Omni  = function('<SID>Omni')
          call add(coords, coord)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'COORDINATE_SYSTEM_TITLE'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let coord       = copy(self)
          let coord.title = trim(line)
        elseif dlcount == 2
          let coord.id    = str2nr(line[:9])
          let coord.lnum  = coord.first + lcount
        elseif dlcount == 3
          let coord.Qf    = function('<SID>Qf')
          let coord.Tag   = function('<SID>Tag')
          let coord.Omni  = function('<SID>Omni')
          call add(coords, coord)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'COORDINATE_VECTOR'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

          let coord       = copy(self)
          let coord.title = ''
          let coord.id    = str2nr(line[:9])
          let coord.lnum  = coord.first + lcount
          let coord.Qf    = function('<SID>Qf')
          let coord.Tag   = function('<SID>Tag')
          let coord.Omni  = function('<SID>Omni')
          call add(coords, coord)
          let dlcount = 0

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'COORDINATE_VECTOR_TITLE'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let coord       = copy(self)
          let coord.title = trim(line)
        elseif dlcount == 2
          let coord.id    = str2nr(line[:9])
          let coord.lnum  = coord.first + lcount
          let coord.Qf    = function('<SID>Qf')
          let coord.Tag   = function('<SID>Tag')
          let coord.Omni  = function('<SID>Omni')
          call add(coords, coord)
          let dlcount = 0
        endif

      endif
    endfor

  endif

  return coords

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
  "let item.dup  = 1

  return item

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from part object.
  " Returns:
  "   Tag file line (:help tags-file-format).
  "-----------------------------------------------------------------------------

  let tag = self.id."\t".self.file."\t".self.lnum.";\"\tkind:DEFINE_COORD\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
