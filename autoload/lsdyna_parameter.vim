"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  5th of November 2016
"
"-------------------------------------------------------------------------------
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function s:MatchPairBracketPos(string, start)

  " ----------------------------------------------------------------------------
  " Function to find matching round bracket in string.
  " Arguments:
  " - string : string where to search matching bracket
  " - start  : position where to start search
  "            it must be '(' or ')' position, depend on bracket type function
  "            look forward or backward.
  " Return:
  " - bracket 0 index position in string.
  " ----------------------------------------------------------------------------

  let offset = 0
  let countMatch = 0

  " look forward
  if a:string[a:start] == '('
  
    for i in range(a:start, len(a:string))
      if a:string[i] == '(' | let countMatch += 1 | endif
      if a:string[i] == ')' | let countMatch -= 1 | endif
      if countMatch == 0 | return a:start + offset  | endif
      let offset += 1
    endfor

  " look backward
  elseif a:string[a:start] == ')'
  
    for i in range(a:start, 0, -1)
      if a:string[i] == '(' | let countMatch += 1 | endif
      if a:string[i] == ')' | let countMatch -= 1 | endif
      if countMatch == 0 | return a:start - offset  | endif
      let offset += 1
    endfor

  endif

endfunction

"-------------------------------------------------------------------------------

function s:MatchArgEndPos(string, start, flag)

  " ----------------------------------------------------------------------------
  " Function to find end position of argument which start
  " at a:start in a:string.
  " Arguments:
  " - string : string where to search matching end
  " - start  : start position
  " Return:
  " - end position : end of argument position with 0 index
  " ----------------------------------------------------------------------------

  let reOperator = '[+-/*()]'
  " TODO: re does not cover case like '.5' '.5e+03', it assume it always start
  " with a digit
  let reNumber = '[-+]\?\d\+\.\?\d*\([eE][-+]\?\d\+\)\?'
  let reNumberRev = '\(\d\+[-+]\?[eE]\)\?\d*\.\?\d\+\([-+]$\)\?'

  " look forward from a:start
  if a:flag == 'f'
    
    " operator(arg),  operatorFUNCTION(arg) --> **(2+1), **MIN(1,2)
    if a:string[a:start] =~? '(\|\a'
      return <SID>MatchPairBracketPos(a:string, stridx(a:string, '(', a:start))
    " operatorNUMBER --> **2.0e-03, **-1, **+3.0 **.5
    else
      return matchend(a:string, reNumber, a:start, 1) - 1
    endif

  " look backward from a:start
  elseif a:flag == 'b'

    " (arg1)** or min(arg1)**
    if a:string[a:start] == ')'    
      
      let pos = <SID>MatchPairBracketPos(a:string, a:start)
      " now I move back from bracket position until find operator sign or end
      " of the string
      while pos > 0
        if a:string[pos-1] =~? reOperator | break | endif
        let pos -= 1
      endwhile
      return pos

    " arg1** --> 2**, 2.0**, 2.0+e-03**
    else
      
      " this case force me to match floating point number regular expression
      " looking backward, have no idea how to do it so I reverse string so I 
      " can match regular expression froward, of course re is also reverse
      " 1. 2.0e+03**2
      " 2. 2.0e+03 : cut till operator
      " 3. 30+e0.2 : reverse number and match
      " 4. return start - matchend ( +1 is becasue matchend() return one sign
      " after match end).
      let rev_string = join(reverse(split(a:string[0:a:start], '\zs')), '')
      let match = matchstr(rev_string, reNumberRev, 0, 1)
      return a:start - matchend(rev_string, reNumberRev, 0, 1) + 1

    endif

  endif

endfunction

"-------------------------------------------------------------------------------

