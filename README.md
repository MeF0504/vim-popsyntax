# vim-popsyntax

Vim function that shows the syntax information under the cursor by the popup window.

![popsyntax](https://raw.githubusercontent.com/MeF0504/vim-popsyntax/main/images/popsyntax.gif)

## Requirements

- popup window
```vim
echo has('popupwin')  " == 1
```

## Installation

if you use dein,
```vim
call dein#add('MeF0504/vim-popsyntax')
```
or do something like this.

## Usage

The following command turns on and off the popup window.
```vim
PopSyntaxToggle
```


