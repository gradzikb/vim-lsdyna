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

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          "call add(lines, line)
          let part       = copy(self)
          let part.title = trim(line)
          "let part.title = part.hide ? g:lsdynaCommentString .. ' ' .. part.title : part.title
        elseif dlcount == 2
          "call add(lines, line)
          let part.id    = str2nr(line[:9])
          let part.lnum  = part.first + lcount
          let part.lines = lines
          let part.Qf    = function('<SID>Qf')
          let part.Tag   = function('<SID>Tag')
          let part.Omni  = function('<SID>Omni')
          call add(parts, part)
          let dlcount = 0
          let lines = [self.name] " set to only keyword name for another *Part instance
        endif
      "else
      "  call add(lines, line)
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'CONTACT'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let part       = copy(self)
          let part.title = trim(line)
          "let part.title = part.hide ? g:lsdynaCommentString .. ' ' .. part.title : part.title
        elseif dlcount == 2
          let part.id   = str2nr(line[:9])
          let part.lnum = part.first + lcount
        elseif dlcount == 3
          let part.lines = lines
          let part.Qf    = function('<SID>Qf')
          let part.Tag   = function('<SID>Tag')
          let part.Omni  = function('<SID>Omni')
          call add(parts, part)
          let dlcount = 0
          let lines = [self.name] " set to only keyword name for another *Part instance
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'INERTIA'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let part       = copy(self)
          let part.title = trim(line)
          "let part.title = part.hide ? g:lsdynaCommentString .. ' ' .. part.title : part.title
        elseif dlcount == 2
          let part.id   = str2nr(line[:9])
          let part.lnum = part.first + lcount
        elseif dlcount == 5
          let part.lines = lines
          let part.Qf    = function('<SID>Qf')
          let part.Tag   = function('<SID>Tag')
          let part.Omni  = function('<SID>Omni')
          call add(parts, part)
          let dlcount = 0
          let lines = [self.name] " set to only keyword name for another *Part instance
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SENSOR'

    let lines = [self.name]
    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let part       = copy(self)
        "let part.title = ''
        let part.title = ''
        "let part.title = part.hide ? g:lsdynaCommentString .. ' ' .. part.title : part.title
        let part.id    = str2nr(line[:9])
        let part.lnum  = part.first + lcount
        let part.lines = lines
        let part.Qf    = function('<SID>Qf')
        let part.Tag   = function('<SID>Tag')
        let part.Omni  = function('<SID>Omni')
        call add(parts, part)
        let lines = [self.name] " set to only keyword name for another *Part instance
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
  let item.info = join(self.lines, "\n")

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
