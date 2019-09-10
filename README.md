LanguageTool.nvim
-----------------
[![asciicast](https://asciinema.org/a/265931.svg)](https://asciinema.org/a/265931)

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
from http://www.dicollecte.org are not supported by Vim, but they work well
with LanguageTool. On the other hand, the Vim native spelling checker is
faster and better integrated with Vim.

See http://www.languagetool.org/ for more information about LanguageTool.

# Usage

* Use `:LanguageToolCheck` to check grammar in the current buffer.
  This will check for grammar mistakes and highlight grammar or
  spelling mistakes. The location list for the buffer being
  checked is also populated, so you can use location commands
  such as `:lopen` to open the location list window, `:lne` to
  jump to the next error, etc.

* Use `:LanguageToolSummary` to open a summary window where you can navigate
  errors using `]]` and `[[`, jump to them by hit `<CR>` and fix them by hitting
  `f` on a suggestion.
  
* Use `:LanguageToolClear` to remove highlighting of grammar
  mistakes, close the scratch window containing the list of errors,
  clear and close the location list.

* Use `:help LanguageTool` to get more details on various commands
  and configuration information.

Some commands are also available from the menu in gvim:
```
Plugin -> LanguageTool -> Check
                       -> Clear
```

# Install

## Installing LanguageTool.nvim

You can use any popular plugin manager according to your preference.
For example, with [vim-plug](https://github.com/junegunn/vim-plug),
add this line in your `.vimrc`:
```
Plug 'vigoux/LanguageTool.nvim'
```

## Download LanguageTool

To use this plugin, you need to install the Java LanguageTool grammar
checker. You can choose to:

* Download the standalone version of
  LanguageTool(LanguageTool-\*.zip) from
  [here](http://www.languagetool.org/) using the orange button labeled
  "LanguageTool for standalone for your desktop".

* or download a nightly build LanguageTool-.\*-snapshot.zip from
  http://www.languagetool.org/download/snapshots/. It contains a
  more recent version than the stable version but it is not tested
  as well. 

* or checkout and build the latest LanguageTool from sources in git
  from https://github.com/languagetool-org/languagetool

Recent versions of LanguageTool require Java-8.

# Configuration

Several global variables can be set in your `.vimrc` to configure the behavior
of the LanguageTool plugin.

## `g:languagetool_server`

This variable specifies the location of the LanguageTool java grammar
checker program. Default is empty.
Example:

```vim
:let g:languagetool_server='$HOME/languagetool/languagetool-standalone/target/LanguageTool-3.7-SNAPSHOT/LanguageTool-3.7-SNAPSHOT/languagetool-server.jar'
```

## `g:languagetool`

All LanguageTool configuration goes through this varaible, which is organized
as follows (all lists are comma separated):

```vim
    g:languagetool = {
        '.' : {
            {model1} for all filetypes
        },
        'my_filetype' : {
            {model1} for my_filetype
        }
    }

    {model1} = {
        'enabledRules' : list of enabled rules,
        'disabledRules' : list of disabled rules,
        'enabledCategories' : list of enabled categories,
        'disabledCategories' : list of disabled categories,
        'language' : the code of the language to check,
            as given by :LanguageToolSupportedLanguages
    }
```

Actually, there is more options than those found here, you can found an
exhaustive list here :
https://languagetool.org/http-api/swagger-ui/#!/default/post_check

## Colors

You can customize the following syntax highlighting groups:
```
LanguageToolCmd
LanguageToolErrorCount
LanguageToolLabel
LanguageToolUrl
LanguageToolGrammarError
LanguageToolSpellingError
```
For example, to highlight grammar mistakes in blue, and spelling mistakes in
red, with a curly underline in vim GUIs that support it, add this into your
colorscheme:

```vim
hi LanguageToolGrammarError  guisp=blue gui=undercurl guifg=NONE guibg=NONE ctermfg=white ctermbg=blue term=underline cterm=none
hi LanguageToolSpellingError guisp=red  gui=undercurl guifg=NONE guibg=NONE ctermfg=white ctermbg=red  term=underline cterm=none
```

## Mappings

LanguageTool.nvim provides `<Plug>` mappings for a more convenient usage.

`<Plug>(LanguageToolCheck)` can be used in both normal and insert modes to run a check on current buffer.

## Events

`LanguageTool.nvim` triggers some `User` events:
  * `LanguageToolCheckDone`, which is triggered right after a check is done
  * `LanguageToolServerStarted`, which is triggered right after the server has started

# FAQ

## I want the summary window to open whenever a check is done.
Just add the following lines to you `.vimrc`:
```vim
autocmd User LanguageToolCheckDone LanguageToolSummary
```

## I want the server to start whenever I open a certain filetype
Add this to your `.vimrc` (this example is for `latex` files)
```vim
autocmd Filetype tex LanguageToolSetUp
```

# License

The VIM LICENSE applies to the LanguageTool.vim plugin (see 
`:help copyright` but replace "LanguageTool.vim with "Vim").

LanguageTool is freely available under LGPL.
