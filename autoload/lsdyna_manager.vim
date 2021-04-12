"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  13.10.2019
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_manager#Manager(bang, kword) abort

  "-----------------------------------------------------------------------------
  " Main function trigger for 'LsManager' command. It serach all a:kword in
  " inputdeck and build qf list.
  " Arguments:
  " - bang : false - search in current file only
  "        :  true - search in all *INCLUDE files
  " - kword : keyword(s) to search
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " global list to store all parameters {pname:peval}
  " I need it to evaluate parameter values
  let g:lsdyna_manager_parameters = {}

  " w/o  bang --> search keyword in current buffer only
  " with bang --> search keyword in all *INCLUDE files
  if a:bang
    let qfid = lsdyna_vimgrep#Vimgrep(a:kword, '%', 'i')
  else
    let qfid = lsdyna_vimgrep#Vimgrep(a:kword, '%', '')
  endif

  " list of items found by vimgrep
  let vimgrepQfList = getqflist({'id':qfid, 'items':0}).items 

  " oops ... I found nothing ... goodbye
  if len(vimgrepQfList) == 0
    echo 'No ' . a:kword . ' found.'
    return
  endif

  " save cursor position
  " parsing keywords change cursor position and I want to stay in place
  let save_cursor = getpos(".")
  let save_cursor[0] = bufnr('%')

  " if I make list of all keywords parse all items as "kword" object otherwise
  " try to detecet type of the keyword
  let fname = a:kword == '*' ? '_Kword' : '_Autodetect'

  " parse each entry from vimgrep into keyword type
  let qflist = []
  for item in vimgrepQfList
    let kwords = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'f')
    "let kwords_obj = kwords.{fname}()
    let kwords_obj = call(kwords[fname], [], kwords)
    call extend(qflist, map(kwords_obj, 'v:val.Qf()'))
  endfor

  " restore cursor position
  execute 'noautocmd buffer ' . save_cursor[0]
  call setpos('.', save_cursor)

  " set new qf list with new items
  call setqflist([], ' ', {'items' : qflist,
  \                        'title' : 'LsManager '.a:kword
  \                       })
  "
  " save qf list id so I can used it from history
  " history for includes is kept separately
  let qfid = getqflist({'id':0}).id 
  let g:lsdyna_qfid_last = qfid
  if a:kword == 'include' | let g:lsdyna_qfid_lastIncl = qfid | endif

  " finally show me Qf window
  call lsdyna_manager#QfOpen(qfid)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_manager#QfOpen(qfid)

  "-----------------------------------------------------------------------------
  " Function opens quick fix window for a:qfid and set cursor on line with
  " item close to cursor position at call time.
  " Arguments:
  " - qfid : qf list id
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " collect some info used later about qf list
  let qf = getqflist({'id':a:qfid, 'nr':'', 'items':'', 'size':''})

  " default position on the list
  let pos_lnum = 1

  " just before qf window is open I am here
  let lnum = line('.')
  let bufnr = bufnr('%')

  " looking minimal distance between my current position and qf item
  let min = 1.0e+06
  let i = 1
  for item in qf.items
    if item.bufnr == bufnr
      let dist = abs(item.lnum-lnum)
      " if distance is 0 there is no point to continue loop
      if dist == 0
        let pos_lnum = i
        break
      endif
      if dist <= min
        let min = dist
        let pos_lnum = i
      endif
    endif
    let i += 1
  endfor

  " open qf window
  cclose
  silent execute qf.nr.'chistory'
  "execute 'copen' max([2, min([30, qf.size+1])])
  " qf qindow has minimal size of two lines and max 50% of window height
  execute 'copen' max([2, min([winheight('')/2, qf.size+1])])
  call cursor(pos_lnum, 0)
  call lsdyna_manager#QfSetCursor()

endfunction

"-------------------------------------------------------------------------------

