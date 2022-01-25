"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  25.12.2021
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

function! parser#sensor#Sensor() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *SENSOR keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of sensor objects base on keyword object.
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

  " get rid of members/methods you do not want to inherit
  call filter(self, 'v:key[0] != "_"')

  " list to return sensor objects
  let sensors = []

  "-----------------------------------------------------------------------------
  " two cards per definition
  if self.type =~? 'CONTROL\|DEFINE_ELEMENT_SET'

    let lcount = 0
    let dlcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'
        let dlcount += 1
        if dlcount == 1
          let sensor       = copy(self)
          let sensor.id    = str2nr(line[:9])
          let sensor.title = trim(toupper(line[10:19]))
          let sensor.lnum  = sensor.first + lcount
          let sensor.lines = line
        elseif dlcount == 2
          let sensor.lines += line
          let sensor.Qf    = function('<SID>Qf')
          let sensor.Tag   = function('<SID>Tag')
          let sensor.Omni  = function('<SID>Omni')
          call add(sensors, sensor)
          let dlcount = 0
        endif
      endif
    endfor

  else
  "-----------------------------------------------------------------------------
  " one card per definition

    let lcount = 0
    for line in self.lines[1:]
      let lcount += 1
      if line[0] != '$'
          let sensor       = copy(self)
          let sensor.id    = str2nr(line[:9])
          if sensor.type =~? 'DEFINE_ELEMENT\|DEFINE_FORCE\|DEFINE_MISC\|DEFINE_CALC-MATH'
            let sensor.title = trim(toupper(line[10:19]))
          elseif sensor.type =~? 'DEFINE_NODE'
            let sensor.title = trim(toupper(line[50:59]))
          elseif sensor.type ==? 'SWITCH'
            let sensor.title = trim(toupper(line[30:39]))
          else
            let sensor.title = ''
          endif
          let sensor.lnum  = sensor.first + lcount
          let sensor.lines = line
          let sensor.Qf    = function('<SID>Qf')
          let sensor.Tag   = function('<SID>Tag')
          let sensor.Omni  = function('<SID>Omni')
          call add(sensors, sensor)
      endif
    endfor

  endif

  return sensors

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

  let tag = self.id."\t".self.file."\t".self.first.";\"\tkind:DEFINE_FRICTION\ttitle:".self.title

  return tag

endfunction

"-------------------------------------EOF---------------------------------------
