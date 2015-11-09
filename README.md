README for termpdf
==================

`termpdf` is a barebones inline graphical PDF (and DJVU and TIF) viewer for
terminals that support inline graphics.

On OS X, it works with iTerm 2.9 or later (so for the moment you will need to
install [the beta test release or a nightly build]). On X11, it should work
with any terminal that supports inline images in the w3m browser (I have
tested it on Ubuntu using xterm and urxvt). I do not know if it works in the
framebuffer.

It works by converting each page of the document into a png, using
ghostscript, poppler, djvulibre, and ImageMagick, as needed.

It automatically sizes pages to fit within the terminal window (or, within
`tmux`, the pane). It does not support zooming, but it does support
autocropping of margins, for which it relies on ImageMagick's `convert -trim`
command. It also supports text search, using `pdfgrep`, and, for PDFs, a
rudimentary paginated text view, that relies on [Poppler]'s `pdftotext`.

It is not especially robust, because support for inline graphics in these
terminals is not especially robust. But it works well enough to be useful.

![screenshot]

Installation
============

`termpdf` is a bash script. Put it somewhere in your path and make sure it has
the appropriate permissions (i.e., `chmod u+x termpdf`).

Dependencies:

-   w3m (for X11) or iTerm2 2.9 or greater (for OS X)
-   Ghostscript, ImageMagick, Poppler, and `pdfgrep`, djvulibre

On OSX, install these via homebrew with

    brew install gs imagemagick poppler pdfgrep djvulibre

On Ubuntu, install via apt-get with

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

Font Size Conversion Factors (X11 only)
---------------------------------------

In order to display an image using `w3mimgdisplay`, we need to specify both
its width and height in pixels. But tmux reports the size of a pane in
characters. So we need to know how many pixels wide and high a single
character is, and that depends on all sorts of factors.

After spending some time looking at terminal escape codes, I decided it was
easier to just do this manually for now, so I played with numbers until I got
something that worked on my copy of urxvt. There is no reason to suppose it
will work for you. Edit the values of `y_factor` and `x_factor` to find values
that work for you.

Image Quality
=============

The script defaults to converting to 300x300 pixel images. For crisper text
(at a possible performance cost), adjust the value of the `density` variable.

Usage
=====

`$ termpdf.sh [options] file.pdf`

options:

-   `-h` or `--help` to get some help
-   `-t` or `--text` to display text instead of images
-   `-n <number>` to open the PDF at a given page number.

While viewing a PDF, the commands are:

       j/k:         page back/forward
       enter/space  page forward
       g <number>:  go to page number
       NNN:         go to page number NNN
       r:           resize and redraw to fit pane
       m:           toggle autocropped margins
       t:           toggle text/image display
       y:           yank current page as text to clipboard
       / <expr>     go to page with first match for <expr>
       n:           go to next match for <expr>
       h:           print this help
       p:           switch to between pagers in text mode
       w:           wrap lines in text mode
       q:           quit

  [the beta test release or a nightly build]: https://iterm2.com/downloads.html
  [Poppler]: http://poppler.freedesktop.org/
  [screenshot]: termpdf_screenshot.png
