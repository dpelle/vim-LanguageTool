" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 09
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

" This function reads the file at file path and returns the preprocessed text
" i.e. with the distinction between markup and real text
" For now it reads the file line by line, apply the rules to be applied and returns the text
" with \n as line separator
function! LanguageTool#preprocess#getProcessedText(lines)
    let l:result = []
    for l:line in a:lines
        let l:result = add(l:result, LanguageTool#preprocess#applyRules(l:line))
    endfor

    return join(l:result, ',')
endfunction

" This function applies the rules to the given line, in order
" If none of them applies, the text is considered as only text
" without markup
" For now this is just a function that return the text, it will
" then be used to differentiate markup and text using rules associated with current
" filetype
function! LanguageTool#preprocess#applyRules(line)
    return '{"text":"' . escape(a:line, "\"\\\t") . '\n"}'
endfunction
