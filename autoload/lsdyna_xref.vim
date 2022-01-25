" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  30.12.2021
" Version:      1.0.0
"
" History of change:
" v1.0.0
"   - Initial version

"-------------------------------------------------------------------------------

function! lsdyna_xref#Xref(what, options) abort

  "-----------------------------------------------------------------------------
  " Quickpeek main function, build popup window.
  "
  " Arguments:
  " - inclFlag (string) : flag to search in include files
  "                       ''  : look only in current buffer
  "                       'i' : look in include files
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " function options
  let options = {}
  let options.includes = get(a:options, 'includes', 0)
 
  " mark 'X' is used with <ESC> mapping, with <ESC> I want to go back to
  " orginal position, or I will be set in qf item position
  normal! mX

  " set string to match
  if !empty(a:what)
    let xref_match = a:what
  else
    let xref_match = lsdyna_parser#Keyword(line('.'), bufnr('%'), '').GetText({'cword':''}).cword
  endif

  " clean up string
  let xref_match = xref_match->substitute('[-&<>]','','g')->trim()
  " saving in search register let me highlight string after x-reference is done
  let @/ = xref_match

  " find any line with xref_match string
  "echo 'Looking reference for '..xref_match..' ...'
  let qfid = lsdyna_vimgrep#Vimgrep(xref_match, #{type:'string', includes:options.includes})
  let vimgrepList = getqflist({'id':qfid, 'items':0}).items

  " I change 'xref_match' later and I want to keep orginal value
  let xref_match_org = xref_match

  " do not match substring if I am looking id
  if xref_match ==? '^\d\+$'
    let xref_match = '^'..xref_match..'$'
  endif

  " parse all keywords which has line with xref_match
  let bufnr_old = 0
  let last_old = 0
  let qflist = []
  for item in vimgrepList

    " skip the same keyword
    if item.bufnr == bufnr_old && item.lnum <= last_old
      continue
    " skip keyword and comment lines
    elseif item.text =~? '^[*$]'
      continue
    endif

    let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, '')
    let bufnr_old = kword.bufnr
    let last_old = kword.last

    " skip if match is span over two columns
    let begin_of_match = kword.GetText({'curcolpos':item.col, 'colnr':0}).colnr
    let end_of_match = kword.GetText({'curcolpos':item.col+len(xref_match_org)-1, 'colnr':0}).colnr
    if begin_of_match != end_of_match
      continue
    endif

    let kwords = kword._Autodetect()

    for kw in kwords

      " exceptions for PARAMETER_EXPRESSION since it hase join all multiple
      " lines already in self.pval
      if kw.name =~? 'PARAMETER_EXPRESSION'
        if kw.pname =~? xref_match || kw.pval =~? xref_match
          let qflist += [kw.Qf()]
        endif
      else
        " single instance kewyword
        if len(kwords) == 1
          let qflist += [kwords[0].Qf()]
        " multi instance keyword
        else
          let datalines = kw.Datalines()
          for lnum in range(1, len(datalines)-1)
            for col in kw.GetText({'textline':datalines[lnum], 'rownr':lnum, 'rowlist':[]}).rowlist
              let col = col->substitute('[-&]','g','')->trim()
              if col =~? xref_match
                let qflist += [kw.Qf()]
                break
              endif
            endfor
          endfor
        endif
      endif
    endfor

  endfor

  if empty(qflist)
    echo 'No x-ref found for "' .. xref_match .. '".'
    return
  endif

  call setqflist([], ' ', #{title           : 'Xref '..xref_match_org,
  \                        items            : qflist,
  \                        quickfixtextfunc : 'lsdyna_xref#Quickfixtextfunc',
  \                        context          : {'type'              :'xref', 
  \                                            'quickfixbufferfunc':function('lsdyna_xref#quickfixbufferfunc')},
  \                       })

  " finally show me Qf window
  let qfid = getqflist({'id':0}).id
  let g:lsdyna_qfid_last = qfid
  call lsdyna_manager#QfOpen(qfid, 0)

  silent call feedkeys(":\<c-u>/\<CR>")

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_xref#Quickfixtextfunc(info)

  "-----------------------------------------------------------------------------
  " Function to format lines in QuickFix window.
  " Arguments:
  " - See :help quickfix-window-function
  " Return:
  " - See :help quickfix-window-function
  "-----------------------------------------------------------------------------

  " get current qf list
  let qf_items = getqflist({'id':a:info.id, 'items':''}).items

  " for each qf list item set a line
  let qf_lines = []
  for idx in range(a:info.start_idx - 1, a:info.end_idx - 1)
    " unpack qftext dictionary
    let kword = eval(qf_items[idx].text)
    " set line
    "if kword->has_key('id')
    "  let id = kword.id -> printf('%10s')
    "elseif kword->has_key('pname')
    "  let id = kword.pname -> printf('%10s')
    "else
    "  let id = '' -> printf('%10s')
    "endif
    let id = kword.id->printf('%10s')
    let title = kword->get('title','')[:49]->printf('%-50s')
    let qf_line =  id .. ' ' .. title .. ' | '..kword.name
    call add(qf_lines, qf_line)
  endfor

  return qf_lines

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_xref#quickfixbufferfunc() abort

  "-----------------------------------------------------------------------------
  " Function to set quickfix window commands. The function ist rigged by
  " autocommadn when quickfix window is loaded.
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  call lsdyna_quickfix#BufferCommands()
  "let &l:statusline = 'Xref'

endfunction

"-------------------------------------------------------------------------------
