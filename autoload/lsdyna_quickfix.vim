"
let s:qf_history_incr = 0

"-------------------------------------------------------------------------------
"    KEYWORD (NO PARSER)
"-------------------------------------------------------------------------------

function! lsdyna_quickfix#KeywordNoParse_textfunc(info)

  "-----------------------------------------------------------------------------
  " Function to format lines in QuickFix window.
  " See :help quickfix-window-function
  "-----------------------------------------------------------------------------

  let qf_items = getqflist({'id':a:info.id, 'items':''}).items

  let qf_lines = []
  for idx in range(a:info.start_idx - 1, a:info.end_idx - 1)
    let kword = eval(qf_items[idx].text)
    let hide = kword.hide ? '$ ' : '  '
    let name = kword.name
    let qf_line = hide..name
    call add(qf_lines, qf_line)
  endfor

  return qf_lines

endfunction

function! lsdyna_quickfix#KeywordNoParse_bufferfunc()

  "-----------------------------------------------------------------------------
  " Function to set options for quickfix buffer.
  "-----------------------------------------------------------------------------

  call lsdyna_quickfix#BufferCommands()
  "let &l:statusline = '*'

endfunction

"-------------------------------------------------------------------------------
"    KEYWORD
"-------------------------------------------------------------------------------

function! lsdyna_quickfix#Keyword_textfunc(info)

  "-----------------------------------------------------------------------------
  " Function to format lines in QuickFix window.
  " See :help quickfix-window-function
  "-----------------------------------------------------------------------------

  let qf_items = getqflist({'id':a:info.id, 'items':''}).items->map({_,val->eval(val.text)})

  " longest title
  let max_length = qf_items->copy()->map({_,val->len(val.title)})->max()

  let qf_lines = []
  for kword in qf_items
    let hide  = kword.hide ? '$' : ' '
    let id    = kword.id->printf('%9s')
    let title = kword.title->printf('%-'..max([57,max_length])..'s')
    let type  = kword.type
    let qf_line = hide..id..' '..title..' | '..type
    call add(qf_lines, qf_line)
  endfor

  return qf_lines

endfunction

function! lsdyna_quickfix#Keyword_bufferfunc()

  "-----------------------------------------------------------------------------
  " Function to set options for quickfix buffer.
  "-----------------------------------------------------------------------------

  call lsdyna_quickfix#BufferCommands()
  "let &l:statusline = 'Keywords'

endfunction

"-------------------------------------------------------------------------------
"    INCLUDES
"-------------------------------------------------------------------------------

function! lsdyna_quickfix#Include_textfunc(info)

  "-----------------------------------------------------------------------------
  " Function to format lines in QuickFix window.
  " See :help quickfix-window-function
  "-----------------------------------------------------------------------------

  let qf_items = getqflist({'id':a:info.id, 'items':''}).items->map({_,val->eval(val.text)})

  let maxlen = 0      " max length of keyword title to adjust table
  let treelvls = []   " inclination level for include tree
  let paramNames = [] " list of all parameter names, used to find duplicates

  " loop over all includes to set inclination levels
  for idx in range(qf_items->len())
    let inclName = fnamemodify(qf_items[idx].path,':t')
    let inclDir  = qf_items[idx].file
    if !exists('parent_dir')
      let parent_dir = []
    endif
    if idx == 0
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
    "let treelvls[idx] = repeat('>', treelvl) " include name prefix to print like tree view
    call add(treelvls, repeat(' ', treelvl)) " include name prefix to print like tree view
  endfor

  let qf_lines = []
  "for incl in qf_items
  for idx in range(qf_items->len())
    let incl  = qf_items[idx]
    " remove path separator if at the end, it make difference for fnamemodify(":t")
    let name = incl.path[-1:] =~? '[/\\]' ? incl.path[:-2] : incl.path 
    let path  = printf('%-'..max([68, maxlen])..'s', treelvls[idx]..fnamemodify(name,':t'))
    let read  = incl.read <= 0 ? 'error' : ''
    let type  = incl.type
    let hide  = incl.hide ? '$ ' : '  ' 
    let qf_line = hide..path..' | '..type..' '..read
    call add(qf_lines, qf_line)
  endfor

  return qf_lines

endfunction

