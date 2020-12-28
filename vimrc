" vi:ts=2 sw=2 tw=79 et lbr wrap
" Copyright 2016 by David Rabkin

" This must be first, because it changes other options as side effect.
set nocompatible

" Allows utf-8 symbols in the file.
scriptencoding utf-8
set encoding=utf-8

" General.
set hidden                      " Hides buffers instead of closing them.
set linebreak                   " Break lines at word (requires Wrap lines).
set textwidth=79                " Line wrap (number of cols).
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
set tabstop=2                   " Number of spaces per Tab.
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
set listchars=tab:░\ ,extends:»,precedes:«,nbsp:⣿,trail:·
set showbreak="\u21aa "
set list
set splitbelow
set splitright

" Switches on and off relativenumber in hybrid mode.
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * set nu rnu
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * set nornu
augroup END
:nnoremap <silent> <C-n> :set nu! rnu!<cr>

" Configures Pathogen before Colors.
execute pathogen#infect()
let g:syntastic_c_checkers = ['cppcheck']
let g:syntastic_sh_checkers = ['shellcheck']
let g:syntastic_ruby_checkers = ['rubocop']

" Colors.
syntax on                      " Enables syntax processing.
filetype on                    " Enables filetype detection.
filetype indent on             " Enables filetype-specific indenting.
filetype plugin on             " Enables filetype-specific plugins.
colorscheme zenburn

" Highlights for text that goes over the 80 column limit.
highlight OverLength ctermbg=black ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

set pastetoggle=<F2>            " Enables clear paste.
let mapleader=","               " Leader is comma.

" Edit vimrc/zshrc and load vimrc bindings.
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" Turns off search highlight.
nnoremap <leader><space> :nohlsearch<CR>

" Easier split navigations.
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Window.
nmap <leader>sw<left>  :topleft  vnew<CR>
nmap <leader>sw<right> :botright vnew<CR>
nmap <leader>sw<up>    :topleft  new<CR>
nmap <leader>sw<down>  :botright new<CR>
" Buffer.
nmap <leader>s<left>   :leftabove  vsplit<CR>
nmap <leader>s<right>  :rightbelow vsplit<CR>
nmap <leader>s<up>     :leftabove  split<CR>
nmap <leader>s<down>   :rightbelow split<CR>

" This mapping sorts the lines of a paragraph, or block of text separated by
" blank lines. I use this a lot to sort #include directives.
nmap <leader>s vip:sort<CR>

" Similar to the last mapping, this one sorts lines inside braces. I use this to
" sort switch statement cases or array initializers.
nmap <leader>S $vi{:sort<CR>

" Don't pollute directories with swap files, keep them in one place.
silent !mkdir -p ~/.vim/{backup,swp}/
set backupdir=~/.vim/backup//
set directory=~/.vim/swp//
" Except crontab, which will complain that it can't see any changes.
au FileType crontab setlocal bkc=yes

" Allows saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

" Allows saving remote file in case of vim scp://name@host:port/filename.ext.
autocmd BufRead scp://* :set bt=acwrite
autocmd BufWritePost scp://* :set bt=acwrite

" If installed using Homebrew.
set rtp+=/usr/local/opt/fzf

" Provides tab-completion for all file-related tasks.
set path+=**

" Display all matching files when we tab complete.
set wildmenu

" Create the `tags` file (may need to install ctags first).
command! MakeTags !ctags -R .

" Tweaks for browsing.
let g:netrw_banner=0        " disable annoying banner
let g:netrw_browse_split=4  " open in prior window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
