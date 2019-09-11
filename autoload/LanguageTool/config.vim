" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Thomas Vigouroux <tomvig38@gmail.com>
" Last Change:  2019 Sep 11
" Version:      1.0
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.nvim plugin
" (see ":help copyright" except use "LanguageTool.nvim" instead of "Vim").
"
" }}} 1

" This function returns the config dict for the current filetype
function! LanguageTool#config#get() " {{{1
    if !exists('s:default')
        call LanguageTool#config#setup()
    endif

    let l:config = copy(s:default)

    if exists('g:languagetool') && !empty(g:languagetool)
        if has_key(g:languagetool, '.')
            call extend(l:config, g:languagetool['.'])
        endif

        for l:key in keys(g:languagetool)
            if &filetype =~? l:key && l:key !=? '.'
                call extend(l:config, g:languagetool[l:key])
            endif
        endfor
    endif

    return l:config
endfunction

" This function sets up defaults for the config
function! LanguageTool#config#setup() "{{{1
    let s:default = {
                \ 'disabledRules' : 'WHITESPACE_RULE,EN_QUOTES',
                \ 'enabledRules' : '',
                \ 'disabledCategories': '',
                \ 'enabledCategories' : '',
                \ }

    " Setting up language...
    " Trying to guess language from 'spelllang' or 'v:lang'.
    let l:lang = LanguageTool#languages#findLanguage(&spelllang)
    if l:lang == ''
        let l:lang = LanguageTool#languages#findLanguage(v:lang)
        if l:lang == ''
            echoerr 'Failed to guess language from spelllang=['
            \ . &spelllang . '] or from v:lang=[' . v:lang . ']. '
            \ . 'Defaulting to English (en-US). '
            \ . 'See ":help LanguageTool" regarding setting g:languagetool_lang.'
            let l:lang = 'en-US'
        endif
    endif

    let s:default.language = l:lang
endfunction
