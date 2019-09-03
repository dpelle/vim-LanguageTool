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

" This functions finds the error at point
function! LanguageTool#errors#find() "{{{1
    if !exists('b:errors')
        echoerr 'Please run :LanguageToolCheck'
        return {}
    endif
    let line_byte_index = line2byte('.')
    let current_col = col('.')

    let current_byte_idx = line_byte_index + current_col

    for l:error in b:errors
        if error.start_byte_idx <= current_byte_idx && error.stop_byte_idx >= current_byte_idx
            return l:error
        endif
    endfor
    return {}
endfunction

" This functions appends a pretty printed version of current error at the end of the current buffer
function! LanguageTool#errors#prettyprint(error) "{{{1
    call append(line('.') - 1, 'Error:      '
                \ . (a:error.index + 1) . ' / ' . a:error.nr_errors
              \ . ' '  . a:error.rule.id . ( !has_key(a:error.rule, 'subId') ? '' : (':' . a:error.rule['subId']))
              \ . ' @ ' . a:error.fromy . 'L ' . a:error.fromx . 'C')
    call append(line('.') - 1, 'Message:    '     . a:error.message)
    call append(line('.') - 1, 'Context:    ' . a:error.context.text)

    call clearmatches()

    let l:re = LanguageTool#errors#highlightRegex(
                \ line('.') - 1,
                \ a:error.context.text,
                \ a:error.context.offset,
                \ a:error.context.length)

    if a:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
        call matchadd('LanguageToolSpellingError', l:re)
    else
        call matchadd('LanguageToolGrammarError', l:re)
    endif

    if has_key(a:error, 'urls')
        call append(line('.') - 1, 'URL:        ' . a:error.urls[0].value)
    endif
    if has_key(a:error, 'replacements')
        call append(line('.') - 1, 'Corrections:')
        for l:replacement in a:error.replacements
            call append(line('.') - 1, '    ' . l:replacement.value)
        endfor
    endif
endfunction

" Return a regular expression used to highlight a grammatical error
" at line a:line in text.  The error starts at character a:start in
" context a:context and its length in context is a:len.
function! LanguageTool#errors#highlightRegex(line, context, start, len)  "{{{1
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

" This function uses suggestion sug_id to fix error error
function! LanguageTool#errors#fix(error, sug_id) "{{{1
    let l:location_regex = LanguageTool#errors#highlightRegex(
                \ a:error.fromy,
                \ a:error.context.text,
                \ a:error.context.offset,
                \ a:error.context.length)
    let l:fix = a:error.replacements[a:sug_id].value

    call win_gotoid(a:error.source_win)
    " This is temporary, we might want to use / only if it is not present
    " in any of l:location_regex and l:fix
    execute 's/' . l:location_regex . '/' . l:fix . '/'
endfunction

" This function is used on the description of an error to get the underlying data
function! LanguageTool#errors#errorAtPoint() "{{{1
    let l:save_cursor = getpos('.')
    norm! $
    if search('^Error:\s\+', 'beW') > 0
        let l:error_idx = expand('<cword>')
        let l:error = b:errors[l:error_idx - 1]
        call setpos('.', l:save_cursor)
        return l:error
    endif
    return {}
endfunction

" This function returns the index of the suggestion at point
function! LanguageTool#errors#suggestionAtPoint() "{{{1
    return line('.') - search('Corrections:', 'bn') - 1
endfunction

" Jump to a grammar mistake (called when pressing <Enter>
" on a particular error in scratch buffer).
function! LanguageTool#errors#jumpToCurrentError() "{{{1
    let l:error = LanguageTool#errors#errorAtPoint()
    if !empty(l:error)
        let l:line = l:error.fromy
        let l:col  = l:error.fromx
        let l:rule = l:error.rule.id
        if exists('*win_gotoid')
            call win_gotoid(l:error.source_win)
        else
            exe l:error.source_win . ' wincmd w'
        endif
        exe 'norm! ' . l:line . 'G0'
        if l:col > 0
            exe 'norm! ' . (l:col  - 1) . 'l'
        endif

        echon 'Jump to error ' . (l:error.index + 1) . '/' . l:error.nr_errors
        \ . ' ' . l:rule . ' @ ' . l:line . 'L ' . l:col . 'C'
        norm! zz
    endif
endfunction
