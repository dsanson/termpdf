termpdf
=======

`termpdf` is a barebones inline graphical PDF (and DJVU and TIFF) viewer for
iTerm 2.9 or later on OS X. It is a ridiculous hack---a bash script wrapped around
some special terminal escape codes. But it works well enough for me to be
useful.

![screenshot]

Features
========

Each page of the PDF is sized to fit within your terminal window (or tmux
pane). Other features include:

-   basic "vim-style" navigation
-   cropping of margins (using `k2pdfopt`)
-   extracting (yanking) pages and saving them to a new pdf
-   printing
-   opening a text file for annotation in a split pane in tmux

Requirements
============

OS X and iTerm 2 > 2.9
-------------

This only works on OS X because iTerm 2 is only available on OS X. A
previous version of the script tried to support X11 using `w3mimgdisplay`,
but that didn't work and made everything a lot more complicated, so I 
removed it.

Support for inline images was added in iTerm 2.9. So, at least for now, that
means you will need to install [the beta test release or a nightly build]. 

Poppler
-------

The script uses `pdfseparate` to separate PDF documents into separate pages,
and `pdfinfo` to figure out how many pages a PDF document has. These commands
are provided by [Poppler]:

    $ brew install poppler

DJVULibre and Ghostscript
-------------------------

The script uses `djvups` and `ps2pdf` to extract pages from DJVU documents and
convert them to PDF, and `djvudump` to figure out how many pages a DJVU
document has. These commands are provided by DJVULibre and Ghostscript:

    $ brew install ghostscript djvulibre

libtiff
-------

The script uses `tiffutil`, and `tiff2pdf` to extract pages from
TIFF files and convert them to PDF, and `tiffinfo` to figure out how many
pages a TIFF document has. These commands are provided by libtiff:

    $ brew install libtiff

K2pdfopt
--------

The simplest tool I could find for automatically cropping margins on PDF
documents was [`k2pdfopt`](http://willus.com/k2pdfopt/). If you don't care
about cropping margins, you don't need this. If you know of a way of doing
this that is simpler, let me know! (In a previous version of the script, I
used ImageMagick's `convert`, but that was because I was converting
each page to a PNG file.)

Bash 4.x
--------

Bash 3.x is shipped with OS X. Bash 4.x adds associative arrays. A previous
version of the script required Bash 4.x, because it made heavy use of
associative arrays. This version only requires Bash 4.x if you want support
for marks.

    $ brew install bash


Installation
============

`termpdf` is a bash script. Put it somewhere in your path and make sure it has
the appropriate permissions (i.e., `chmod u+x termpdf`). 

Usage
=====

```.bash
$ termpdf <file> 
```

File type is determined by extension ('pdf' and 'djvu' are currently the only
two supported formats).

While viewing a file, the default key commands are:

    enter/space: forward one page
    [n]k/j:      forward or back [n] pages
    [n]G:        go to page [n]
    G:           go to last page
    gg:          go to first page
    [n]p:        print [n copies of] document
    [n]y:        yank [n] pages forward and save as pdf
    yy:          yank current page and save as pdf
    r:           refresh display
    R:           reload document
    M:           remake document
    c:           crop margins
    a:           annotate in split pane
    m[r]:        store current page in register [r]
    '[r]:        go to page stored in register [r]
    g'[r]:       go to to page in register [r]
    y'[r]:       yank from current page to mark and save as pdf
    q:           quit
    h:           view this help

These commands are all set by the `keys()` function, so they are easy enough
to change as you see fit.

There is also rudimentary undocumented support for `:` style commands, e.g.,

    :first                                go to first page
    :last                                 go to last page
    :print <copies> <page-range>
    :gui                                  open the document in your default
                                             PDF viewer (e.g., Preview.app)
    :marks                                list marks
    :quit                                 quit

This is mostly useless, because bash's `read` command doesn't support
customizable autocompletion when called within scripts. But it is there. 

# `termdoc`

`termdoc` is a wrapper script for viewing more filetypes using `termpdf`, by
converting them as needed to formats supported by `termpdf`.

In it's current iteration, it uses [LibreOffice](https://www.libreoffice.org/) if it can find it in your
`/Applications` or `~/Applications` folder. This works well for LibreOffice's
native ODF formats (like ODT), and reasonably well for Microsoft office
formats (Word, Excel, Powerpoint) and LibreOffice formats (ODT). 

If you don't have LibreOffice installed, `termdoc` can use the free
online doc2pdf.net conversion service. Obviously this will only work online.
Also note that doc2pdf.net is not recommended for confidential documents, for
obvious reasons.

# Known issues

Various events, like resizing panes, can cause tmux to clobber the
displayed page. Use the 'refresh display' command (`r`) to fix this.

The make command right now only works if you have a Makefile in the same
directory as the PDF, and you launched termpdf from that directory. It would
be nice to support a configurable make command.

There is no robust error checking. This is just a bash script.

# TODO

-   better handling of pdfs with transparent backgrounds. See Issue #10.
-   implement search using `pdfgrep`. This was in an earlier version of the
    script, but was removed because it was complicated. I'm not sure what the
    best minimal implementation of search is. One problem is that there is no
    easy way to indicate *where* the search term was found on a page, since
    the page is just an image and we don't have any reasonable way to
    highlight matches.
-   rewrite in real language (using ncurses?). It would be really cool to have
    a PDF viewer for vim+tmux with the power of emacs'
    [pdf-tools](https://github.com/politza/pdf-tools). But that's not going to
    happen using bash. Also, if written in a proper language, it would be
    easier to implement other image drawing schemes that would work in
    X11 terminals.    
    
  [the beta test release or a nightly build]: https://iterm2.com/downloads.html
  [Poppler]: http://poppler.freedesktop.org/
  [screenshot]: screenshot.png
