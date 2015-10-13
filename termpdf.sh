#!/usr/bin/env bash
###########################################################################
# termpdf is a barebones pdf viewer that relies on iTerm2's 
# support of inline images:
# 
#   https://iterm2.com/images.html
#
# To render the pdf into images, we rely on ghostscript and
# poppler's pdfimages command. To autocrop margins, we rely
# on ImageMagick's convert command. For search, we rely on
# pdfgrep.
#
# You can install ghostscript, poppler, ImageMagick, and pdfgrep
# via homebrew:
#
#   brew install poppler gs imagemagick pdfgrep
#
# termpdf should work inside of tmux.
#
###########################################################################


# SETTINGS

display="image" # default is to display images not text
wrap="false" # default is not to pipe text through wrap in text mode 
# default pager is cat. secondary pager is less: a lot more power, but
# clunky integration with termpdf. 
text_pagers[0]="cat"
text_pagers[1]="less -XE"
# density for PDF conversion. Higher density means sharper images,
# but might lead to slower performance.
density=200 
# halo is the number of pages before and after the current page that will
# be converted in the background.
halo=2


#
# The following two functions are borrowed from the imgcat script at
# 
#   https://raw.githubusercontent.com/gnachman/iTerm2/master/tests/imgcat
#
# tmux requires unrecognized OSC sequences to be wrapped with DCS tmux;
# <sequence> ST, and for all ESCs in <sequence> to be replaced with ESC ESC. It
# only accepts ESC backslash for ST.
function print_osc() {
    if [[ $TERM == screen* ]] ; then
        printf "\033Ptmux;\033\033]"
    else
        printf "\033]"
    fi
}

function print_st() {
    if [[ $TERM == screen* ]] ; then
        printf "\a\033\\"
    else
        printf "\a"
    fi
}

# This function is also borrowed from imgcat, but I've added support
# for specifying width and height.
#
# print_image filename inline base64contents
#   filename: Filename to convey to client
#   inline: 0 or 1
#   base64contents: Base64-encoded contents
function print_image() {
    print_osc
    printf '1337;File='
    if [[ -n "$1" ]]; then
      printf 'name='`echo -n "$1" | base64`";"
    fi
    if $(base64 --version 2>&1 | grep GNU > /dev/null)
    then
      BASE64ARG=-d
    else
      BASE64ARG=-D
    fi
    echo -n "$3" | base64 $BASE64ARG | wc -c | awk '{printf "size=%d",$1}'
    printf ";inline=$2"
    printf ";width=$width"
    printf ";height=$height"
    printf ":"
    echo "$3"
    print_st
    printf '\n'
}

# A simple function that uses pdfgrep to search the pdf
function find_text() {
  read -p "Find: " text
  results=( $(pdfgrep -nip "$text" "$pdf_file" | sed 's|:.*||') )
  if [ ${#results[@]} -gt 0 ]; then
     index=0
  else 
     index=-1
  fi
}

# A function for getting the dimensions of the current terminal
# window or pane.
function get_pane_size() {
    width=$(tput cols)
    height=$(stty size | awk '{print $1}')
    width=$(expr $width - 1)
    height=$(expr $height - 1 )
}

# A function for validiating page numbers
function page_limits() {
   if [ "$n" -le 0 ]; then n=1; fi
   if [ "$n" -ge "$pages" ]; then n="$pages"; fi
}

# Convert a page of the pdf to png. Using gs rather than 
# convert because it is supposedly faster. Also means that
# if you don't use the margin trimming feature, you don't need
# imagemagick.
function convert_gs() {
   gs -dNumRenderingThreads=4 -dNOPAUSE -sDEVICE=png16m \
       -dFirstPage=$1 -dLastPage=$1 \
       -sOutputFile=${tmp_file_root}-$1.png -r$density \
       -q "${pdf_file}" -c quit 2>/dev/null
}

# 
function convert_pdf() {
    for i in "$@"
    do
        if [[ $i -le $pages && $i -ge 1 ]]; then
            if [[ ! -f "${tmp_file_root}-$i.png" ]]; then
                if [[ $use_images == 'false' ]]; then
                    convert_gs "$i"
                else
                    pdfimages -png -f $i -l $i "$pdf_file" "$tmp_file_root"
                    mv "$tmp_file_root-000.png" "$tmp_file_root-$i.png"
                fi
                # generate margin-trimmed version of the page
                convert -trim "$tmp_file_root-$i.png" \
                    -bordercolor white -border 20x20 \
                    "$tmp_file_root-trimmed-$i.png" 2>/dev/null
            fi
        fi
    done
}

function convert_pdf_background() {
   (
   core=$n
   k=1
   while ((k<=halo))
   do
      convert_pdf $[$core + $k] $[$core - $k]
      let k++
   done
   )&
}

function display_text() {
   clear
   pdftotext -f $n -l $n -layout "$pdf_file" - \
       | egrep --color "$text|\$" \
       | if [ $wrap == 'true' ]; then wrap -w $width; else cat; fi \
       | $text_pager 
   if [[ $text_pager != 'cat' ]]; then echo "---END OF PAGE---"; fi
}

function check_dependencies() {
   for app in gs pdftotext pdfimages pdfgrep pdfinfo convert 
   do
      command -v $app >/dev/null 2>&1 ||\
          { echo >&2 "I require $app but it's not installed."; exit 1; } 
   done
   }

function print_tttt() {
   clear
   tput cup 0 0
   echo "j/k:         page back/forward"
   echo "g <number>:  go to page number"
   echo "r:           resize and redraw to fit pane"
   echo "m:           toggle autocropped margins"
   echo "t:           toggle text/image display"
   echo "p:           toggle pager in text mode" 
   echo "w:           toggle word-wrapping in text mode"
   echo "y:           yank current page as text to clipboard"
   echo "/ <expr>     go to page with first match for <expr>"
   echo "n:           go to next match for <expr>"
   echo "h:           print this help"
   echo "q:           quit"
   read -p "Press any key to return" -n 1 -s dummy
   if [ $dummy == 'q' ]; then exit; fi
   clear
}

function cli_help() {
   echo "Usage: termpdf.sh [options] file.pdf"
   echo
   echo "   options:"
   echo "      -h|--help:   show this help"
   echo "      -t|--text:   display text instead of images"
   echo "      -n <int>:    display page number <n>" 
   exit
}

function requires_poppler() {
    echo "termpdf requires ghostscript and poppler." 
    exit
}

check_dependencies

# Set some defaults
n=1 # start on page 1
text_pager=${text_pagers[0]}
results=( )
index=-1 
text="$" # null search text for egrep
trimmed="false" # set to true to default to trim margins


# Look for command line flags
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            cli_help
            exit
            ;;
        -t|--text)
            display="text"
            ;;
        -n)
            shift
            if [[ "$1" != [0-9]* ]]; then
               echo "Must specify a page number with -n"
               exit
            else
               n="$1"
            fi
            ;;
        -*)
            echo "Unknown option: $1"
            cli_help
            exit
            ;;
        *)
            if [ -r "$1" ] ; then
               pdf_file="$1" 
            else
                echo "$1: No such file or directory"
                exit
            fi
            ;;
    esac
    shift
