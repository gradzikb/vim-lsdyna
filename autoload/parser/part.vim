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

function! parser#part#Part() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *PART keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of parts base on keyword object.
  " Members:
  " - self.xxxx   : inherit from parent class
  " - self.lnum   : line number with id
  " - self.id     : kword id
  " - self.title  : kword title
  " Methods:
  " - self.xxxx() : inherit from parent class
  " - self.Omni() : set omni-completion dictionary
  " - self.Qf()   : set quickfix dictionary
  " - self.Tag()  : set tag file line
  "-----------------------------------------------------------------------------

  " members and methods starting with '_' will not be inherit
  call filter(self, 'v:key[0] != "_"')

  " list store all part objects
  let parts = []

  "-----------------------------------------------------------------------------
  if self.type ==? ''

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let part       = copy(self)
          let part.title = trim(line)
        elseif dlcount == 2
          let part.id    = str2nr(line[:9])
          let part.lnum  = part.first + lcount
          let part.Qf    = function('<SID>Qf')
          let part.Tag   = function('<SID>Tag')
          let part.Omni  = function('<SID>Omni')
          call add(parts, part)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'CONTACT'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let part       = copy(self)
          let part.title = trim(line)
        elseif dlcount == 2
          let part.id   = str2nr(line[:9])
          let part.lnum = part.first + lcount
        elseif dlcount == 3
          let part.Qf    = function('<SID>Qf')
          let part.Tag   = function('<SID>Tag')
          let part.Omni  = function('<SID>Omni')
          call add(parts, part)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'INERTIA'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let part       = copy(self)
          let part.title = trim(line)
        elseif dlcount == 2
          let part.id   = str2nr(line[:9])
          let part.lnum = part.first + lcount
        elseif dlcount == 5
          let part.Qf    = function('<SID>Qf')
          let part.Tag   = function('<SID>Tag')
          let part.Omni  = function('<SID>Omni')
          call add(parts, part)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SENSOR'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let part       = copy(self)
        let part.title = ''
        let part.id    = str2nr(line[:9])
        let part.lnum  = part.first + lcount
        let part.Qf    = function('<SID>Qf')
        let part.Tag   = function('<SID>Tag')
        let part.Omni  = function('<SID>Omni')
        call add(parts, part)

      endif
    endfor
  endif

  return parts

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
  let qf.text  = 'id_title_type'.'|'.self.name.'|'.self.type.'|'.self.id.'|'.self.title

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

  let tag = self.id."\t".self.file."\t".self.lnum.";\"\tkind:PART\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