function lsdyna_manager#QfFormatLine(info)

  "-----------------------------------------------------------------------------
  " Function to format lines in QuickFix window. Each line format depend on
  " qf.type value (normally it describe error type but I am using to describe
  " line formatting type). Supported values are:
  "   'K' : keyword
  "   'I' : include
  "   'P' : parameter
  "   'U' : unknown
  " Each keyword object has Qf() method to create a dict for qf list
  " ':help setqflist-what', all info is saved in 'text' key as one string with
  " '|' separators. Number and meanings of entities in 'text' might be different
  " for different keywords, see source code for specific parser type. 
  " Arguments:
  " - See :help quickfix-window-function
  " Return:
  " - See :help quickfix-window-function
  "-----------------------------------------------------------------------------

  " get items from qf list displayed in qf window
  let items = getqflist({'id':a:info.id, 'items':''}).items

  " 1st loop to collect informations
  let maxlen = 0 " max length of keyword title to adjust table
  let treelvls = {} " inclination level for include tree
  let paramNames = [] " list of all parameters name, used to find duplicates

  for idx in range(a:info.start_idx - 1, a:info.end_idx - 1)
    if items[idx].type == 'K'

      let qfline = split(items[idx].text, '|', 1)
      let kwordName = qfline[1]
      let length = len(kwordName)
      let maxlen = length > maxlen ? length : maxlen

    elseif items[idx].type == 'I'

      let qfline = split(items[idx].text, '|', 1)
      let inclName = qfline[0]
      let inclDir  = qfline[3]
      if !exists('parent_dir')
        let parent_dir = []
      endif
      if idx == a:info.start_idx - 1
        call add(parent_dir, inclDir) " parent dir for first include
      else
        let parent_dir_pos = index(parent_dir, inclDir)
        " current path on last position --> the same inclination level, keep the list not changed
        if parent_dir_pos == len(parent_dir)-1
            let parent_dir = parent_dir
        " no current path in the list --> new inclination level, add new parent path at the end
        elseif parent_dir_pos == -1 
            call add(parent_dir, inclDir)
        " current path on any other position --> old inclination level, remove all from current position to end
        else
            let parent_dir = parent_dir[:parent_dir_pos]
        endif
      endif
      let treelvl = 2*(len(parent_dir)-1)
      let length = treelvl + len(inclName)
      let maxlen = length > maxlen ? length : maxlen
      let treelvls[idx] = repeat(' ', treelvl) " include name prefix to print like tree view

    elseif items[idx].type == 'P'
      
      let qfline = split(items[idx].text, '|', 1)
      let paramName = qfline[3]
      let paramNames += [paramName]

    endif
  endfor

  let qflines = []
  for idx in range(a:info.start_idx - 1, a:info.end_idx - 1)

    "-------------------------------------------------------------------------
    " format line as keyword
    if items[idx].type == 'K'
      let qftext = split(items[idx].text, '|', 1)
      let id     = printf('%10s', qftext[0])
      "let title  = printf('%-57s', qftext[1][:56])
      let title  = printf('%-'..max([57,maxlen])..'s', qftext[1])
      let type   = qftext[2]
      call add(qflines, id.' '.title.' | '.type)

    "-------------------------------------------------------------------------
    " format line as include
    elseif items[idx].type == 'I'

      let qftext   = split(items[idx].text, '|', 1)
      let inclName = treelvls[idx]..qftext[0]
      let path  = printf('%-'..max([69, maxlen])..'s', inclName)
      let read  = qftext[1] <= 0 ? 'error' : ''
      "let read  = qftext[1] == 0 ? 'warning' : ''
      "if qftext[1] == 0
      "  let read = 'error'
      "elseif qftext[1] == 1
      "  let read = ''
      "elseif qftext[1] == -1
      "  let read = 'ignore'
      "endif
      let type  = qftext[2]
      call add(qflines, path.'| '.type.' '.read)

    "-------------------------------------------------------------------------
    " format lines as parameter
    elseif items[idx].type == 'P'
      let qftext = split(items[idx].text, '|', 1)
      let ktype  = qftext[1] =~# 'EXPRESSION' ? 'E' : ' '
      let pscope = qftext[1] =~# 'LOCAL' ? 'L' : ' '
      let ptype  = qftext[2]
      let pname  = printf('%9s', qftext[3])
      let pval   = qftext[4]
      let peval  = qftext[5]
      "let pdub   = qftext[6] ? 'D' : ' '
      let pdub   = count(paramNames, qftext[3], 1) > 1 ? 'D' : ' '
      " I want to print parameter expression only if I need to
      " if parameter value is just a number there is no point to print expression
      if pval =~ '^[-+]\?\d\+\.\?\d*\([eE][-+]\?\d\+\)\?$'
        let peval = printf('%-59s', pval)
        let pval  = ''
      else
        if ptype == 'R'
          let peval = peval == '?' ? printf('%-10s', peval).' : ' : printf('%-10.3g', str2float(peval)).' : '
        elseif ptype == 'I'
          let peval = peval == '?' ? printf('%-10s', peval).' : ' : printf('%-10d', str2nr(peval)).' : '
        else
          let peval = peval == '?' ? printf('%-10s', peval).' : ' : printf('%-10s', peval).' : '
        endif
        let pval  = printf('%-46s', pval[:44])
      endif
      call add(qflines, ptype.' '.pname.' = '.peval.pval.'| '.'['.pscope.ktype.pdub.']')

    "-------------------------------------------------------------------------
    " format line as unknown keyword, print only keyword name
    elseif items[idx].type == 'U'
      let qftext = split(items[idx].text, '|', 1)
      let kname = qftext[0]
      call add(qflines, kname)

    "-------------------------------------------------------------------------
    " if format type not match just print line as is
    else
      call add(qflines, items[idx].text)
    endif

  endfor

  return qflines

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_manager#QfWindow()

  "-----------------------------------------------------------------------------
  " Function to set status line and define normal commands for qf window.
  " Depend on qf content might be diffrent.
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " do nothing is Qf list is empty
  if empty(getline(1))
    return
  endif

  "-----------------------------------------------------------------------------
  " default status line and normal commands

  setlocal nolist
  setlocal number
  setlocal nowrap
  setlocal statusline=LsManager:\ (F\|f)ilter\ (u)ndo_filter

  nnoremap <buffer><silent> <ESC> :cclose<CR>zz
  nnoremap <buffer><silent> <CR> :cclose<CR>zz
  nnoremap <buffer><silent> <kEnter> :cclose<CR>zz
  nnoremap <buffer><silent> <Home> gg
  nnoremap <buffer><silent> <End> G
  nnoremap <buffer><silent><expr> <Down> line(".") == line("$") ? "gg" : "j"
  nnoremap <buffer><silent><expr> <Up> line(".") == 1 ? "G" : "k"
  nnoremap <buffer><silent><expr> j line(".") == line("$") ? "gg" : "j"
  nnoremap <buffer><silent><expr> k line(".") == 1 ? "G" : "k"
  nnoremap <buffer><silent> f :call <SID>QfFilter('','')<CR>
  nnoremap <buffer><silent> F :call <SID>QfFilter('','exclusive')<CR>
  nnoremap <buffer><silent> u :call <SID>QfFilterUndo()<CR>

  " status line will be set base on 1st qf item type
  " not perfect since qf list can have diffrent types but I must make decision
  " somehow, in 99% cases qf list has only one type item
  let qftype = getqflist()[0].type
  
  "-----------------------------------------------------------------------------
  " status line and normal commands for include
  if qftype == 'I'

    setlocal statusline=LsManager:\ (F\|f)ilter\ (u)ndo_filter\ (C)opy\ (D)elete\ (R\|r)ename
    nmap <buffer><silent> <CR> <ESC>gf
    nmap <buffer><silent> <kEnter> <ESC>gf
    nmap <buffer><silent> gf <ESC>gf
    nmap <buffer><silent> gF <ESC>gF
    nmap <buffer><silent> gt <ESC><C-w>gf
    nmap <buffer><silent> gT <ESC><C-w>gf:tabrewind<CR>:LsIncludes<CR>
    nmap <buffer><silent> gd <ESC>gd
    nmap <buffer><silent> gD <ESC>gD
    nmap <buffer><silent> g<C-d> <ESC>g<C-d>
    nnoremap <buffer><silent> C :cclose<CR>:call lsdyna_include#Touch('C')<CR>
    nnoremap <buffer><silent> D :cclose<CR>:call lsdyna_include#Touch('D')<CR>
    nnoremap <buffer><silent> r :cclose<CR>$F.C
    nnoremap <buffer><silent> R :cclose<CR>:call lsdyna_include#Touch('R')<CR>

  endif

