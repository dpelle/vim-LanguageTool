" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019/08/14
" Version:      1.32
"
" Long Description: {{{1
"
" This plugin integrates the LanguageTool grammar checker into Vim.
" Current version of LanguageTool can check grammar in many languages:
" ast, be, br, ca, da, de, el, en, eo, es, fa, fr, gl, is, it, ja, km, lt,
" ml, nl, pl, pt, ro, ru, sk, sl, sv, ta, tl, uk, zh.
"
" See doc/LanguageTool.txt for more details about how to use the
" LanguageTool plugin.
"
" See http://www.languagetool.org/ for more information about LanguageTool.
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.vim plugin
" (see ":help copyright" except use "LanguageTool.vim" instead of "Vim").
"
" Plugin set up {{{1
if &cp || exists("g:loaded_languagetool")
 finish
endif
let g:loaded_languagetool = "1"

" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function s:FindLanguage(lang) "{{{1
  " This replaces things like en_gb en-GB as expected by LanguageTool,
  " only for languages that support variants in LanguageTool.
  let l:language = substitute(substitute(a:lang,
  \  '\(\a\{2,3}\)\(_\a\a\)\?.*',
  \  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
  \  '_', '-', '')

  " All supported languages (with variants) from version LanguageTool.
  let l:supportedLanguages =  {
  \  'ast'   : 1,
  \  'be'    : 1,
  \  'br'    : 1,
  \  'ca'    : 1,
  \  'cs'    : 1,
  \  'da'    : 1,
  \  'de'    : 1,
  \  'de-AT' : 1,
  \  'de-CH' : 1,
  \  'de-DE' : 1,
  \  'el'    : 1,
  \  'en'    : 1,
  \  'en-AU' : 1,
  \  'en-CA' : 1,
  \  'en-GB' : 1,
  \  'en-NZ' : 1,
  \  'en-US' : 1,
  \  'en-ZA' : 1,
  \  'eo'    : 1,
  \  'es'    : 1,
  \  'fa'    : 1,
  \  'fr'    : 1,
  \  'gl'    : 1,
  \  'is'    : 1,
  \  'it'    : 1,
  \  'ja'    : 1,
  \  'km'    : 1,
  \  'lt'    : 1,
  \  'ml'    : 1,
  \  'nl'    : 1,
  \  'pl'    : 1,
  \  'pt'    : 1,
  \  'pt-BR' : 1,
  \  'pt-PT' : 1,
  \  'ro'    : 1,
  \  'ru'    : 1,
  \  'sk'    : 1,
  \  'sl'    : 1,
  \  'sv'    : 1,
  \  'ta'    : 1,
  \  'tl'    : 1,
  \  'uk'    : 1,
  \  'zh'    : 1
  \}

  if has_key(l:supportedLanguages, l:language)
    return l:language
  endif

  " Removing the region (if any) and trying again.
  let l:language = substitute(l:language, '-.*', '', '')
  return has_key(l:supportedLanguages, l:language) ? l:language : ''
endfunction

" Return a regular expression used to highlight a grammatical error
" at line a:line in text.  The error starts at character a:start in
" context a:context and its length in context is a:len.
function s:LanguageToolHighlightRegex(line, context, start, len)  "{{{1
  let l:start_idx     = byteidx(a:context, a:start)
  let l:end_idx       = byteidx(a:context, a:start + a:len) - 1
  let l:start_ctx_idx = byteidx(a:context, a:start + a:len)
  let l:end_ctx_idx   = byteidx(a:context, a:start + a:len + 5) - 1

  " The substitute allows matching errors which span multiple lines.
  " The part after \ze gives a bit of context to avoid spurious
  " highlighting when the text of the error is present multiple
  " times in the line.
  return '\V'
  \     . '\%' . a:line . 'l'
  \     . substitute(escape(a:context[l:start_idx : l:end_idx], "'\\"), ' ', '\\_\\s', 'g')
  \     . '\ze'
  \     . substitute(escape(a:context[l:start_ctx_idx : l:end_ctx_idx], "'\\"), ' ', '\\_\\s', 'g')
endfunction

" Set up configuration.
" Returns 0 if success, < 0 in case of error.
function s:LanguageToolSetUp() "{{{1
  let s:languagetool_disable_rules = exists("g:languagetool_disable_rules")
  \ ? g:languagetool_disable_rules
  \ : 'WHITESPACE_RULE,EN_QUOTES'
  let s:languagetool_enable_rules = exists("g:languagetool_enable_rules")
  \ ? g:languagetool_enable_rules
  \ : ''
  let s:languagetool_disable_categories = exists("g:languagetool_disable_categories")
  \ ? g:languagetool_disable_categories
  \ : ''
  let s:languagetool_enable_categories = exists("g:languagetool_enable_categories")
  \ ? g:languagetool_enable_categories
  \ : ''
  let s:languagetool_win_height = exists("g:languagetool_win_height")
  \ ? g:languagetool_win_height
  \ : 14
  let s:languagetool_encoding = &fenc ? &fenc : &enc

  " Setting up language...
  if exists("g:languagetool_lang")
    let s:languagetool_lang = g:languagetool_lang
  else
    " Trying to guess language from 'spelllang' or 'v:lang'.
    let s:languagetool_lang = s:FindLanguage(&spelllang)
    if s:languagetool_lang == ''
      let s:languagetool_lang = s:FindLanguage(v:lang)
      if s:languagetool_lang == ''
        echoerr 'Failed to guess language from spelllang=['
        \ . &spelllang . '] or from v:lang=[' . v:lang . ']. '
        \ . 'Defauling to English (en-US). '
        \ . 'See ":help LanguageTool" regarding setting g:languagetool_lang.'
        let s:languagetool_lang = 'en-US'
      endif
    endif
  endif

  let s:languagetool_jar = exists("g:languagetool_jar")
  \ ? g:languagetool_jar
  \ : $HOME . '/languagetool/languagetool-commandline.jar'

  if !filereadable(s:languagetool_jar)
    " Hmmm, can't find the jar file.  Try again with expand() in case user
    " set it up as: let g:languagetool_jar = '$HOME/languagetool-commandline.jar'
    let l:languagetool_jar = expand(s:languagetool_jar)
    if !filereadable(expand(l:languagetool_jar))
      echomsg "LanguageTool cannot be found at: " . s:languagetool_jar
      echomsg "You need to install LanguageTool and/or set up g:languagetool_jar"
      echomsg "to indicate the location of the languagetool-commandline.jar file."
      return -1
    endif
    let s:languagetool_jar = l:languagetool_jar
  endif
  return 0
endfunction

" Jump to a grammar mistake (called when pressing <Enter>
" on a particular error in scratch buffer).
function <sid>JumpToCurrentError() "{{{1
  let l:save_cursor = getpos('.')
  norm! $
  if search('^Error:\s\+', 'beW') > 0
    let l:error_idx = expand('<cword>')
    let l:error = s:errors[l:error_idx - 1]
    let l:line = l:error['fromy']
    let l:col  = l:error['fromx']
    let l:rule = l:error['ruleId']
    call setpos('.', l:save_cursor)
    if exists('*win_gotoid')
      call win_gotoid(s:languagetool_text_winid)
    else
      exe s:languagetool_text_winid . ' wincmd w'
    endif
    exe 'norm! ' . l:line . 'G0'
    if l:col > 0
      exe 'norm! ' . (l:col  - 1) . 'l'
    endif

    echon 'Jump to error ' . l:error_idx . '/' . len(s:errors)
    \ . ' ' . l:rule . ' @ ' . l:line . 'L ' . l:col . 'C'
    norm! zz
  else
    call setpos('.', l:save_cursor)
  endif
endfunction

" This function performs grammar checking of text in the current buffer.
" It highlights grammar mistakes in current buffer and opens a scratch
" window with all errors found.  It also populates the location-list of
" the window with all errors.
" a:line1 and a:line2 parameters are the first and last line number of
" the range of line to check.
" Returns 0 if success, < 0 in case of error.
function s:LanguageToolCheck(line1, line2) "{{{1
  if s:LanguageToolSetUp() < 0
    return -1
  endif
  call s:LanguageToolClear()

  " Using window ID is more reliable than window number.
  " But win_getid() does not exist in old version of Vim.
  let s:languagetool_text_winid = exists('*win_getid')
  \                             ? win_getid() : winnr()
  sil %y
  botright new
  set modifiable
  let s:languagetool_error_buffer = bufnr('%')
  sil put!

  " LanguageTool somehow gives incorrect line/column numbers when
  " reading from stdin so we need to use a temporary file to get
  " correct results.
  let l:tmpfilename = tempname()
  let l:tmperror    = tempname()

  let l:range = a:line1 . ',' . a:line2
  silent exe l:range . 'w!' . l:tmpfilename

  let l:languagetool_cmd = 'java'
  \ . ' -jar '  . s:languagetool_jar
  \ . ' -c '    . s:languagetool_encoding
  \ . (empty(s:languagetool_disable_rules) ? '' : ' -d '.s:languagetool_disable_rules)
  \ . (empty(s:languagetool_enable_rules) ?  '' : ' -e '.s:languagetool_enable_rules)
  \ . (empty(s:languagetool_disable_categories) ? '' : ' --disablecategories '.s:languagetool_disable_categories)
  \ . (empty(s:languagetool_enable_categories) ?  '' : ' --enablecategories '.s:languagetool_enable_categories)
  \ . ' -l '    . s:languagetool_lang
  \ . ' --json ' . l:tmpfilename
  \ . ' 2> '    . l:tmperror

  " Let json magic happen
  let output = json_decode(system(l:languagetool_cmd))

  if v:shell_error
    echoerr 'Command [' . l:languagetool_cmd . '] failed with error: '
    \      . v:shell_error
    if filereadable(l:tmperror)
      echoerr string(readfile(l:tmperror))
    endif
    call delete(l:tmperror)
    call s:LanguageToolClear()
    return -1
  endif
  call delete(l:tmperror)

  " Loop on all errors in output of LanguageTool and
  " collect information about all errors in list s:errors
  let s:errors = output.matches
  for l:error in s:errors
    " {from|to}{x|y} are not provided by LT JSON API, thus we have to compute them
    " Make also line number absolute as in buffer.
    let l:start_byte_index = byteidx(system("cat " . expand(l:tmpfilename)), l:error.offset) + 1
    let l:error.fromy = byte2line(l:start_byte_index) + a:line1 - 1
    let l:error.fromx = l:start_byte_index - line2byte(l:error.fromy) + 1

    let l:stop_byte_index = byteidx(system("cat " . expand(l:tmpfilename)), l:error.offset + l:error.length - 1) + 1
    let l:error.toy = byte2line(l:stop_byte_index) + a:line1 - 1
    let l:error.tox = l:stop_byte_index - line2byte(l:error.toy) + 1
  endfor
  call delete(l:tmpfilename)

  if s:languagetool_win_height >= 0
    " Reformat the output of LanguageTool (JSON is not human friendly) and
    " set up syntax highlighting in the buffer which shows all errors.
    %d
    call append(0, '# ' . l:languagetool_cmd)
    set bt=nofile
    setlocal nospell
    syn clear
    call matchadd('LanguageToolCmd',        '\%1l.*')
    call matchadd('LanguageToolErrorCount', '^Error:\s\+\d\+/\d\+')
    call matchadd('LanguageToolLabel',      '^\(Context\|Message\|Correction\|URL\):')
    call matchadd('LanguageToolUrl',        '^URL:\s*\zs.*')

    let l:i = 1
    for l:error in s:errors
      call append('$', 'Error:      '
      \ . l:i . '/' . len(s:errors)
      \ . ' '  . l:error.rule.id . ((len(l:error.rule.category.id) ==  0) ? '' : ':') . l:error.rule.category.id
      \ . ' @ ' . l:error.fromy . 'L ' . l:error.fromx . 'C')
      call append('$', 'Message:    '     . l:error.message)
      call append('$', 'Context:    ' . l:error.context.text)
      let l:re =
      \   '\%'  . line('$') . 'l\%9c'
      \ . '.\{' . (4 + l:error.context.offset) . '}\zs'
      \ . '.\{' .     (l:error.context.length) . '}'
      if l:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
        call matchadd('LanguageToolSpellingError', l:re)
      else
        call matchadd('LanguageToolGrammarError', l:re)
      endif
      if !empty(l:error.replacements)
        call append('$', 'Correction: ' . l:error.replacements)
      endif
      if !empty(l:error.rule.urls)
        call append('$', 'URL:        ' . l:error.rule.urls)
      endif
      call append('$', '')
      let l:i += 1
    endfor
    exe "norm! z" . s:languagetool_win_height . "\<CR>"
    0
    map <silent> <buffer> <CR> :call <sid>JumpToCurrentError()<CR>
    redraw
    echon 'Press <Enter> on error in scratch buffer to jump its location'
    exe "norm! \<C-W>\<C-P>"
  else
    " Negative s:languagetool_win_height -> no scratch window.
    bd!
    unlet! s:languagetool_error_buffer
  endif

  " Also highlight errors in original buffer and populate location list.
  setlocal errorformat=%f:%l:%c:%m
  for l:error in s:errors
    let l:re = s:LanguageToolHighlightRegex(l:error.fromy,
    \                                       l:error.context.text,
    \                                       l:error.context.offset,
    \                                       l:error.context.length)
    if l:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
      call matchadd('LanguageToolSpellingError', l:re)
    else
      call matchadd('LanguageToolGrammarError', l:re)
    endif
    laddexpr expand('%') . ':'
    \ . l:error.fromy . ':'  . l:error.fromx . ':'
    \ . l:error.rule.id . ' ' . l:error.message
  endfor
  return 0
endfunction

" This function clears syntax highlighting created by LanguageTool plugin
" and removes the scratch window containing grammar errors.
function s:LanguageToolClear() "{{{1
  if exists('s:languagetool_error_buffer')
    if bufexists(s:languagetool_error_buffer)
      sil! exe "bd! " . s:languagetool_error_buffer
    endif
  endif
  if exists('s:languagetool_text_winid')
    let l:win = winnr()
    " Using window ID is more reliable than window number.
    " But win_getid() does not exist in old version of Vim.
    if exists('*win_gotoid')
      call win_gotoid(s:languagetool_text_winid)
    else
      exe s:languagetool_text_winid . ' wincmd w'
    endif
    call setmatches(filter(getmatches(), 'v:val["group"] !~# "LanguageTool.*Error"'))
    lexpr ''
    lclose
    exe l:win . ' wincmd w'
  endif
  unlet! s:languagetool_error_buffer
  unlet! s:languagetool_text_winid
endfunction

hi def link LanguageToolCmd           Comment
hi def link LanguageToolErrorCount    Title
hi def link LanguageToolLabel         Label
hi def link LanguageToolUrl           Underlined
hi def link LanguageToolGrammarError  Error
hi def link LanguageToolSpellingError WarningMsg

" Menu items {{{1
if has("gui_running") && has("menu") && &go =~# 'm'
  amenu <silent> &Plugin.LanguageTool.Chec&k :LanguageToolCheck<CR>
  amenu <silent> &Plugin.LanguageTool.Clea&r :LanguageToolClear<CR>
endif

" Defines commands {{{1
com! -nargs=0          LanguageToolClear :call s:LanguageToolClear()
com! -nargs=0 -range=% LanguageToolCheck :call s:LanguageToolCheck(<line1>,
                                                                 \ <line2>)
" vim: fdm=marker
