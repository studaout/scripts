#!/bin/bash

if [ $# -ne 1 ]; then
    echo "$0: usage: $0 dir_name"
    exit 1
fi

dirName=$1
echo "Directory name: $dirName."

if [ -d "$dirName" ]
then
    echo "Processing $dirName"
    cd $dirName || exit 1
    for entry in *; do
       if [ -f "$entry" ]; then
          #get file name without extension
           fileName=${entry%.*}
           #get file size
           fileSize=$(stat -c%s "$entry")
           #get last 10 bytes to get prefix size
           headerSize=`tail -c 10 $entry`
           #remove trailing 0 from begining by conversion from base10 to base10
           skipSize=$((10#$headerSize))
           #calculate file size
           countSize=$(($fileSize-$skipSize-10))
           #skip prefix and last 10 bytes
           dd iflag=skip_bytes,count_bytes skip=$skipSize count=$countSize if=$entry of=$fileName || exit 1
           rm $entry || exit 1
       fi
    done
    #find first file for extraction
    firstFile=$(find . -type f -name '*.001')
    if [ -z "$firstFile" ]; then
        echo "Could not find first file"
        exit 1
    fi
    #extract
    7z x -so $firstFile | tar xf -
else
    echo "$dirName is not a directory"
    exit 1
fi