function! lsdyna_quickfix#Include_bufferfunc()

  "-----------------------------------------------------------------------------
  " Function to set options for quickfix buffer.
  "-----------------------------------------------------------------------------

  call lsdyna_quickfix#BufferCommands()

  let &l:statusline ..= '| (C-c)opy (C-d)elete (C-r|r)ename'
  "unmap <buffer> <CR>
  nnoremap <buffer><silent> <ESC> :cclose<CR>zz
  nmap <buffer><silent> <CR> :cclose<CR>gf
  nmap <buffer><silent> <kEnter> <CR>
  nmap <buffer><silent> gf <ESC>gf
  nmap <buffer><silent> gF <ESC>gF
  nmap <buffer><silent> gt <ESC><C-w>gf
  nmap <buffer><silent> gT <ESC><C-w>gf:tabrewind<CR>:call lsdyna_manager#QfOpen(g:lsdyna_qfid_lastIncl, 0)<CR>
  nmap <buffer><silent> gd <ESC>gd
  nmap <buffer><silent> gD <ESC>gD
  nmap <buffer><silent> g<C-d> <ESC>g<C-d>
  nnoremap <buffer><silent> <C-c> :cclose<CR>:call lsdyna_include#Touch('C')<CR>
  nnoremap <buffer><silent> <C-d> :cclose<CR>:call lsdyna_include#Touch('D')<CR>
  nnoremap <buffer><silent> r :cclose<CR>$F.C
  nnoremap <buffer><silent> <C-r> :cclose<CR>:call lsdyna_include#Touch('R')<CR>

endfunction

"-------------------------------------------------------------------------------
"    PARAMETER
"-------------------------------------------------------------------------------

function! lsdyna_quickfix#Parameter_textfunc(info)

  "-----------------------------------------------------------------------------
  " Function to format lines in QuickFix window.
  " See :help quickfix-window-function
  "-----------------------------------------------------------------------------

  let qf_items = getqflist({'id':a:info.id, 'items':''}).items->map({_,val->eval(val.text)})

  " list of parameter names, used to find duplicates
  let pnames = qf_items->copy()->map({_,val->val.pname})

  let qf_lines = []
  for param in qf_items
    let ptype = param.ptype
    let pname = param.pname->printf('%9s')

    " I want to print parameter expression only if I need to
    " if parameter value is just a number there is no point to print expression
    if param.pval =~ '^[-+]\?\d\+\.\?\d*\([eE][-+]\?\d\+\)\?$'
      let peval = param.pval->printf('%-59s')
      let pval  = ''
    else
      if ptype == 'R'
        let peval = param.peval == '?' ? printf('%-10s', param.peval).' : ' : printf('%-10.3g', str2float(param.peval)).' : '
      elseif ptype == 'I'
        let peval = param.peval == '?' ? printf('%-10s', param.peval).' : ' : printf('%-10d', float2nr(str2float(param.peval))).' : '
      else
        let peval = param.peval == '?' ? printf('%-10s', param.peval).' : ' : printf('%-10s', param.peval).' : '
      endif
      let pval  = param.pval[:44]->printf('%-46s')
    endif

    let ktype = param.type =~# 'EXPRESSION' ? 'E' : ' '
    let scope = param.type =~# 'LOCAL' ? 'L' : ' '
    let dub   = count(pnames, param.pname, 1) > 1 ? 'D' : ' '

    let qf_line = ptype..' '..pname..' = '..peval..pval..'| '..'['..scope..ktype..dub..']'
    call add(qf_lines, qf_line)
  endfor

  return qf_lines

endfunction

function! lsdyna_quickfix#Parameter_bufferfunc()

  "-----------------------------------------------------------------------------
  " Function to set options for quickfix buffer.
  "-----------------------------------------------------------------------------

  call lsdyna_quickfix#BufferCommands()
  let &l:statusline = 'Parameters'

endfunction

"-------------------------------------------------------------------------------
"    COMMANDS
"-------------------------------------------------------------------------------