endfunction

"-------------------------------------------------------------------------------

function! s:QfFilter(string, flag)

  "-----------------------------------------------------------------------------
  " Function to filter lines in qf window.
  "
  " Arguments:
  " - string : string used to filter
  " - flag   : filter flag
  "            empty     : inclusive filter (keep matching lines)
  "            not empty : exclusive filter (remove matching lines)
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " if filter name missing ask for it
  let fname = !empty(a:string) ? a:string : input('Filter: ') 

  if empty('fname') | return | endif

  let qflist = getqflist()
  let qfwindow = getline(1, line('$'))
  let qflist_filter = []

  " inclusive filter
  if empty(a:flag)
    for i in range(len(qfwindow))
      if qfwindow[i] =~? fname
        call add(qflist_filter, qflist[i])
      endif
    endfor
  " exclusive filter
  else
    for i in range(len(qfwindow))
      if qfwindow[i] !~? fname
        call add(qflist_filter, qflist[i])
      endif
    endfor
  endif

  " set a new qf list with filter items
  call setqflist([], ' ', {'items' : qflist_filter,
  \                        'title' : 'LsManager filter - '.fname
  \                       })
  "\                        'quickfixtextfunc' : '<SID>QfFormatLine' 
  call lsdyna_manager#QfOpen(getqflist({'id':0}).id) " open current qf list

