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

function! parser#section#Section() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *SECTION keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of section base on keyword object.
  " Members:
  " - self.xxxx  : inherit from parent class
  " - self.lnum  : line number with id
  " - self.id    : kword id
  " - self.title : kword title
  " Methods:
  " - self.xxxx() : inherit from parent class
  " - self.Omni() : set omni-completion dictionary
  " - self.Qf()   : set quickfix dictionary
  " - self.Tag()  : set tag file line
  "-----------------------------------------------------------------------------

  " members and methods starting with '_' will not be inherit
  call filter(self, 'v:key[0] != "_"')

  " list to store all section objects
  let sects = []

  "-----------------------------------------------------------------------------
  if self.type ==? 'SOLID'

      let lines = [self.name]
      let lcount = 0
      for line in self.lines[1:]
        let lcount += 1
        call add(lines, line)
        if line[0] != '$'
          let sect       = copy(self)
          let sect.title = ''
          let sect.id    = str2nr(line[:9])
          let sect.lnum  = sect.first + lcount
          let sect.lines = lines
          let sect.Qf    = function('<SID>Qf')
          let sect.Tag   = function('<SID>Tag')
          let sect.Omni  = function('<SID>Omni')
          call add(sects, sect)
          let lines = [self.name]
        endif
      endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SOLID_TITLE'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = trim(line)
        elseif dlcount == 2
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SHELL'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = ''
          let sect.id    = str2nr(line[:9])
          let sect.lnum  = sect.first + lcount
          let icomp = str2nr(line[60:70])
          let dlcount_end = icomp ? 3 : 2
        elseif dlcount == dlcount_end
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SHELL_TITLE'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = trim(line)
        elseif dlcount == 2
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
          let icomp = str2nr(line[60:70])
          let dlcount_end = icomp ? 4 : 3
        elseif dlcount == dlcount_end
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'BEAM'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = ''
          let sect.id    = str2nr(line[:9])
          let sect.lnum  = sect.first + lcount
        elseif dlcount == 2
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'BEAM_TITLE'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = trim(line)
        elseif dlcount == 2
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
        elseif dlcount == 3
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'DISCRETE'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = ''
          let sect.id    = str2nr(line[:9])
          let sect.lnum  = sect.first + lcount
        elseif dlcount == 2
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'DISCRETE_TITLE'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = trim(line)
        elseif dlcount == 2
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
        elseif dlcount == 3
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SEATBELT'

    let lines = [self.name]
    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
        call add(lines, line)
      if line[0] != '$'
        let sect       = copy(self)
        let sect.title = ''
        let sect.id    = str2nr(line[:9])
        let sect.lnum  = sect.first + lcount
        let sect.lines = lines
        let sect.Qf    = function('<SID>Qf')
        let sect.Tag   = function('<SID>Tag')
        let sect.Omni = function('<SID>Omni')
        call add(sects, sect)
        let lines = [self.name]
      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'SEATBELT_TITLE'

    let lines = [self.name]
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      call add(lines, line)
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sect       = copy(self)
          let sect.title = trim(line)
        elseif dlcount == 2
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
          let sect.lines = lines
          let sect.Qf   = function('<SID>Qf')
          let sect.Tag  = function('<SID>Tag')
          let sect.Omni = function('<SID>Omni')
          call add(sects, sect)
          let dlcount = 0
          let lines = [self.name]
        endif
      endif
    endfor

  endif


  return sects

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
  let item.info = join(self.lines,"\n")
  return item

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from part object.
  " Returns:
  "   Tag file line (:help tags-file-format).
  "-----------------------------------------------------------------------------

  let tag = self.id."\t".self.file."\t".self.lnum.";\"\tkind:SECTION\ttitle:".self.title
  return tag

endfunction

"-------------------------------------EOF---------------------------------------
