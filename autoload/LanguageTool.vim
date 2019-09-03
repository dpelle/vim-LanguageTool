" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 03
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
" }}} 1
" This function is used to know if the language is supported or not by the running languagetool server
function! s:languageIsSupported(lang) "{{{1
    if !exists('s:supported_languages')
        let s:supported_languages = LanguageTool#server#get()
    endif

    for l:language in s:supported_languages
        if a:lang ==? l:language.longCode
            return 1
        endif
    endfor

    return 0
endfunction

" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function! s:FindLanguage(lang) "{{{1
  " This replaces things like en_gb en-GB as expected by LanguageTool,
  " only for languages that support variants in LanguageTool.
  let l:language = substitute(substitute(a:lang,
  \  '\(\a\{2,3}\)\(_\a\a\)\?.*',
  \  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
  \  '_', '-', '')

  if s:languageIsSupported(l:language)
    return l:language
  endif

  " Removing the region (if any) and trying again.
  let l:language = substitute(l:language, '-.*', '', '')
  return s:languageIsSupported(l:language) ? l:language : ''
endfunction

" This functions prints all languages supported by the server
function! LanguageTool#supportedLanguages() "{{{1
    if !exists('s:languagetool_setup_done')
        echoerr 'LanguageTool not initialized, please run :LanguageToolSetUp'
        return -1
    endif

    if !exists('s:supported_languages')
        let s:supported_languages = LanguageTool#server#get()
    endif

    let l:language_list = []

    for l:language in s:supported_languages
        call add(l:language_list, l:language.name . ' [' . l:language.longCode . ']')
    endfor

    echomsg join(l:language_list, ', ')
endfunction

" Set up configuration.
" Returns 0 if success, < 0 in case of error.
function! LanguageTool#setup() "{{{1
    let s:languagetool_disable_rules = get(g:, 'languagetool_disable_rules', 'WHITESPACE_RULE,EN_QUOTES')
    let s:languagetool_enable_rules = get(g:, 'languagetool_enable_rules', '')
    let s:languagetool_disable_categories = get(g:, 'languagetool_disable_categories', '')
    let s:languagetool_enable_categories = get(g:, 'languagetool_enable_categories', '')
    let s:languagetool_encoding = &fenc ? &fenc : &enc

    let s:languagetool_server = get(g:, 'languagetool_server', $HOME . '/languagetool/languagetool-server.jar')

    if !filereadable(expand(s:languagetool_server))
        echomsg "LanguageTool cannot be found at: " . s:languagetool_server
        echomsg "You need to install LanguageTool and/or set up g:languagetool_server"
        echomsg "to indicate the location of the languagetool-server.jar file."
        return -1
    endif

    call LanguageTool#server#start(s:languagetool_server)

    let s:languagetool_setup_done = 1

    return 0
endfunction

" Sets up the plugin, but after server startup
" This function is called by server stdout handler just
" after server starts
function! LanguageTool#setupFinish() "{{{1

    " Setting up language...
    if exists('g:languagetool_lang')
        let s:languagetool_lang = g:languagetool_lang
    else
        " Trying to guess language from 'spelllang' or 'v:lang'.
        let s:languagetool_lang = s:FindLanguage(&spelllang)
        if s:languagetool_lang == ''
            let s:languagetool_lang = s:FindLanguage(v:lang)
            if s:languagetool_lang == ''
                echoerr 'Failed to guess language from spelllang=['
                \ . &spelllang . '] or from v:lang=[' . v:lang . ']. '
                \ . 'Defaulting to English (en-US). '
                \ . 'See ":help LanguageTool" regarding setting g:languagetool_lang.'
                let s:languagetool_lang = 'en-US'
            endif
        endif
    endif
endfunction

" Jump to a grammar mistake (called when pressing <Enter>
" on a particular error in scratch buffer).
function! <sid>JumpToCurrentError() "{{{1
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
function! LanguageTool#check() "{{{1
    if !exists('s:languagetool_setup_done')
        echoerr 'LanguageTool not initialized, please run :LanguageToolSetUp'
        return -1
    endif
    call LanguageTool#clear()

    " Using window ID is more reliable than window number.
    " But win_getid() does not exist in old version of Vim.
    let s:languagetool_text_winid = exists('*win_getid')
    \                             ? win_getid() : winnr()
    let l:file_content = system('cat ' . expand('%'))

    let data = {
              \ 'disabledRules' : s:languagetool_disable_rules,
              \ 'enabledRules'  : s:languagetool_enable_rules,
              \ 'disabledCategories' : s:languagetool_disable_categories,
              \ 'enabledCategories' : s:languagetool_enable_categories,
              \ 'language' : s:languagetool_lang,
              \ 'text' : l:file_content
              \ }

    let output = LanguageTool#server#check(data)

    if empty(output)
        return -1
    endif

    " Loop on all errors in output of LanguageTool and
    " collect information about all errors in list s:errors
    let b:errors = output.matches
    for l:error in b:errors

    " There be dragons, this is true blackmagic happening here, we hardpatch offset field of LT
    " {from|to}{x|y} are not provided by LT JSON API, thus we have to compute them
    let l:start_byte_index = byteidxcomp(l:file_content, l:error.offset) + 2 " All errrors are offsetted by 2
    let l:error.fromy = byte2line(l:start_byte_index)
    let l:error.fromx = l:start_byte_index - line2byte(l:error.fromy)
    let l:error.start_byte_idx = l:start_byte_index

    let l:stop_byte_index = byteidxcomp(l:file_content, l:error.offset + l:error.length) + 2
    let l:error.toy = byte2line(l:stop_byte_index)
    let l:error.tox = l:stop_byte_index - line2byte(l:error.toy)
    let l:error.stop_byte_idx = l:stop_byte_index
  endfor

  " Also highlight errors in original buffer and populate location list.
  setlocal errorformat=%f:%l:%c:%m
  for l:error in b:errors
    let l:re = LanguageTool#errors#highlightRegex(l:error.fromy,
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
    \ . l:error.rule.id . ' : ' . l:error.message
  endfor
  return 0
endfunction

" This function clears syntax highlighting created by LanguageTool plugin
" and removes the scratch window containing grammar errors.
function! LanguageTool#clear() "{{{1
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

" This functions shows the error at point in the preview window
function! LanguageTool#showErrorAtPoint() "{{{1
    let error = LanguageTool#errors#find()
    if !empty(error)
        let l:source_win_id = win_getid()
        " Open preview window and jump to it
        pedit LanguageTool
        wincmd P
        setlocal filetype=languagetool
        setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap nonumber norelativenumber

        call LanguageTool#errors#prettyprint(l:error)

        call execute('0delete')

        let b:error = l:error
        let b:error.source_win = l:source_win_id

        " Map <CR> to fix error with suggestion at point
        nnoremap <buffer> <CR> :call LanguageTool#fixErrorWithSuggestionAtPoint()<CR>

        " Return to original window
        exe "norm! \<C-W>\<C-P>"
        return
    endif
endfunction

" This function is used to fix error in the preview window using
" the suggestion under cursor
function! LanguageTool#fixErrorWithSuggestionAtPoint() "{{{1
    let l:suggestion_id = line('.') - (line('$') - len(b:error.replacements)) - 1
    if l:suggestion_id >= 0
        let l:error_to_fix = b:error

        call win_gotoid(b:error.source_win)

        call LanguageTool#errors#fix(l:error_to_fix, l:suggestion_id)
    endif
endfunction

" This function is used to fix the error at point using suggestion nr sug_id
function! LanguageTool#fixErrorAtPoint(sug_id) "{{{1
    call LanguageTool#errors#fix(LanguageTool#errors#find(), a:sug_id)
endfunction
