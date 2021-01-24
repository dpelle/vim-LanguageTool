vim-LanguageTool
----------------

This plugin integrates the LanguageTool grammar checker into Vim.
LanguageTool is an Open Source style and grammar checker for English,
French, German, etc. See http://www.languagetool.org/languages/ for a
complete list of supported languages.

LanguageTool detects grammar mistakes that a spelling checker cannot detect
such as "it work" instead of "it works". LanguageTool can also detect spelling
mistakes using Hunspell dictionaries bundled with LanguageTool for several
languages or using morfologik for other languages.
Vim builtin spelling checker can also of course be used along with
LanguageTool. One advantage of the spelling checker of LanguageTool over
Vim spelling checker, is that it uses the native Hunspell dictionary directly,
so it works even with the latest Hunspell dictionaries containing features
not supported by Vim. For example, the latest French Hunspell dictionaries
from http://www.dicollecte.org are not supported by Vim but they work well
with LanguageTool. On the other hand, the Vim native spelling checker is
faster and better integrated with Vim.

See http://www.languagetool.org/ for more information about LanguageTool.

# Screenshots

These screenshots will give you an idea of what the LanguageTool plugin does:
English

![English](http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png)

![French](http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png)

# Usage

* Use `:LanguageToolCheck` to check grammar in the current buffer.
  This will check for grammar mistakes and highlight grammar or
  spelling mistakes. It also opens a new scratch window with the
  list of errors with further explanations about each error.
  Pressing <Enter> in an error in the scratch buffer will jump to
  that error in the text. The location list for the buffer being
  checked is also populated, so you can use location commands
  such as `:lopen` to open the location list window, `:lne` to
  jump to the next error, etc.
  The `:LanguageToolCheck` command accepts a range. You can for example check
  grammar between lines 100 and 200 in buffer with `:100,200LanguageToolCheck`,
  or check grammar in the visual selection with `:<',>'LanguageToolCheck`.
  The default range is 1,$ (whole buffer).

* Use `:LanguageToolClear` to remove highlighting of grammar
  mistakes, close the scratch window containing the list of errors,
  clear and close the location list.

* Use `:help LanguageTool` to get more details on various commands
  and configuration information.

The two commands are also available from the menu in gvim:
```
Plugin -> LanguageTool -> Check
                       -> Clear
```

# Installation and configuration

To install and configure the vim-LanguageTool plugin, refer to
the documentation:

  https://github.com/dpelle/vim-LanguageTool/blob/master/doc/LanguageTool.txt

# License

The VIM LICENSE applies to the LanguageTool.vim plugin (see 
`:help copyright` but replace "LanguageTool.vim with "Vim").

LanguageTool is freely available under LGPL.