function s:Subs_power(string)

  " ----------------------------------------------------------------------------
  " Function to substitute all power functions in a:string.
  " Ls-dyna use synatx X**Y, vim use pow(X,Y)
  " Arguments:
  " - string : string where to make substitute
  " Return:
  " - expr : string after change
  " ----------------------------------------------------------------------------

  let expr=a:string
  "let start = 0
  let idx = 0
  while 1
    let idx = stridx(expr, '**') "oprator position in expression string
    if idx >= 0
      let arg_start = <SID>MatchArgEndPos(expr, idx-1, 'b')
      let arg_end   = <SID>MatchArgEndPos(expr, idx+2, 'f')
      let arg1 = expr[arg_start :   idx-1]
      let arg2 = expr[    idx+2 : arg_end]
      let sub = 'pow('.arg1.','.arg2.')'
      let expr = strpart(expr, 0, arg_start) . sub . strpart(expr, arg_end+1)
    else
      break
    endif
  endwhile

  return expr

endfunction

"-------------------------------------------------------------------------------

function s:Subs_Pi(string)
  let pi = '3.14159653589'
  return substitute(a:string, '\c\(^\|\H\)\zsPI\ze\W', pi, 'g')
endfunction

"-------------------------------------------------------------------------------

function s:Eval_func(string)

  " ----------------------------------------------------------------------------
  " Function to evaluate values of functions in a:string.
  " Arguments:
  " - string : string with expression
  " Return:
  " - expr : string with result of evaluation
  " ----------------------------------------------------------------------------

  " dictionary with user function
  let funcs = {}
  "let funcs.min  = function('<SID>MIN')
  let funcs.min  = {arg1, arg2 -> arg1 < arg2 ? arg1 : arg2}
  let funcs.max  = {arg1, arg2 -> arg1 > arg2 ? arg1 : arg2}
  let funcs.sign = {arg1, arg2 -> arg2 < 0 ? -1.0 * arg1 : arg1}

  " re to find any supported function in expression
  let reFuncName = '\c'.join(keys(funcs),'(\|').'('

  let expr = a:string
  while 1

    " does my expression has any supported function (min(, max(, sign(, ...) ? 
    let idx = match(expr, reFuncName)

    " nope, there is nothing to do here ... bye
    if idx == -1 | break | endif    

    " function name used for eval (min, max, sign, ...), I remove '\|(' from end
    let fname = tolower(matchstr(expr, reFuncName)[0:-2])
  
    " first get function arguments, text between round brackets
    let pos_open_bracket  = stridx(expr, '(', idx)
    let pos_close_bracket = <SID>MatchPairBracketPos(expr, pos_open_bracket)
    let str_args  = expr[pos_open_bracket+1:pos_close_bracket-1]

    "if function arguments includes function name --> make recursive call
    if match(str_args, reFuncName) > -1
      let str_args = <SID>Eval_func(str_args)
    endif

    " eval args valus and return expression value
    let args = str_args->split(',')->map('eval(v:val)')
    let eval = call(funcs[fname], args)

    " substitute function with results
    let str_start = idx
    let str_end   = pos_close_bracket
    let expr = strpart(expr, 0, str_start) . string(eval) . strpart(expr, str_end+1)

  endwhile
  
  return expr

endfunction

"-------------------------------------------------------------------------------

function s:Eval_expression(expr)

  let expr = <SID>Subs_Pi(a:expr)
  let expr = <SID>Subs_power(expr)
  let expr = <SID>Eval_func(expr)
  let eval = eval(expr)
  return string(eval)

endfunction

"-------------------------------------------------------------------------------

function lsdyna_parameter#Eval(expr)

  " find all parameter names in current expression
  let pnames = []
  let start = 0
  while 1
    let match = matchstrpos(a:expr, '\h\w*\ze\([-+*/)]\|$\)', start, 1) 
    if match[1] == -1 | break | endif
    call add(pnames, toupper(match[0]))
    let start = match[2] + 1
  endwhile

  " substitute parameter name to parameter value in expression
  let expr = a:expr
  for pn in pnames
    let expr = substitute(expr, '\c\(^\|\W\)\zs'.pn.'\ze\($\|\W\)', get(g:lsdyna_manager_parameters,pn,pn), 'g')
  endfor

  " evaluate parameter expression, if something gone wrong mark it with question mark
  try
    return <SID>Eval_expression(expr)
  catch
    return '?'
  endtry


endfunction

"-------------------------------------EOF---------------------------------------
