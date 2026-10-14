" vi:et lbr noet sw=2 ts=2 tw=79 wrap
" SPDX-FileCopyrightText: 2016-2026 David Rabkin
" SPDX-License-Identifier: 0BSD

" Must come first because it changes other options as a side effect.
set nocompatible

" Allows UTF-8 symbols in the file.
scriptencoding utf-8
set encoding=utf-8

" General.
set noexpandtab                 " Keeps tabs instead of spaces.
set hidden                      " Hides buffers instead of closing them.
set linebreak                   " Breaks lines at words (requires wrap).
set textwidth=79                " Wraps lines at this column.
set showmatch                   " Highlights the matching brace.
set visualbell                  " Uses a visual bell instead of beeping.
set hlsearch                    " Highlights all search results.
set incsearch                   " Shows search matches as you type.
set smartcase                   " Enables smart-case search.
set ignorecase                  " Ignores case in searches by default.
set incsearch                   " Searches incrementally while typing.
set autoindent                  " Indents new lines automatically.
set copyindent                  " Copies the previous indent.
set shiftwidth=2                " Sets the number of spaces for auto-indent.
set smartindent                 " Enables smart indent.
set smarttab                    " Enables smart tabs.
set tabstop=2                   " Sets the number of spaces per Tab.
set softtabstop=2               " Sets the spaces per Tab while editing.
set ruler                       " Shows the row and column of the cursor.
set undolevels=1000             " Sets the number of undo levels.
set history=1000                " Remembers more commands and search history.
set backspace=indent,eol,start  " Lets backspace delete indents and breaks.
set nobackup                    " Disables backup files.
set noswapfile                  " Disables swap files.
set title                       " Changes the terminal's title.
set noerrorbells                " Disables error beeps.
set lazyredraw                  " Redraws only when needed.
" Marks tabs, trailing spaces, and wrapped lines.
set listchars=tab:␉·,extends:»,precedes:«,nbsp:⣿,trail:·
set showbreak="\u21aa "
set list                        " Shows the invisible characters.
set splitbelow                  " Opens horizontal splits below.
set splitright                  " Opens vertical splits on the right.

" Toggles relative numbers in hybrid mode.
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * set nu rnu
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * set nornu
augroup END

" Toggles line numbers with Ctrl-N.
:nnoremap <silent> <C-n> :set nu! rnu!<cr>

" Configures Pathogen before the colors.
execute pathogen#infect()

" Shows Syntastic warnings in the status line and selects its checkers.
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_c_checkers = ['cppcheck']
let g:syntastic_cmake_checkers = ['cmakelint']
let g:syntastic_dockerfile_checkers = ['hadolint']
let g:syntastic_go_checkers = ['gofmt']
let g:syntastic_markdown_checkers = ['mdl', 'prroselint', 'textlint']
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_sh_checkers = ['shellcheck', 'shfmt']
let g:syntastic_tex_checkers = ['proselint', 'textlint']
let g:syntastic_yaml_checkers = ['yamllint']

" Colors.
syntax on                      " Enables syntax processing.
filetype on                    " Enables filetype detection.
filetype indent on             " Enables filetype-specific indenting.
filetype plugin on             " Enables filetype-specific plugins.
colorscheme zenburn

" Highlights text that goes over the 79-column limit.
highlight OverLength ctermbg=black ctermfg=white guibg=#592929
match OverLength /\%80v.\+/

set pastetoggle=<F2>            " Toggles paste mode.
let mapleader=","               " Sets the leader key to a comma.

" Edits vimrc or zshrc and reloads vimrc.
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" Turns off search highlight.
nnoremap <leader><space> :nohlsearch<CR>

" Eases navigation between splits.
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Opens an empty window at the edge of the screen.
nmap <leader>sw<left>  :topleft  vnew<CR>
nmap <leader>sw<right> :botright vnew<CR>
nmap <leader>sw<up>    :topleft  new<CR>
nmap <leader>sw<down>  :botright new<CR>

" Splits the current window.
nmap <leader>s<left>   :leftabove  vsplit<CR>
nmap <leader>s<right>  :rightbelow vsplit<CR>
nmap <leader>s<up>     :leftabove  split<CR>
nmap <leader>s<down>   :rightbelow split<CR>

" Sorts the lines of a paragraph, meaning a block of text separated by blank
" lines. Useful for sorting #include directives.
nmap <leader>s vip:sort<CR>

" Sorts the lines inside braces. Useful for sorting switch cases or array
" initializers.
nmap <leader>S $vi{:sort<CR>

" Keeps backup and swap files in one place instead of cluttering directories.
silent !mkdir -p ~/.vim/{backup,swp}/
set backupdir=~/.vim/backup//
set directory=~/.vim/swp//

" Makes an exception for crontab, which complains about unseen changes.
au FileType crontab setlocal bkc=yes

" Allows saving a file as root when Vim was started without sudo.
cmap w!! w !sudo tee > /dev/null %

" Allows saving a remote file opened as scp://name@host:port/filename.ext.
autocmd BufRead scp://* :set bt=acwrite
autocmd BufWritePost scp://* :set bt=acwrite

" Treats redo files as shell scripts.
autocmd BufEnter *.do :setlocal filetype=sh

" Adds fzf to the runtime path when installed with Homebrew.
set rtp+=/usr/local/opt/fzf

" Provides tab-completion for all file-related tasks.
set path+=**

" Displays all matching files when completing with Tab.
set wildmenu

" Creates the `tags` file. Requires ctags.
command! MakeTags !ctags -R .
