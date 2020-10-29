" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2020/10/30
"
" Long Description: {{{1
"
" This plugin integrates the LanguageTool grammar checker into Vim.
" Current version of LanguageTool can check grammar in many languages:
" ar ast, be, br, ca, da, de, el, en, eo, es, fa, fr, ga, gl, it, ja,
" km, nl, pl, pt, ro, ru, sk, sl, sk, sv, ta, tl, uk, zh.
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
com! -nargs=0          LanguageToolClear :call languagetool#Clear()
com! -nargs=0 -range=% LanguageToolCheck :call languagetool#Check(<line1>,
                                                                \ <line2>)
" vim: fdm=marker
