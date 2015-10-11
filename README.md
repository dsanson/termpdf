# README for termpdf

`termpdf` is a barebones pdf viewer that relies on [iTerm2's support of inline
images][] and the [Poppler PDF rendering library][]. It should run fine within
tmux. I wrote it so that I could view PDF files will working in tmux and
iTerm2 in fullscreen mode.

# Installation

`termpdf` is a bash script. Put it somewhere in your path and make sure it has
the appropriate permissions (i.e., `chmod u+x termpdf.sh`).

You can install Poppler via homebrew: `brew install poppler`.

# Usage

From the command line, try,

`$ termpdf.sh [options] sample.pdf`

options: 

-   `-h` or `--help` to get some help
-   `-t` or `--text` to display text instead of images

While viewing a PDF, the commands are:

~~~
   j/k:         page back/forward
   g <number>:  go to page number
   r:           resize and redraw to fit pane
   t:           toggle text/image display
   y:           yank current page as text to clipboard
   / <expr>     go to page with first match for <expr>
   n:           go to next match for <expr>
   h:           print this help
   q:           quit
~~~



  [iTerm2's support of inline images]: https://iterm2.com/images.html
  [Poppler PDF rendering library]: http://poppler.freedesktop.org/
