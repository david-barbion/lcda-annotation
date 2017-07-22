#!/bin/bash

# This script uses Betty Regular font, it must be present in ~/.fonts/
# Deps: 
# zenity for asking user some paramters
# bc
# bash
# imagemagick
# Betty Regular.ttf

# ask user for color
# this function takes care to convert zenity output to hex code:
# rgba(1,2,3,0.5)
ask_color() {
  local title
  local rgba; local rgb; local alpha=255
  [ -z "$1" ] && title="Select color" || title="$1"
  rgba=$(zenity --title "$title" --color-selection --show-palette)
  if [ $? -ne 0 ]; then
    echo "Color not selected" >&2
    return 1
  fi
  if [[ "$rgba" =~ rgba ]]; then # alpha set
    alpha=$(echo "$rgba" | sed 's/^.*(\([0-9]\+\),\([0-9]\+\),\([0-9]\+\),\([0-9.]\+\).*/scale=0; \4 * 255 \/ 1/' | bc -l)
  fi
  rgb=$(echo "$rgba" | sed 's/^.*(\([0-9]\+\),\([0-9]\+\),\([0-9]\+\).*/\1 * 65536 + \2 * 256 + \3/' | bc)
  printf '#%06x%02x' "$rgb" "$alpha"
}

ask_text() {
  local title; local text
  [ -z "$1" ] && title="Enter text" || title="$1"
  text=$(zenity --title "$title" --entry)
  if [ $? -ne 0 ]; then
    echo "No text" >&2
    return 1
  fi
  echo "$text"
}


###########
# M A I N #
###########

# parse args
while [ ! -z "$1" ]; do
  case "$1" in
    --back-color|-bc) shift; UNDER_COLOR=$1 ;;
    --font-color|-fc) shift; FILL_COLOR=$1 ;;
    --text|-t) shift; TEXT=$1 ;;
  esac
  shift
done


##############
#   SANITY   #
##############
if [ -z "$FILL_COLOR" ]; then
  FILL_COLOR=$(ask_color "Select font color")
  [ $? -eq 1 ] && exit 1
fi

if [ -z "$UNDER_COLOR" ]; then
  UNDER_COLOR=$(ask_color "Select backround box color")
  [ $? -eq 1 ] && exit 1
fi

if [ -z "$TEXT" ]; then
  TEXT=$(ask_text "Enter text")
  [ $? -eq 1 ] && exit 1
fi

# get last selected dir
LASTANNOTATE=/tmp/anotate.lastdir
if [ -f "$LASTANNOTATE" ]; then
  LASTDIR=$(cat $LASTANNOTATE)
fi

IFS=$'\n' INPUTFILES=($(zenity --file-selection --multiple --filename="$LASTDIR/" --separator=$'\n' --title "Choisir le(s) fichier(s) à annoter"))
if [ $? -ne 0 ]; then
  exit 1
fi

for INPUTFILE in ${INPUTFILES[@]}; do
  echo $(dirname "$INPUTFILE") >"$LASTANNOTATE"
  OUTPUTFILE=$(echo "$INPUTFILE" | sed 's/\./-annotate./')
  FONTFAMILY="$HOME/.fonts/Betty Regular.ttf"

  WSIZE=$(identify -format '%w' "$INPUTFILE")
  POINTSIZE=$((380*WSIZE/3120))

  convert "$INPUTFILE" -fill white -undercolor "$UNDER_COLOR" -fill "$FILL_COLOR" -gravity center -font "$FONTFAMILY" -pointsize "$POINTSIZE" -annotate 0 "$TEXT" "$OUTPUTFILE"
done

