#!/bin/bash

# using %%c is a must, as, if the creation date of the image is the same as another image, despite
# actually being different images, only one will get saved. using %%c fixes this, as it appends a number 
# and writes the next image

PHOTOLOCATION="photos"
SORTEDLOCATION="Sorted"

mkdir -p "$SORTEDLOCATION/unsorted"

rm *.log
rm *.csv

exiftool -v10 -o . -if '($datetimeoriginal and ($datetimeoriginal ne "0000:00:00 00:00:00"))' -d 'Sorted/%Y/%m/%d_%H:%M%%-c.%%e' '-Filename<DateTimeOriginal' -r "$PHOTOLOCATION" > messagesA.log 2> messagesB.log

grep "^Error" messagesB.log

# Not needed anymore
#if [ $(grep "^Error" messagesB.log | wc -l) -ne 0 ]; then
#	echo "Errors found"
#	echo "Could be because a filname already exists in a file with no exif data, so for instance, all files with no exif are copied to this directory, so could be filename collision" 
#	echo "THIS SHOULD NOT HAVE HAPPENED, as we are only looking for files with exif in now"
#	exit
#fi

# find any files without exif
exiftool -filename -r "$PHOTOLOCATION" -if '(not $datetimeoriginal or ($datetimeoriginal eq "0000:00:00 00:00:00"))' -common -csv > noexif.csv

# can't use awk for parsing, because might be commas in filename so, copy files which don't have exif to unsorted folder
cat noexif.csv | sed "s/,[^,]*,[^,]*,[^,]*,[^,]*$//g" | while read -r file; do md5=( $(md5sum "$file") ); cp "$file" "$SORTEDLOCATION/unsorted/$md5.${file##*.}"; done

# Delete the dupes
fdupes -rdN "$SORTEDLOCATION" > dupes.txt
