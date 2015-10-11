#!/bin/sh
#
# termpdf is a barebones pdf viewer that relies on iTerm2's 
# support of inline images:
# 
#   https://iterm2.com/images.html
#
# and tools provided by the Poppler PDF rendering library
#
#   http://poppler.freedesktop.org/
#
# You can install Poppler via homebrew:
#
#   brew install poppler
#
# It should work inside of tmux.
#

# The following functions are borrowed from the imgcat script at
# 
#   https://raw.githubusercontent.com/gnachman/iTerm2/master/tests/imgcat

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

# More of the tmux workaround described above.
function print_st() {
    if [[ $TERM == screen* ]] ; then
        printf "\a\033\\"
    else
        printf "\a"
    fi
}

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

function find_text() {
  read -p "Find: " text
  results=( $(pdfgrep -nip "$text" "$pdf_file" | sed 's|:.*||') )
  if [ ${#results[@]} -gt 0 ]; then
     index=0
  else 
     index=-1
  fi
}

function get_pane_size() {
    width=$(tput cols)
    height=$(stty size | awk '{print $1}')
    width=$(expr $width - 1)
    height=$(expr $height - 1 )
}

function print_help() {
   clear
   tput cup 0 0
   echo "j/k:         page back/forward"
   echo "g <number>:  go to page number"
   echo "r:           resize and redraw to fit pane"
   echo "t:           toggle text/image display"
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
   echo "Usage: termpdf.sh [options] path_to_pdf"
   echo
   echo "   options:"
   echo "      -h|--help: show this help"
   echo "      -t|--text: display text instead of images"
   echo 
   echo "   dependencies:"
   echo "       iTerm2 and poppler (for pdfimages, pdftotext, and pdfinfo)"
   exit
}

# Default settings
n=1 # start on page 1
display="image" # display images not text


# No search results yet
results=( )
index=-1 
text="$"

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
        -*)
            echo "Unknown option: $1"
            cli_help
            exit
            ;;
        *)
            if [ -r "$1" ] ; then
               pdf_file="$1" 
               pages=$(pdfinfo "$pdf_file" | grep "^Pages:" | awk '{print $2}') 
            else
                echo "$1: No such file or directory"
                exit
            fi
            ;;
    esac
    shift
done

# Check to see that a file was specified on the cli
if [ ! $pdf_file ]; then cli_help; fi

# We need the size of the current pane so we can properly size the pdf
# images
get_pane_size

# Make a tmpfile
tmp_file_root=$(mktemp)
tmp_file="${tmp_file_root}-000.png"

# clear the pane since we don't always fill it
clear

# display the PDF
while $(pdfimages -png -f $n -l $n "$pdf_file" "$tmp_file_root")  
do
   tput cup 0 1  # we leave a line at the top for commands

   # display
   if [ $display == 'image' ]; then
       if [ -r "$tmp_file" ] ; then
           print_image "$tmp_file" 1 "$(base64 < "$tmp_file")"
       else
           error "termpdf: unable to create the temporary file"
           exit 2
       fi
   else
       clear
       pdftotext -f $n -l $n "$pdf_file" - | egrep --color "$text|\$"
   fi

   tput cup 0 0 # put the cursor at the top of the pane
   tput el # erase any old stuff from previous commands
   read -n 1 -s command # await commands
   case "$command" in
      j)
          n=$(expr "$n" - 1);; # go back a page
      k)
          n=$(expr $n + 1);; # go forward a page
      g)   
          read -p "Goto page: " n;; # jump to a page
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
      y)
          pdftotext -f $n -l $n "$pdf_file" - | pbcopy
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
          rm "$tmp_file"
          exit;;
   esac

   # make sure the page we want exists
   if [ "$n" -le 0 ]; then n=1; fi
   if [ "$n" -ge "$pages" ]; then n="$pages"; fi
done
