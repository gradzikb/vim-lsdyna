#vim-lsdyna
VIM filetype plugin for [Ls-Dyna](http://www.lstc.com) FE solver.

What is Ls-Dyna filetype plugin? It's just a bunch of scripts for VIM text editor I am made to speed up work with Ls-Dyna.

##Main features
- Syntax highlighting
- Folding
- Keyword library
- Curve commands
- Useful functions & mappings

###Keyword library
With keyword library you can very quick add a new Ls-Dyna keyword into your model.

![vimLsDynaKeyLib](https://raw.github.com/wiki/gradzikb/vim-lsdyna/screenshots/vimLsDynaKeyLib.gif)

###Curve commands
You can use commands to operate with a curves data directly in VIM.
- LsDynaScale
- LsDynaShift
- LsDynaResample
- LsDynaAddPoint

Example of use you will find on [wiki page](https://github.com/gradzikb/vim-lsdyna/wiki/Curve-Commands).

##Installation

[Pathogen](https://github.com/tpope/vim-pathogen)

```
cd ~/.vim/bundle
git clone https://github.com/gradzikb/vim-lsdyna
```

##Documentation

It is highly recommended to read the documentation to know and understand all the plugin features.

`:help lsdyna`

Some basic introduction to main plugin features can be found also on [wiki pages](https://github.com/gradzikb/vim-lsdyna/wiki).

##License

The GNU General Public License

Copyright &copy; 2014 Bartosz Gradzik
