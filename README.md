# vim-lsdyna
[VIM](http://www.vim.org/) filetype plugin for [Ls-Dyna](http://www.lstc.com) FE solver.

## Introduction

The plugin make your work with Ls-Dyna keyword file as fast and as easy as possible.

## Main features
- Syntax highlighting
- Nodes/elements table folding
- Omni-completion for keywords/options/ids/parameters
- Keyword manager
- Numerous commands to operate on model data
- Useful mappings and functions

### Syntax highlighting
Easy navigation with keyword file.

![syntax](https://raw.github.com/wiki/gradzikb/vim-lsdyna/gifs/syntax.gif)

### Nodes/elements table folding
No more never ending scrolling.

![folding](https://raw.github.com/wiki/gradzikb/vim-lsdyna/gifs/folding.gif)

### Omni-completion
Inserting of keywords/options/ids/parameters never was easier.

![omni-completion](https://raw.github.com/wiki/gradzikb/vim-lsdyna/gifs/omni-completion.gif)

### Keyword manager
One tool to rule them all.

![lsmanager](https://raw.github.com/wiki/gradzikb/vim-lsdyna/gifs/lsmanager.gif)

### Commands/functions/mappings
Many great features to update your model directly in VIM.

![commands](https://raw.github.com/wiki/gradzikb/vim-lsdyna/gifs/commands.gif)

## Example

The plugin in action you can see [here](https://www.youtube.com/watch?v=MY9qV8jrkDk&spfreload=10).

## Documentation

Please read [documentation](https://github.com/gradzikb/vim-lsdyna/blob/master/doc/lsdyna.txt) to get know all plugin features.

`:help lsdyna`

## Installation

The plugin required (g)VIM 8.2.1176 or higher.

Installation with (g)VIM native package manager `:help packages`

Windows:
```
mkdir %USERPROFILE%\vimfiles\pack\cae_plugins\start\
cd %USERPROFILE%\vimfiles\pack\cae_plugins\start\
git clone https://github.com/gradzikb/vim-lsdyna
```
Linux
```
mkdir -p ~/.vim/pack/cae_plugins/start/
cd ~/.vim/pack/cae_plugins/start/
git clone https://github.com/gradzikb/vim-lsdyna
```

## License

The GNU General Public License

Copyright &copy; 2021 Bartosz Gradzik
