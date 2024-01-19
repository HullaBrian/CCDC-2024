"Minimal vimrc for competition use
"show some stats
set number
set ruler

"always show tab characters
set listchars=tab:>.
set list

"set encoding
set encoding=utf-8

"search settings
set incsearch
set hlsearch
set showmatch

"line limit settings
set cc=80,100
set textwidth=100

"last line
set showcmd
set showmode

"backspace settings
set backspace=indent,eol,start

"light mode is evil
set background=dark

syntax enable

filetype plugin indent on
