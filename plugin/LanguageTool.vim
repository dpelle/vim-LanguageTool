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


" Plugin set up {{{1
if &cp || exists("g:loaded_languagetool")
 finish
endif
let g:loaded_languagetool = "1"
" }}}1

" Highligths {{{1
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
command! -nargs=0 LanguageToolClear :call LanguageTool#clear()
command! -nargs=0 LanguageToolCheck :call LanguageTool#check()
command! -nargs=0 LanguageToolSetUp :call LanguageTool#setup()
command! -nargs=0 LanguageToolErrorAtPoint :call LanguageTool#showErrorAtPoint()
command! -nargs=0 LanguageToolSupportedLanguages :call LanguageTool#supportedLanguages()
command! -nargs=0 -count=0 LanguageToolFixAtPoint :call LanguageTool#fixErrorAtPoint(<count>)

" Autocommands {{{1
autocmd VimLeave * call LanguageTool#server#stop()

" vim: fdm=marker
