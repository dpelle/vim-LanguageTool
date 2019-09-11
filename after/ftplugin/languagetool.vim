" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 11
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

setlocal foldmethod=syntax
let b:undo_ftplugin += "setlocal foldmethod<"

nnoremap <buffer><silent> <CR> :call LanguageTool#errors#jumpToCurrentError()<CR>
nnoremap <buffer><silent> f 
            \ :call LanguageTool#errors#fix(
            \ LanguageTool#errors#errorAtPoint(),
            \ LanguageTool#errors#suggestionAtPoint())<CR>
nnoremap <buffer><silent> ]] :execute LanguageTool#errors#nextSummary()<CR>
nnoremap <buffer><silent> [[ :execute LanguageTool#errors#previousSummary()<CR>

normal zx