endfunction

"-------------------------------------------------------------------------------

function! s:QfFilterUndo()

  "-----------------------------------------------------------------------------
  " Small function to load qf list before filter.
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " qf list befor filter, is 2nd from end qf list on stack
  let qfnr = getqflist({'nr':'$'}).nr
  let qfid = getqflist({'nr':qfnr-1, 'id':0}).id
  call lsdyna_manager#QfOpen(qfid)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_manager#QfSetCursor()

  "-----------------------------------------------------------------------------
  " Function to set view for selected kword from qf list.
  " Trigged every time cursor change position in qf window.
  " Take line and buffor number for qf list and set this position in other
  " window.
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let qflist = getqflist()

  if empty(qflist)
    return
  endif

  let qf = qflist[line(".")-1]
  "let bufnr = qf.bufnr
  "let lnum  = qf.lnum
  "let col   = qf.col
  " jump to prev window
  wincmd p
  execute 'buffer ' .. qf.bufnr
  " when I am looking for keywords I open buffer with 'noautocomand' option
  " it save time for big files since plugin is not loaded
  " now when I move on qf list I want to have sytax highlight so i need to
  " load plugin
  "if &filetype != 'lsdyna'
  "  let &filetype='lsdyna'
  "endif
  call cursor(qf.lnum, qf.col)
  if foldclosed(qf.lnum) != -1
    normal! zo
  endif
  normal! zz
  "redraw!
  " move back to qf window
  wincmd p
  "execute line(".")-1..'cc'
  "wincmd p

endfunction

"-------------------------------------------------------------------------------

"function s:ShowExpr()
"
"  "-----------------------------------------------------------------------------
"  " Function to show only selected parameter and parameters used in
"  " expression.
"  "
"  " Arguments:
"  " - None
"  " Return:
"  " - None
"  "-----------------------------------------------------------------------------
"
"  " get name and full expression for parameter in current line
"  let exprName = split(getqflist()[line('.')-1].text,'|')[4]
"  let exprVal  = split(getqflist()[line('.')-1].text,'|')[5]
"  
"  " here I am looking for all parameter lines in expression
"  let rePnames = exprName.'\|'
"  let start = 0
"  while 1
"    let match = matchstrpos(exprVal, '\(^\|[-+*/(,]\)\zs\h\w*\ze\([-+*/)]\|$\)', start, 1) 
"    if match[1] == -1 | break | endif
"    let rePnames = rePnames.match[0].'\|'
"    let start = match[2]
"  endwhile
"
"  " and last step call filter function
"  let rePnames = '^\w\s*\('.rePnames[:-3].'\) ='
"  "call writefile([rePnames], 'vimout.txt')
"  call <SID>Filter(rePnames,'') 
"
"endfunction

"-------------------------------------EOF---------------------------------------
