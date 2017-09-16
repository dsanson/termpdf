termpdf
=======

`termpdf` is a barebones inline graphical PDF (and DJVU and TIFF and CBR and
CBZ and JPG and PNG and GIF and BMP) viewer for iTerm 2.9 or later on OS X. It
is a ridiculous hack---a bash script wrapped around some special terminal
escape codes. But it works well enough for me to be useful.

![screenshot]

Features
========

-   displays images sized to fit your terminal window (or tmux pane)
-   navigate multipage documents using vim-style commands
-   yank selected pages to a new pdf file
-   print selected pages
-   automatically crop margins (using `k2pdfopt`)
-   saves bookmarks and opens document to last viewed page
-   control running instances remotely using the included `tpdfc` script
-   open a text file for annotation in a split pane in tmux

Requirements
============

OS X and iTerm 2 > 2.9
-------------

This only works on OS X because iTerm 2 is only available on OS X. 
Support for inline images was added in iTerm 2.9. 

A previous version of the script tried to support X11 using `w3mimgdisplay`.
That got complicated and it didn't work, so I removed it. I'd be happy to add
support for X11 back in if someone knows how to make it work.

The biggest headache with `w3mimgdisplay` is figuring out how to get the image
to fit inside a terminal window or tmux pane: it is easy to get the size of
the window or pane in characters, but `w3mimgdisplay` takes dimensions in
pixels, not characters. It looks like [termimg] might solve this problem.

