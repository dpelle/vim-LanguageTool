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

    let l:re = LanguageTool#errors#highlightRegex(line('.') - 1, a:error)

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
function! LanguageTool#errors#highlightRegex(line, error)  "{{{1
    let l:start_idx     = byteidxcomp(a:error.context.text, a:error.context.offset)
    let l:end_idx       = byteidxcomp(a:error.context.text, a:error.context.offset + a:error.context.length) - 1
    let l:start_ctx_idx = byteidxcomp(a:error.context.text, a:error.context.offset + a:error.context.length)
    let l:end_ctx_idx   = byteidxcomp(a:error.context.text, a:error.context.offset + a:error.context.length + 5) - 1

    " The location prefix is used to match only at the point of the actual
    " error and not multiple times accross the line/text
    if a:line != a:error.fromy
        let l:location_prefix = '\%' . a:line . 'l\&'
    elseif a:error.fromy == a:error.toy
        let l:location_prefix = '\%' . a:error.fromy . 'l'
                    \ . '\%>' . (a:error.fromx - 1) . 'c'
                    \ . '\%<' . (a:error.tox + 1) . 'c'
                    \ . '\&'
    else
        let l:location_prefix = '\(\%' . a:error.fromy . 'l\%>' . (a:error.fromx - 1) . 'c\|'
                    \ . '\%>' . a:error.fromy . 'l\%<' . a:error.toy . 'l\|'
                    \ . '\%' . a:error.toy . 'l\%<' . (a:error.tox + 1) . 'c\)\&'
    endif

    " The substitute allows matching errors which span multiple lines.
    " We use \< and \> because all errors start at the beginning of
    " a word and end at the end of a word
    return  '\V' . l:location_prefix . '\<'
    \     . substitute(escape(a:error.context.text[l:start_idx : l:end_idx], "'\\"), ' ', '\\_\\s', 'g')
    \     . '\>\ze'
endfunction

" This function uses suggestion sug_id to fix error error
function! LanguageTool#errors#fix(error, sug_id) "{{{1
    let l:location_regex = LanguageTool#errors#highlightRegex(a:error.fromy, a:error)
    let l:fix = a:error.replacements[a:sug_id].value

    call win_gotoid(a:error.source_win)
    " This is temporary, we might want to use / only if it is not present
    " in any of l:location_regex and l:fix
    execute a:error.fromy . ',' . a:error.toy . 's/' . l:location_regex . '/' . l:fix . '/'
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

" This function returns the line number of the previous start of error summary
function! LanguageTool#errors#previousSummary()
    return search('^Error:\s\+', 'bn')
endfunction


" This function returns the line number of the next start of error summary
function! LanguageTool#errors#nextSummary()
    return search('^Error:\s\+', 'n')
endfunction