function! lsdyna_quickfix#BufferCommands()

  "-----------------------------------------------------------------------------
  " Function to set status line and define normal commands for qf window.
  " Depend on qf content might be different.
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " window appearance
  setlocal nolist
  setlocal number
  setlocal nowrap
  let &l:statusline = '(h)elp (b)ack un(c)omment (d)elete (e)xecute (f)ind (y)ank (p)ut (x)item'
  " quit commands
  nnoremap <buffer><silent> <ESC> :cclose<CR>'X
  nnoremap <buffer><silent> <CR> :cclose<CR>zz
  " cursor movement commands
  nnoremap <buffer><silent> <kEnter> :cclose<CR>zz
  nnoremap <buffer><silent> <Home> gg
  nnoremap <buffer><silent> <End> G
  nnoremap <buffer><silent><expr> <Down> line(".") == line("$") ? "gg" : "j"
  nnoremap <buffer><silent><expr> <Up> line(".") == 1 ? "G" : "k"
  nnoremap <buffer><silent><expr> j line(".") == line("$") ? "gg" : "j"
  nnoremap <buffer><silent><expr> k line(".") == 1 ? "G" : "k"
  " normal commands
  nnoremap <buffer><silent> b :call <SID>QfFilterUndo(-1)<CR>
  nnoremap <buffer><silent> B :call <SID>QfFilterUndo(1)<CR>
  nnoremap <buffer><silent> c :call <SID>QfNormalCmd('c')<CR>
  nnoremap <buffer><silent> C :call <SID>QfNormalCmd('C')<CR>
  nnoremap <buffer><silent> U :call <SID>QfNormalCmd('U')<CR>
  nnoremap <buffer><silent> x :call <SID>QfNormalCmd('x')<CR>
  nnoremap <buffer><silent> d :call <SID>QfNormalCmd('d')<CR>
  nnoremap <buffer><silent> D :call <SID>QfNormalCmd('D')<CR>
  nnoremap <buffer><silent> y :call <SID>QfNormalCmd('y')<CR>
  nnoremap <buffer><silent> Y :call <SID>QfNormalCmd('Y')<CR>
  nnoremap <buffer><silent> <C-y> :call <SID>QfNormalCmd('C-y')<CR>
  nnoremap <buffer><silent> p :call <SID>QfNormalCmd('p')<CR>
  nnoremap <buffer><silent> P :call <SID>QfNormalCmd('P')<CR>
  nnoremap <buffer><silent> R :call <SID>QfNormalCmd('R')<CR>
  nnoremap <buffer><silent> h :call <SID>QfNormalCmd('h')<CR>
  nnoremap <buffer><silent> f :call <SID>QfFilter('','f')<CR>
  nnoremap <buffer><silent> F :call <SID>QfFilter('','F')<CR>
  nnoremap <buffer><silent> 4 :call <SID>QfFilter('\$','F')<CR>
  nnoremap <buffer><silent> $ :call <SID>QfFilter('\$','f')<CR>
  nnoremap <buffer> e :cclose<CR> :silent cdo LsCmdExe 

endfunction

"-------------------------------------------------------------------------------

