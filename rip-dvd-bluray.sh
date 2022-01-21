#!/usr/bin/env bash
#
# Description:  A script to rip a DVD or Bluray using makemkv
#
# Usage:  $0 <dir> <device>
#
# Notes:  Rubbish notes on makemkvcon
#           https://www.makemkv.com/developers/usage.txt
#
# ToDo:  Could do with some info on what to do if makemkvcon isn't on the system
#

DIR="${1%/}" # Remove any trailing slash
DEVICE="$2"
MINLENGTH=90
echo

set -e
set -u

# Basic check that we have the tools that all systems should have (uses set -e)
# echo, cd, pwd are all bash built-in's
hash blkid

if [ $# -eq 0 ]; then
    echo "No variables specified. e.g."
    echo "  $0 /path/to/dir /dev/sr0"
    exit 1
fi

if [ -z "$DIR" ]; then
  echo "No directory specified, please call script with a path. e.g."
  echo "  $0 /path/to/dir /dev/sr0"
  exit 2
fi

if [ ! -d "$DIR" ]; then
  echo "Directory is not a directory: $DIR"
  exit 3
fi

if [ ! -w "$DIR" ]; then
  echo "Directory is not writable: $DIR"
  exit 4
fi

if [ -z "$DEVICE" ]; then
  echo "No device specified, please call script with a device. e.g."
  echo "  $0 /path/to/dir /dev/sr0"
  exit 5
fi

if [ ! -b "$DEVICE" ]; then
  echo "Device not a block device: $DEVICE"
  exit 6
fi

if [ ! -r "$DEVICE" ]; then
  echo "Device not readable: $DEVICE"
  exit 7
fi

if ! command -v "makemkvcon" >/dev/null ;then
  echo "Error: Can't find 'makemkvcon' on the sytem"
  echo "  More details can be found at... "
  echo "  https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224"
  exit
fi

DVDNAME=$(blkid -o value -s LABEL $DEVICE)

echo "Please enter a correct title for $DVDNAME"
xdg-open "https://www.themoviedb.org/search?query=${DVDNAME//_/%20}"
read -p 'Title: ' DVDTITLE
echo
DVDTITLE="${DVDTITLE#"${DVDTITLE%%[![:space:]]*}"}" # Remove leading whitespace
DVDTITLE="${DVDTITLE%"${DVDTITLE##*[![:space:]]}"}" # Remove trailing whitespace

# I did think about doing the following but haven't needed it yet :-p 
#CLEANPATH=$(realpath -s "$DIR/$DVDTITLE")

echo "Making $DIR/$DVDTITLE/"
mkdir "$DIR/$DVDTITLE"

echo "Ripping Disk..."
makemkvcon --minlength=$MINLENGTH --decrypt --directio=true mkv dev:$DEVICE all "$DIR/$DVDTITLE"

EXTRAS=0
FEATURE=0
# If we don't change the IFS the `FILE in $(ls...` borks if spaces are in the filenames
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for FILE in $(ls -S1 "$DIR/$DVDTITLE"); do
  if [ $FEATURE -eq 0 ]; then
    mv "$DIR/$DVDTITLE/$FILE" "$DIR/$DVDTITLE/$DVDTITLE.mkv"
    FEATURE=1
  else
    mkdir -p "$DIR/$DVDTITLE/extras"
    mv "$DIR/$DVDTITLE/$FILE" "$DIR/$DVDTITLE/extras/$FILE"
    EXTRAS=1
  fi
done
IFS=$SAVEIFS

if [ $EXTRAS -eq 1 ]; then
  echo "Extras found, please rename the files..."
  xdg-open "$DIR/$DVDTITLE/extras"
  vlc $DEVICE > /dev/null
  read -n 1 -s -r -p "Press any key to continue"
fi

eject $DEVICE

exit

