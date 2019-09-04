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
        let s:languagetool_lang = LanguageTool#languages#findLanguage(&spelllang)
        if s:languagetool_lang == ''
            let s:languagetool_lang = LanguageTool#languages#findLanguage(v:lang)
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
    let l:file_content = system('cat ' . expand('%'))

    let data = {
              \ 'disabledRules' : s:languagetool_disable_rules,
              \ 'enabledRules'  : s:languagetool_enable_rules,
              \ 'disabledCategories' : s:languagetool_disable_categories,
              \ 'enabledCategories' : s:languagetool_enable_categories,
              \ 'language' : s:languagetool_lang,
              \ 'text' : l:file_content
              \ }

    call LanguageTool#server#check(data, function('LanguageTool#check#callback'))
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
        " Open preview window and jump to it
        pedit LanguageTool
        wincmd P
        setlocal modifiable

        call clearmatches()

        call LanguageTool#errors#prettyprint(l:error)

        let b:error = l:error

        setlocal filetype=languagetool
        setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap nonumber norelativenumber noma
        " Map <CR> to fix error with suggestion at point
        nnoremap <buffer> f :call LanguageTool#fixErrorWithSuggestionAtPoint()<CR>

        " Return to original window
        exe "norm! \<C-W>\<C-P>"
        return
    endif
endfunction

" This function is used to fix error in the preview window using
" the suggestion under cursor
function! LanguageTool#fixErrorWithSuggestionAtPoint() "{{{1
    let l:suggestion_id = LanguageTool#errors#suggestionAtPoint()
    if l:suggestion_id >= 0
        let l:error_to_fix = b:error

        call LanguageTool#errors#fix(l:error_to_fix, l:suggestion_id)
    endif
endfunction

" This function is used to fix the error at point using suggestion nr sug_id
function! LanguageTool#fixErrorAtPoint(sug_id) "{{{1
    call LanguageTool#errors#fix(LanguageTool#errors#find(), a:sug_id)
endfunction

" This functions opens a new window with all errors in the current buffer
" and mappings to navigate to them, and fix them
function! LanguageTool#summary() "{{{1
    let l:errors = b:errors
    " Open a new window
    wincmd v
    enew

    for l:error in l:errors
        call LanguageTool#errors#prettyprint(l:error)
        call append(line('.') - 1, '')
    endfor

    execute '$delete'
    execute 'goto 1'

    " We need to transfer the errors to this buffer
    let b:errors = l:errors

    nnoremap <buffer><silent> <CR> :call LanguageTool#errors#jumpToCurrentError()<CR>
    nnoremap <buffer><silent> f 
                \ :call LanguageTool#errors#fix(
                \ LanguageTool#errors#errorAtPoint(),
                \ LanguageTool#errors#suggestionAtPoint())<CR>
    nnoremap <buffer><silent> q :q<CR>
    nnoremap <buffer><silent> ]] :execute LanguageTool#errors#nextSummary()<CR>
    nnoremap <buffer><silent> [[ :execute LanguageTool#errors#previousSummary()<CR>

    setlocal filetype=languagetool
    setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap nonumber norelativenumber noma
endfunction
