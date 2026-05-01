" 开启语法高亮
syntax enable

" 关闭鼠标
set mouse=

" 文件编码
set encoding=utf-8
set termencoding=utf-8

" 制表宽度
set softtabstop=4
set tabstop=4
set shiftwidth=4

" tab页最大个数
set tabpagemax=20

" 自动缩进对齐
set autoindent

" 显示行号
set nu

" 防止在文件末尾追加换行符
set noendofline
set binary

" 设置背景, 影响vim显示
set bg=dark

" 代码折叠
set foldmethod=indent

" backspace功能
set backspace=indent,eol,start

" 总是显示tab栏, 需要vim7
set showtabline=2

" 高亮搜索词
set hlsearch

" 开启注释换行自动格式化
set formatoptions+=r

" 关闭F1的帮助功能, 防止误操作
nmap <F1> <Esc>
imap <F1> <Esc>

" 展开tab为空格
set expandtab

set completeopt=menu