done


# Check to see that a file was specified on the cli
if [ ! -r "$pdf_file" ]; then cli_help; fi

# How many pages does the PDF file have?
pages=$(pdfinfo "$pdf_file" 2>/dev/null | grep "^Pages:" | awk '{print $2}') 
# Does it look like it has page images?
images=$(pdfimages -list "$pdf_file" | wc | awk '{print $1}')
images=$[$images - 2]
if [[ $pages == $images ]]; then use_images='true'; else use_images='false'; fi

# Ensure that $n is set to a page that exists
page_limits

# We need the size of the current pane so we can properly size the pdf
# images
get_pane_size

# Make a tmpfile
tmp_dir=$(mktemp -d)
tmp_file_root="${tmp_dir}/tmp"
# clear the pane since we don't always fill it
clear

# Convert page $n of the PDF
convert_pdf $n

# Convert surrounding pages in the background 
convert_pdf_background 

# display the PDF

while [[ 1 == 1 ]]
do
   tput cup 0 1  # we leave a line at the top for commands

   if [[ $trimmed == 'true' ]]; then
       tmp_file="${tmp_file_root}-trimmed-$n.png"
   else
       tmp_file="${tmp_file_root}-$n.png"
   fi
   # display
   if [ $display == 'image' ]; then
       if [ -r "$tmp_file" ] ; then
           print_image "$tmp_file" 1 "$(base64 < "$tmp_file")"
       else
           convert_pdf $n
           print_image "$tmp_file" 1 "$(base64 < "$tmp_file")"
       fi
   else
       display_text $n
   fi

   tput cup 0 0 # put the cursor at the top of the pane
   tput el # erase any old stuff from previous commands
   tput cup 0 $(expr $width - ${#n}) # page num top right
   echo "$n"
   tput cup 0 0

   read -n 1 -s command # await commands
   case "$command" in
      j)
          n=$(expr "$n" - 1);; # go back a page
      k)
          n=$(expr $n + 1);; # go forward a page
      g)   
          read -p "Goto page: " pn # jump to a page
          if [[ "$pn" == [0-9]* ]]; then
             n="$pn"
          fi
          ;;
      r)
          get_pane_size # clean up and resize to fit pane
          clear
          ;;
      t)
          if [ $display == "text" ]; then
              display="image"
          else
              display="text"
          fi
          clear
          ;;
      m)
          if [ $trimmed == "false" ]; then
              trimmed="true"
          else
              trimmed="false"
          fi
          ;;
      p)
          if [[ "$text_pager" == "${text_pagers[1]}" ]]; then
              text_pager="${text_pagers[0]}"
          else
              text_pager="${text_pagers[1]}"
          fi
          ;;
       w)
          if [ $wrap == "true" ]; then
              wrap="false"
          else
              wrap="true"
          fi
          ;;
      y)
          pdftotext -f $n -l $n -layout "$pdf_file" - | pbcopy
          tput cup 0 0
          echo "Page copied"
          ;;
      '/') 
          find_text
          if [[ $index != -1 ]]; then
             n=${results[$index]}
          else
             echo "No matches"
          fi;;
      n)
          if [ $index != -1 ] && [ ${results[$(expr $index + 1)]} ]; then
             index=$(expr $index + 1)
             n=${results[$index]} # go to next match
          else
             echo "No matches"
          fi;;
      h)
          print_help
          ;;
      q)
          rm -rf "$tmp_dir"
          clear
          exit;;
   esac
   # make sure the page we want exists
   page_limits
   convert_pdf_background
done
