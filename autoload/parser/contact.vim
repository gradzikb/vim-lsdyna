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
  let self.AddComments = function('s:AddComments')

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
    let qf.text  = self.id.'|'.self.title.'|'.self.type

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

"-------------------------------------------------------------------------------

function s:AddComments() dict abort

  let commentlines = []
  if self.name =~? '_ID$'
    call add(commentlines, '$#     cid title')
  endif
  call add(commentlines, '$#    ssid      msid     sstyp     mstyp    sboxid    mboxid       spr       mpr')
  call add(commentlines, '$#      fs        fd        dc        vc       vdc    penchk        bt        dt')
  call add(commentlines, '$#     sfs       sfm       sst       mst      sfst      sfmt       fsf       vsf')
  call add(commentlines, '$#    soft    sofscl    lcidab    maxpar     sbopt     depth     bsort    frcfrq')
  call add(commentlines, '$#  penmax    thkopt    shlthk     snlog      isym     i2d3d    sldthk    sldstf')
  call add(commentlines, '$#    igap    ignore    dprfac    dtstif                        flangl   cid_rcf')
  call add(commentlines, '$#   q2tri    dtpchk     sfnbr    fnlscl    dnlscl      tcso    tiedid    shledg')

  let self.lines = [self.name] + lsdyna_misc#ZipList(commentlines, self.Datalines()[1:])
 
endfunction

"-------------------------------------EOF---------------------------------------
