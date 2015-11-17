termpdf
=======

`termpdf` is a barebones inline graphical PDF (and DJVU and TIF) viewer for
terminals that support inline graphics.

![screenshot]

On OS X, it works with iTerm 2.9 or later (so for the moment you will need to
install [the beta test release or a nightly build]). On X11, it should kinda work
with any terminal that supports inline images in the w3m browser (I have
tested it on Ubuntu using xterm and urxvt). I do not know if it works in the
framebuffer.

Pages are automatically sized to fit within the terminal window (or tmux
pane). Other features include:

-   smart zoom (autocrop margins) (z)
-   vertical and horizontal split page views (s, v)
-   text search/text view (/[search], [count]n, [count]N, t)
-   vim-style navigation ([count]j,[count]k, [count]g, [count]G, gg, G, g'[mark]
-   extract range of pages to pdf ([count]y, yy, y'[mark]) or as text (YY, Y'[mark])
-   printing (p)


Installation
============

`termpdf` is a bash script. Put it somewhere in your path and make sure it has
the appropriate permissions (i.e., `chmod u+x termpdf`).

Dependencies:

-   w3m (for X11) or iTerm2 2.9 or greater (for OS X)
-   Ghostscript, ImageMagick, Poppler, `pdfgrep`, djvulibre,
    [selecta](https://github.com/garybernhardt/selecta)

On OSX, install these via homebrew with

    brew install gs imagemagick poppler pdfgrep djvulibre selecta

On Ubuntu, you will need to download selecta and put it in your path.
Everything else can be installed via apt-get with

    sudo apt-get install ghostscript imagemagick poppler-utils pdfgrep
    djvulibre-bin w3m-img


w3mimgdisplay (X11 only)
========================

When you install w3m with inline graphic support, it includes a helper
program, `w3mimgdisplay`. But by default, this is not placed in your path. You
need to find it and add it to your path, so termpdf can use it.

On my copy of Ubuntu, it is at `/usr/lib/w3m/w3mimgdisplay`. So I made a
symbolic link in `/usr/local/bin`:

    sudo ln -s /usr/lib/w3m/w3mimgdisplay /usr/local/bin/w3mimgdisplay


Usage
=====

```.bash
$ termpdf [options] file [files...]

    -h or --help to get some help
    -t or --text to display text instead of images
    -n <number> to open the first document at a given page number.
```

File type is determined by extension ('pdf', 'djvu', 'tif', 'tiff', or 'png').
But any image files that Imagemagick can convert to png should be displayed.

While viewing a file, the default key commands are:

       [count]j     page back
       [count]k     page forward
       enter/space  page forward
       J/K:         previous document/next document
       [count]g:    go to page number [count]
       gg:          go to first page
       g'[mark]     go to page stored in [mark]
       G:           go to last page
       NNN:         go to page number NNN
       / <expr>     go to page with first match for <expr>
       m[mark]      store page in [mark]
       n:           go to next match for <expr>
       N:           go to previous match for <expr>
       r:           refresh display
       R:           reload document
       z:           toggle autocropped margins
       t:           toggle text/image display
       s:           split pages horizontally
       v:           split pages vertically
       p:           print document
       l:           toggle text pager 
       w:           wrap lines in text mode
       y:           yank page[s] and save as PDF
       Y:           yank page[s] as text to clipboard
       ?:           help
       q:           quit

# Settings

Settings are at the beginning of the script. Set your print command and
options (default: `lp -o sides=two-sided-long-edge`). Set your preferred text
pagers (default: `cat` and `less`). Set your clipboard handler (default
`pbcopy`, which will only work on OSX). Tweak the key commands as you see fit.

# Known issues

X11 support is not very good. It seems like the w3mimgdisplay command is far
more prone to break with incomplete png images(?) and so throws a lot more
errors. Also, positioning images within tmux is very unreliable, and I don't
understand how to clear images once drawn.

Various events, like resizing panes, can cause tmux to overwrite the
displayed page. Use the 'refresh display' command (`r`) to fix this.

Sometimes, the script will display a page before it was finished
converting, or try to display a page before it has been converted at all.
Again, using the 'refresh display' command (`r`) should fix this.

Switching between vertical and horizontal splits causes problems because the
implementation is poorly designed.

# TODO

-   refactor command parsing to make it more consistently vim-like
-   add command-line mode
-   rewrite in real language (using ncurses?)

  [the beta test release or a nightly build]: https://iterm2.com/downloads.html
  [Poppler]: http://poppler.freedesktop.org/
  [screenshot]: screenshot.png
