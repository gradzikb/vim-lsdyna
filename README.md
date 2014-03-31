#vim-lsdyna
[VIM](http://www.vim.org/) filetype plugin for [Ls-Dyna](http://www.lstc.com) FE solver.

What is Ls-Dyna filetype plugin?

It's just bunch of scripts for VIM to speed up work with Ls-Dyna keyword file.

##Main features
- Syntax highlighting
- Folding
- Keyword library
- Curve commands
- Useful functions & mappings

###Syntax highlighting
With color syntax it's easier to navigate through the keyword file. Standard 8x10 columns is supported.

![vimLsDynaColorSyntax](https://raw.github.com/wiki/gradzikb/vim-lsdyna/screenshots/vimLsDynaColorSyntax.gif)

###Folding
Node & element table folding, no more never ending scrolling!

![vimLsDynaFold](https://raw.github.com/wiki/gradzikb/vim-lsdyna/screenshots/vimLsDynaFold.gif)

###Keyword library
With keyword library you can very quick add a new Ls-Dyna keyword into your model.

![vimLsDynaKeyLib](https://raw.github.com/wiki/gradzikb/vim-lsdyna/screenshots/vimLsDynaKeyLib.gif)

Visit [keyword library wiki page](https://github.com/gradzikb/vim-lsdyna/wiki/Keyword-Library) to see more.

###Curve commands
You can use commands to operate with a curves data directly in VIM.

![vimLsDynaScale](https://raw.github.com/wiki/gradzikb/vim-lsdyna/screenshots/vimLsDynaScale.gif)

Visit [curve commands wiki page](https://github.com/gradzikb/vim-lsdyna/wiki/Keyword-Library) to meet all commands.

###Functions & mappings
The plugin has couple of useful function to make your work even faster:
- mappings `:help lsdyna-mappings`
- comment/uncomment `:help lsdyna-comment`
- data line autoformating `:help lsdyna-autoFormat`
- text objects `:help lsdyna-textObject`

##Installation

[Pathogen](https://github.com/tpope/vim-pathogen)

```
cd ~/.vim/bundle
git clone https://github.com/gradzikb/vim-lsdyna
```

##Documentation

Please read documentation before you start to use plugin: `:help lsdyna`

Some examples how to use the plugin can be found on [wiki pages](https://github.com/gradzikb/vim-lsdyna/wiki).

##License

The GNU General Public License

Copyright &copy; 2014 Bartosz Gradzik