I am also keeping my eye on [this possible enhancement to
Kitty.app](https://github.com/kovidgoyal/kitty/issues/33).


  [termimg]: https://github.com/frnsys/termimg

Poppler
-------

The script uses `pdfseparate` to separate PDF documents into separate pages,
and `pdfinfo` to figure out how many pages a PDF document has. These commands
are provided by [Poppler]:

    $ brew install poppler

DJVULibre 
---------

The script uses `ddjvu` to extract pages from DJVU documents and
convert them to PDF, and `djvudump` to figure out how many pages a DJVU
document has. These commands are provided by DJVULibre: 

    $ brew install djvulibre

libtiff
-------

The script uses `tiffutil`, and `tiff2pdf` to extract pages from
TIFF files and convert them to PDF, and `tiffinfo` to figure out how many
pages a TIFF document has. These commands are provided by libtiff:

    $ brew install libtiff

unrar
-----

The script uses `unrar` to open RAR archives and CBR comic books. To install:

    $ brew install unrar


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

LibreOffice
-----------

I've added basic support for viewing Microsoft Office (docx, xlsx, pptx) and
LibreOffice (odt, ods, odp) files. The script converts them to PDF using
LibreOffice, and then displays the resulting PDF. For this to work, you'll
need to have a copy of LibreOffice installed in your `/Applications` folder.

Installation
============

`termpdf` is a bash script. Put it somewhere in your path and make sure it has
the appropriate permissions (i.e., `chmod u+x termpdf`). 

Usage
=====

```.bash
$ termpdf <file> 
$ termpdf <directory>
```

File type is determined by extension. Supported formats include: PDF, DJVU, TIF,
CBR, CBZ, CBT, JPG, JPEG, PNG, GIF, and BMP.

`termpdf` will treat a directory as though it is a document, and each image
file below the directory as a page. It will do the same with RAR, ZIP, and TAR
archives.

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
    +:           zoom in (this is kind of janky)
    -:           zoom out (also janky)
    =:           reset zoom to 100%
    q:           quit
    h:           view this help

These commands are all set by the `keys()` function, so they are easy enough
to change as you see fit.

There is also rudimentary undocumented support for `:` style commands, e.g.,

    :first                                go to first page
    :last                                 go to last page
    :goto 20                              go to page 20
    :print <copies> <page-range>
    :gui                                  open the document in your default
                                             PDF viewer (e.g., Preview.app)
    :marks                                list marks
    :quit                                 quit

This is mostly useless from within the software, because bash's `read` command
doesn't support customizable autocompletion when called within scripts.

# Controlling `termpdf` using `tpdfc`

You can issue `:` style commands to a running instance of `termpdf` using the command
`tpdfc`. For example,

    $ tpdfc goto 5

will flip to page 5. If more than one instance of `termpdf` is running, you
can specify the instance you wish to control either by PID or just by number:

    $ tpdfc -n 2 goto 5
    $ tpdfc -p <PID> goto 5

To list all available instances,

    $ tpdfc -l

# Configuration files

You can put any commands you want into `$HOME/.config/termpdf/config`, and
they will be run during the setup process. This allows you, among other
things, to override the key mappings and tweak the print settings.

I also use this to help address the problem with displaying transparent PDFs
when using a dark theme (see Issue #10), by including the following in my
config file:

```bash
# function for switching iterm themes/profiles
switch_iterm_theme () {
        [[ -n $TMUX ]] && printf "\033Ptmux;\033"
        echo -e "\033]50;SetProfile=$1\a" && export ITERM_PROFILE="$1"
        [[ -n $TMUX ]] && printf "\033\\"
}
# save the current profile
current_profile=$(osascript -e 'tell application "iTerm" to get profile name of current session of current window')
# switch to light theme for transparent PDFs
switch_iterm_theme "Gruvbox Light" && test $TMUX && tmux set -g status-bg white 2> /dev/null && tmux setw -g window-status-attr default
```

You can also put commands in `$HOME/.config/termpdf/exithook`, which will be
sourced before the script exits. I use this to revert to switch back to the
profile I was using before I launched `termpdf`:

```bash
switch_iterm_theme "$current_profile"
```

If you use `tmux`, this solution to issue #10 is far from perfect: it will
change the theme for your entire session, not just the current pane. I've
mostly stopped using `tmux` in favor of
[chunkwm](https://github.com/koekeishiya/chunkwm), so this is no longer a big
issue for me. But it might be for you.

# `termdoc`

`termdoc` was a wrapper script for viewing more filetypes using `termpdf`, by
converting them as needed to formats supported by `termpdf`. But I've added
this feature into `termpdf` itself, so this is obsolete.


In it's current iteration, it uses [LibreOffice](https://www.libreoffice.org/) if it can find it in your
`/Applications` or `~/Applications` folder. This works well for LibreOffice's
native ODF formats (like ODT), and reasonably well for Microsoft office
formats (Word, Excel, Powerpoint).

If you don't have LibreOffice installed, `termdoc` can use the free
online doc2pdf.net conversion service. Obviously this will only work online.
Also note that doc2pdf.net is not recommended for confidential documents, for
obvious reasons.

# Known issues

Various events, like resizing panes, can cause tmux to clobber the
displayed page. Use the 'refresh display' command (`r`) to fix this.

The make command only works if you have a Makefile in the same
directory as the PDF. It would be nice to support a configurable make command.

There is no robust error checking. This is just a bash script. So occasionally
it will just crash or fart or do something unexpected.

# TODO

-   better handling of pdfs with transparent backgrounds. See Issue #10.
-   rewrite in real language (using ncurses?). It would be really cool to have
    a PDF viewer for vim+tmux with the power of emacs'
    [pdf-tools](https://github.com/politza/pdf-tools). But that's not going to
    happen using bash. Also, if written in a proper language, it would be
    easier to implement other image drawing schemes that would work in
    X11 terminals.    
    
# Similar Projects

Emacs users already know about
[pdf-tools](https://github.com/politza/pdf-tools). It would be amazing to
replicate its level of functionality for a pdf viewer in the tmux+vim
workflow.


-   [fbpdf](http://repo.or.cz/fbpdf.git): a pdf viewer for the framebuffer
    with vim-like navigation.
-   [jfbview](https://seasonofcode.com/pages/jfbview.html): another pdf viewer for
    the framebuffer.
-   [imgcat](https://iterm2.com/images.html): the sample imgcat implementation
    from the developer of iTerm2. Works in tmux. Doesn't provide control over
    width and height of image.
-   [term-img](https://github.com/sindresorhus/term-img): javascript node
    library for viewing images in iTerm2. Also offers a command line tool.
    Doesn't work in tmux.
-   [imgcat-cli](https://github.com/egoist/imgcat-cli): a javascript node
    image viewer for iTerm2 (fork of term-img). Doesn't work in tmux.
-   [termimg](https://github.com/frnsys/termimg): uses `w3mimgdisplay`.


  [Poppler]: http://poppler.freedesktop.org/
  [screenshot]: screenshot.png
