" This must be first, because it changes other options as side effect.
set nocompatible

" General.
set hidden                      " Hides buffers instead of closing them.
set nowrap                      " Don't wrap lines.
set linebreak                   " Break lines at word (requires Wrap lines).
set showbreak=+++               " Wrap-broken line prefix.
set textwidth=80                " Line wrap (number of cols).
set showmatch                   " Highlight matching brace.
set visualbell                  " Use visual bell (no beeping).

set hlsearch                    " Highlights all search results.
set incsearch                   " Shows search matches as you type.
set smartcase                   " Enable smart-case search.
set ignorecase                  " Always case-insensitive.
set incsearch                   " Searches for strings incrementally.

set autoindent                  " Auto-indent new lines.
set copyindent                  " Copy previous indentation on autoindenting.
set expandtab                   " Use spaces instead of tabs.
set shiftwidth=2                " Number of auto-indent spaces.
set smartindent                 " Enable smart-indent.
set smarttab                    " Enable smart-tabs.
set softtabstop=2               " Number of spaces per Tab.
set ruler                       " Show row and column ruler information.

set undolevels=1000             " Number of undo levels.
set history=1000                " Remembers more commands and search history.
set backspace=indent,eol,start  " Backspace behaviour.
set nobackup
set noswapfile
set title                       " Changes the terminal's title.
set noerrorbells                " Don't beep.
set lazyredraw                  " Redraw only when we need to.
set nocompatible                " We're running Vim, not Vi!

set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·
set showbreak=↪\
set list

" Colors.
colorscheme zenburn
syntax enable                  " Enables syntax processing.
filetype on                    " Enable filetype detection
filetype indent on             " Enable filetype-specific indenting
filetype plugin on             " Enable filetype-specific plugins

" Highlights for text that goes over the 80 column limit.
highlight OverLength ctermbg=black ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

set pastetoggle=<F2>            " Enables clear paste.

"Plugins.
set runtimepath^=~/.vim/bundle/ctrlp.vim
set runtimepath^=~/.vim/bundle/ag

let mapleader=","       " leader is comma.

" Edit vimrc/zshrc and load vimrc bindings.
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" Turns off search highlight.
nnoremap <leader><space> :nohlsearch<CR>

set backup
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set backupskip=/tmp/*,/private/tmp/*
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set writebackup

" Allows saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %
