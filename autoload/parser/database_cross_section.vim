"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  13.11.2019
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

function! parser#database_cross_section#Database_cross_section() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *DATABASE_CROSS_SECTION keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of dbcs objects base on keyword object.
  " Members:
  " - self.xxxx  : inherit from parent class
  " - self.id    : kword id
  " - self.title : kword title
  " - self.lnum  : line number with id
  " Methods:
  " - self.xxxx() : inherit from parent class
  " - self.Qf()   : set quickfix dictionary
  " - self.Tag()  : set tag file line
  " - self.Omni() : set omni-completion dictionary
  "-----------------------------------------------------------------------------

  " members and methods starting with '_' will not be inherit
  call filter(self, 'v:key[0] != "_"')

  " list to store all sections
  let dbcss = []

  "-----------------------------------------------------------------------------
  if self.type ==? 'CROSS_SECTION_PLANE'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let dbcs       = copy(self)
          let dbcs.id    = ''
          let dbcs.title = ''
          let dbcs.lnum  = dbcs.first + lcount
        elseif dlcount == 2
          let dbcs.Qf    = function('<SID>Qf')
          let dbcs.Tag   = function('<SID>Tag')
          let dbcs.Omni  = function('<SID>Omni')
          let dbcs.SetTitle = function('<SID>SetTitle')
          call add(dbcss, dbcs)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'CROSS_SECTION_PLANE_ID'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let dbcs       = copy(self)
          let dbcs.id    = str2nr(line[:9])
          let dbcs.title = trim(line[10:])
          let dbcs.lnum  = dbcs.first + lcount
        elseif dlcount == 2
          continue
        elseif dlcount == 3
          let dbcs.Qf    = function('<SID>Qf')
          let dbcs.Tag   = function('<SID>Tag')
          let dbcs.Omni  = function('<SID>Omni')
          let dbcs.SetTitle = function('<SID>SetTitle')
          call add(dbcss, dbcs)
          let dlcount = 0
        endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'CROSS_SECTION_SET'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dbcs       = copy(self)
        let dbcs.id    = ''
        let dbcs.title = ''
        let dbcs.lnum  = dbcs.first + lcount
        let dbcs.Qf    = function('<SID>Qf')
        let dbcs.Tag   = function('<SID>Tag')
        let dbcs.Omni  = function('<SID>Omni')
        let dbcs.SetTitle = function('<SID>SetTitle')
        call add(dbcss, dbcs)

      endif
    endfor

  "-----------------------------------------------------------------------------
  elseif self.type ==? 'CROSS_SECTION_SET_ID'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'

        let dlcount += 1
        if dlcount == 1
          let dbcs       = copy(self)
          let dbcs.id    = str2nr(line[:9])
          let dbcs.title = trim(line[10:])
          let dbcs.lnum  = dbcs.first + lcount
        elseif dlcount == 2
          let dbcs.Qf    = function('<SID>Qf')
          let dbcs.Tag   = function('<SID>Tag')
          let dbcs.Omni  = function('<SID>Omni')
          let dbcs.SetTitle = function('<SID>SetTitle')
          call add(dbcss, dbcs)
          let dlcount = 0
        endif

      endif
    endfor

  endif

  return dbcss

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
  "   Generate omni complete item base on kword
  " Returns:
  "   Tag string
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

  let tag = self.id."\t".self.file."\t".self.lnum.";\"\tkind:DATABASE_CROSS_SECTION\ttitle:".self.title
  return tag

endfunction

function! s:SetTitle(title) dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Set a new title for *DATABASE_CROSS_SECTION keyword.
  "-----------------------------------------------------------------------------

  if self.type =~? '_ID'  
    for i in range(1, len(self.lines)-1)
      if self.lines[i][0] != '$'
        let self.lines[i] = self.lines[i][:9] . a:title
        let self.title = a:title
        break
      endif
    endfor
  endif

endfunction

"-------------------------------------EOF---------------------------------------