function! s:QfNormalCmd(cmd)

  "-----------------------------------------------------------------------------
  " Function to execute normal command for keyword manager.
  "
  " Arguments:
  " - cmd : command for execution
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " show help (list of commands for LsManager
  if a:cmd ==# 'h'
    cclose
    silent execute 'help lsdyna-managerCommands'
  "-----------------------------------------------------------------------------
  " yank current keyword
  elseif a:cmd ==# 'y'
    let qf = getqflist()[line('.')-1].text->eval()
    call setreg('+', getbufline(bufname(qf.bufnr), qf.first, qf.last), 'l')
  "-----------------------------------------------------------------------------
  " yank current keyword (extend)
  elseif a:cmd ==# 'C-y'
    let qf = eval(getqflist()[line('.')-1].text)
    call setreg('+', getbufline(bufname(qf.bufnr), qf.first, qf.last), 'al')
  "-----------------------------------------------------------------------------
  " yank all keywords from list
  elseif a:cmd ==# 'Y'
    call setreg('+', [], 'l') " empty register first
    for item in getqflist()
      let qf = eval(item.text)
      call setreg('+', getbufline(bufname(qf.bufnr), qf.first, qf.last), 'al')
    endfor
  "-----------------------------------------------------------------------------
  " put after current keyword
  elseif a:cmd ==# 'p'
    let qf = eval(getqflist()[line('.')-1].text)
    call appendbufline(bufname(qf.bufnr), qf.last, getreg('+', 1, 1))
    cclose
    silent execute getqflist({'context':''}).context.command
  "-----------------------------------------------------------------------------
  " put before current keyword
  elseif a:cmd ==# 'P'
    let qf = eval(getqflist()[line('.')-1].text)
    call appendbufline(bufname(qf.bufnr), qf.first-1, getreg('+', 1, 1))
    cclose
    silent execute getqflist({'context':''}).context.command
  "-----------------------------------------------------------------------------
  " delete current keyword
  elseif a:cmd ==# 'd'
    let qf = eval(getqflist()[line('.')-1].text)
    cclose
    silent execute qf.first ',' qf.last 'delete'
    silent execute getqflist({'context':''}).context.command
  "-----------------------------------------------------------------------------
  " delete all keywords
  elseif a:cmd ==# 'D'
    call <SID>QfNormalCmd('Y') " yank all items
    cclose
    silent execute 'cdo LsCmdExe LsKwordDelete'
  "-----------------------------------------------------------------------------
  " remove current item from the list
  elseif a:cmd ==# 'x'
    let lnum = line('.')
    let qflist = getqflist()
    call remove(qflist, lnum-1)
    call setqflist([], 'r', #{nr: 0, items: qflist})
    call lsdyna_manager#QfOpen(getqflist({'id':0}).id, lnum)
  "-----------------------------------------------------------------------------
  " comment/uncomment current keyword
  elseif a:cmd ==# 'c'
    let lnum = line('.')
    let qflist = getqflist()
    let qf = eval(qflist[lnum-1].text)
    if !qf.hide
      let qf.hide = 1
      let cmd = 's/^/'..g:lsdynaCommentString
    else
      let qf.hide = 0
      let cmd = 's/^'..g:lsdynaCommentString..'/'
    endif
    let qflist[lnum-1].text = string(qf) " update qf item with new hide flag
    cclose
    silent execute qf.first ',' qf.last cmd
    call setqflist([], 'r', #{nr: 0, items: qflist})
    call lsdyna_manager#QfOpen(getqflist({'id':0}).id, lnum)
  "-----------------------------------------------------------------------------
  " comment all keywords
  elseif a:cmd ==# 'C'
    cclose
    let bufnr_1st = bufnr('%')
    for item in getqflist()
        let qf = eval(item.text)
        execute 'noautocmd buffer' qf.bufnr
        if !qf.hide
          silent execute qf.first ',' qf.last 's/^/'..g:lsdynaCommentString
        endif
    endfor
    " must go back to buffer where I started
    execute 'noautocmd buffer' bufnr_1st
    silent execute getqflist({'context':''}).context.command
  "-----------------------------------------------------------------------------
  " uncomment all keywords
  elseif a:cmd ==# 'U'
    cclose
    let bufnr_1st = bufnr('%')
    for item in getqflist()
        let qf = eval(item.text)
        if qf.hide
          execute 'noautocmd buffer' qf.bufnr
          silent execute qf.first ',' qf.last 's/^'..g:lsdynaCommentString..'/'
        endif
    endfor
    " must go back to buffer where I started
    execute 'noautocmd buffer' bufnr_1st
    silent execute getqflist({'context':''}).context.command
  "-----------------------------------------------------------------------------
  " reverse comment/uncomment
  elseif a:cmd ==# 'R'
    let lnum = line('.')
    cclose
    let bufnr_1st = bufnr('%')
    for item in getqflist()
        let qf = eval(item.text)
        execute 'noautocmd buffer' qf.bufnr
        if qf.hide
          silent execute qf.first ',' qf.last 's/^'..g:lsdynaCommentString..'/'
        else
          silent execute qf.first ',' qf.last 's/^/'..g:lsdynaCommentString
        endif
    endfor
    " must go back to buffer where I started
    execute 'noautocmd buffer' bufnr_1st
    silent execute getqflist({'context':''}).context.command
    call cursor(lnum, 0)
  endif

endfunction

"-------------------------------------------------------------------------------

function! s:QfFilter(what, options)

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
  let fname = !empty(a:what) ? a:what : input('Find: ')

  if empty('fname') | return | endif

  let s:qf_history_incr = 0 " reset history position on qf stack

  let qf = getqflist(#{nr:0, all:''})

  let qfwindow = getline(1, line('$'))

  let qf_filter = []

  " inclusive filter
  if a:options ==# 'f'
    for i in range(len(qfwindow))
      if qfwindow[i] =~? fname
        call add(qf_filter, qf.items[i])
      endif
    endfor
  " exclusive filter
  elseif a:options ==# 'F'
    for i in range(len(qfwindow))
      if qfwindow[i] !~? fname
        call add(qf_filter, qf.items[i])
      endif
    endfor
  endif

  " set a new qf list with filter items
  call setqflist([], ' ', #{
  \ title: 'LsManager '..a:options..'ilter '..fname,
  \ items: qf_filter,
  \ quickfixtextfunc: qf.context.quickfixtextfunc,
  \ context: qf.context,
  \ })

  " store filter history
  let qfid = getqflist({'id':0}).id
  if !empty(qf_filter)
    if qf_filter[0].type == 'I' | let g:lsdyna_qfid_lastIncl = qfid | endif
  endif

  " open current qf list
  call lsdyna_manager#QfOpen(qfid, 0)

endfunction

function! s:QfFilterUndo(incr)

  "-----------------------------------------------------------------------------
  " Small function to load qf list before filter.
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let s:qf_history_incr += a:incr

  " qf list befor filter, is 2nd from end qf list on stack
  let qfnr = getqflist({'nr':'$'}).nr
  let qfid = getqflist({'nr':qfnr+s:qf_history_incr, 'id':0}).id
  call lsdyna_manager#QfOpen(qfid, 0)
  "call lsdyna_manager#QfOpen(g:lsdyna_quickfix_filter_history[-2], 0)

endfunction

"-------------------------------------------------------------------------------
