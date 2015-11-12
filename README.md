README for termpdf
==================

`termpdf` is a barebones inline graphical PDF (and DJVU and TIF) viewer for
terminals that support inline graphics.

![screencast](screencast.gif)

On OS X, it works with iTerm 2.9 or later (so for the moment you will need to
install [the beta test release or a nightly build]). On X11, it should work
with any terminal that supports inline images in the w3m browser (I have
tested it on Ubuntu using xterm and urxvt). I do not know if it works in the
framebuffer.

Pages are automatically sized to fit within the terminal window (or tmux
pane). Other features include:

-   smart zoom (autocrop margins)
-   vertical and horizontal split page views
-   jump to page number
-   text search
-   view page as text (with or without word wrapping)
-   printing

![screenshot]

Installation
============

`termpdf` is a bash script. Put it somewhere in your path and make sure it has
the appropriate permissions (i.e., `chmod u+x termpdf`).

Dependencies:

-   w3m (for X11) or iTerm2 2.9 or greater (for OS X)
-   Ghostscript, ImageMagick, Poppler, `pdfgrep`, djvulibre

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

Image Quality
=============

The script defaults to converting to 300x300 pixel images. For crisper text
(at a possible performance cost), adjust the value of the `density` variable.

To boost performance, the script converts each page as needed, but also
attempts to convert, in the background, a few pages before and after the page
currently being viewed. You can adjust the scope of these background
conversions by adjusting the value of the `halo` variable.

Usage
=====

`$ termpdf.sh [options] file.pdf`

options:

-   `-h` or `--help` to get some help
-   `-t` or `--text` to display text instead of images
-   `-n <number>` to open the PDF at a given page number.

While viewing a PDF, the default key commands are:

       j/k:         page back/forward
       enter/space  page forward
       g <number>:  go to page number
       NNN:         go to page number NNN
       / <expr>     go to page with first match for <expr>
       n:           go to next match for <expr>
       N:           go to previous match for <expr>
       r:           refresh display
       R:           reload document
       m:           toggle autocropped margins
       t:           toggle text/image display
       s:           split pages horizontally
       v:           split pages vertically
       p:           print document
       l:           switch to between pagers in text mode
       w:           wrap lines in text mode
       y:           yank current page as text to clipboard
       ?:           help
       q:           quit

You change these to suit your own preferences: the values are set in the
`keys` array found near the beginning of the script.

# Known issues

Various events, like resizing panes, can cause tmux to overwrite the
displayed page. Use the 'refresh display' command (`r`) to fix this.

Sometimes, the script will display a page before it was finished
converting, or try to display a page before it has been converted at all.
Again, using the 'refresh display' command (`r`) should fix this.

# TODO

-   mark pages
-   extract page or page range to pdf
-   open more than one document at a time

  [the beta test release or a nightly build]: https://iterm2.com/downloads.html
  [Poppler]: http://poppler.freedesktop.org/
  [screenshot]: termpdf_screenshot.png
