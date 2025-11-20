"
" A (not so) minimal vimrc.
"You want Vim, not vi. When Vim finds a vimrc, 'nocompatible' is set anyway.
" We set it explicitely to make our position clear!
"
set nocompatible

filetype plugin indent on  " Load plugins according to detected filetype.
syntax on                  " Enable syntax highlighting.
syntax enable


set autoindent             " Indent according to previous line.
set expandtab              " Use spaces instead of tabs.
set softtabstop=4         " Tab key indents by 4 spaces.
set shiftwidth=4         " >> indents by 4 spaces.
set shiftround             " >> indents to next multiple of 'shiftwidth'.

set backspace=indent,eol,start  " Make backspace work as you would expect.
set hidden                 " Switch between buffers without having to save first.
set laststatus=2         " Always show statusline.
set display=lastline  " Show as much as possible of the last line.

set showmode               " Show current mode in command-line.
set showcmd                " Show already typed keys when more are expected.

set incsearch              " Highlight while searching with / or ?.
set hlsearch               " Keep matches highlighted.

set ttyfast                " Faster redrawing.
set lazyredraw             " Only redraw when necessary.

set splitbelow             " Open new windows below the current window.
set splitright             " Open new windows right of the current window.

set cursorline             " Find the current line quickly.
set wrapscan               " Searches wrap around end-of-file.
set report=0         " Always report changed lines.
set synmaxcol=200       " Only highlight the first 200 columns.
set nu                     " number of line
set list                   " Show non-printable characters.

set wildmenu               " Visual autocomplete for command menu
set showmatch              " Highlight matching [{()}]
set hlsearch               " Highlight matches

set mouse=a                 "let mouse to visual
set fileencodings=utf-8,ucs-bom,big5,cp936,gb18030,gb2312,euc-jp,euc-kr,latin1
set clipboard=unnamed
set nospell


augroup files
    autocmd!
    autocmd FileType html,javascript setlocal shiftwidth=2 tabstop=2
    autocmd FileType python,php,c,cpp,java setlocal expandtab shiftwidth=4 softtabstop=4
    autocmd FileType c,cpp,java set mps+==:;
    autocmd BufNewFile,BufFilePre,BufRead *.md setlocal noautoindent nocindent nosmartindent
augroup END


let mapleader=" "          " Leader is comma
" Turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>
" Save session
nnoremap <leader>ms :mksession<CR>
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <leader>\ :tab term ++close<cr>
"nnoremap <leader>- :set spell<cr>
"nnoremap <leader>= :set nospell<cr>
nnoremap <C-\> :term ++close<cr>
nnoremap <Esc>\ :tab term ++close<cr>

function! MultiLineEditToEndColumn()
    " 获取当前光标的列位置
    let current_col = col('.')

    " 进入视觉块模式，确保通过 Vim 脚本正确发送 Ctrl-V
    execute "normal! \<C-V>"

    " 跳到文件末尾
    normal! G

    " 移动到初始列，保持列不变
    execute "normal! " . current_col . "|"
endfunction

" 绑定到一个快捷键，这里我用的是 <leader>e
nnoremap <leader>e :call MultiLineEditToEndColumn()<CR>





if has('multi_byte') && &encoding ==# 'utf-8'
  let &listchars = 'tab:▸ ,extends:❯,precedes:❮,nbsp:±'
else
  let &listchars = 'tab:> ,extends:>,precedes:<,nbsp:.'
endif

" The fish shell is not very compatible to other shells and unexpectedly
" breaks things that use 'shell'.
if &shell =~# 'fish$'
  set shell=/bin/bash
endif

" Put all temporary files under the same directory.
" https://github.com/mhinz/vim-galore#handling-backup-swap-undo-and-viminfo-files
"

if !isdirectory($HOME.'/.vim/files') && exists('*mkdir')
  call mkdir($HOME.'/.vim/files')
endif
set backup
set backupdir=$HOME/.vim/files/backup/
set backupext=-vimbackup
set backupskip=
set updatecount=100
set undofile
set undodir=$HOME/.vim/files/undo/
set viminfo='100,n$HOME/.vim/files/info/viminfo
set directory=$HOME/.vim/files/swap/

" Plugins
if has('vim') && empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


call plug#begin('~/.vim/plugged')

Plug 'https://github.com/altercation/Vim-colors-solarized'
Plug 'preservim/nerdtree'
Plug 'https://github.com/morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tomasr/molokai'
Plug 'fmoralesc/molokayo'
Plug 'phanviet/vim-monokai-pro'

" otherslug 'mhinz/vim-startify'
Plug 'catppuccin/vim', { 'as': 'catppuccin' }
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'mhinz/vim-startify'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'kshenoy/vim-signature'
Plug 'luochen1990/rainbow'
Plug 'ervandew/supertab'
Plug 'kamykn/spelunker.vim'
Plug 'ghifarit53/tokyonight-vim'
Plug 'NLKNguyen/papercolor-theme'
Plug 'christoomey/vim-tmux-navigator'


call plug#end()

" Color
" colorscheme molokayo
"
" colorscheme catppuccin_mocha
"  set bg=light
"
" 1. 告诉 Vim：不要傻等 Esc 键，快速响应
set ttimeout
set ttimeoutlen=50

" 2. 手动把终端发送的 Escape 序列映射回 Alt 键
" (原理：终端发 \eh，Vim 以为是 Esc+h，我们强行定义它为 <M-h>)
execute "set <M-h>=\eh"
execute "set <M-j>=\ej"
execute "set <M-k>=\ek"
execute "set <M-l>=\el"
execute "set <M-\\>=\e\\"

let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <M-h> :TmuxNavigateLeft<CR>
nnoremap <silent> <M-j> :TmuxNavigateDown<CR>
nnoremap <silent> <M-k> :TmuxNavigateUp<CR>
nnoremap <silent> <M-l> :TmuxNavigateRight<CR>
nnoremap <silent> <M-\> :TmuxNavigatePrevious<CR>

set termguicolors

" let g:tokyonight_style = 'storm' " available: night, storm
" let g:tokyonight_enable_italic = 1
" 
" colorscheme tokyonight

set background=light
colorscheme PaperColor


"F2开启和关闭树"
map <F2> :NERDTreeToggle<CR>
let NERDTreeChDirMode=1
"显示书签"
let NERDTreeShowBookmarks=1
"设置忽略文件类型"
let NERDTreeIgnore=['\~$', '\.pyc$', '\.swp$']
"窗口大小"
let NERDTreeWinSize=25

" Airline
let g:airline_powerline_fonts=1
if !exists('g:airline_symbols')
let g:airline_symbols = {}
endif
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#branch#enabled  = 1
let g:airline#extensions#branch#displayed_head_limit = 10

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.dirty='⚡'

let g:airline_theme='minimalist'
" let g:airline_theme = 'catppuccin_mocha'
" let g:airline_theme = "tokyonight"

let g:rainbow_active = 1

let g:enable_spelunker_vim = 1