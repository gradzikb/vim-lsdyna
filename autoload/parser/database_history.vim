"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  26.12.2021
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

function! parser#database_history#Database_history() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *DATABASE_HISTORY keyword object.
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
  let dbhs = []

  "-----------------------------------------------------------------------------
  " ID, no LOCAL
  if self.type =~? 'ID' && self.type =~? 'LOCAL'

    let lines = []
    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      let lines += [line]
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let dbh       = copy(self)
          let dbh.id    = str2nr(line[:9])
          let dbh.lnum  = dbh.first + lcount
        elseif dlcount == 2
          let dbh.title = trim(line)
          let dbh.lines = [self.name] + lines
          let dbh.Qf    = function('<SID>Qf')
          let dbh.Tag   = function('<SID>Tag')
          let dbh.Omni  = function('<SID>Omni')
          call add(dbhs, dbh)
          let dlcount = 0
          let lines = []
        endif
      endif
    endfor

  "-----------------------------------------------------------------------------
  " ID, no LOCAL
  elseif self.type =~? 'ID'

    let lines = []
    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      let lines += [line]
      if line[0] != '$'
        let dbh       = copy(self)
        let dbh.id    = str2nr(line[:9])
        let dbh.title = trim(line[10:])
        let dbh.lnum  = dbh.first + lcount
        let dbh.lines = [self.name] + lines
        let dbh.Qf    = function('<SID>Qf')
        let dbh.Tag   = function('<SID>Tag')
        let dbh.Omni  = function('<SID>Omni')
        call add(dbhs, dbh)
        let lines = []
      endif
    endfor

  "-----------------------------------------------------------------------------
  " no ID, LOCAL
  elseif self.type =~? 'LOCAL'

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'
        let dbh       = copy(self)
        let dbh.id    = str2nr(line[:9])
        let dbh.title = ''
        let dbh.lnum  = dbh.first + lcount
        let dbh.Qf    = function('<SID>Qf')
        let dbh.Tag   = function('<SID>Tag')
        let dbh.Omni  = function('<SID>Omni')
        call add(dbhs, dbh)
        let lines = []
      endif
    endfor

  "-----------------------------------------------------------------------------
  " no ID, no LOCAL
  else

    let dbh = copy(self)
    let dbh.id    = 0
    let dbh.title = ''
    let dbh.lnum  = dbh.first
    let dbh.Qf    = function('<SID>Qf')
    let dbh.Tag   = function('<SID>Tag')
    let dbh.Omni  = function('<SID>Omni')
    call add(dbhs, dbh)

  endif

  return dbhs

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
