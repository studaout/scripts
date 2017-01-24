#!/bin/bash

if [ $# -ne 1 ]; then
    echo "$0: usage: $0 dir_name"
    exit 1
fi

dirName=$1
encDirName="${dirName}_enc"
echo "Directory name: $dirName. Encoded files directory name $encDirName ."

if [ -d "$dirName" ]
then
    echo "Processing $dirName"
    mkdir $encDirName || exit 1
    #tar and archive with part size <= 10M
    tar cf - $dirName | 7z a -si -v10m $dirName || exit 1
    mv ${dirName}.7z.* $encDirName || exit 1
    cd $encDirName || exit 1
    for entry in *; do
       if [ -f "$entry" ]; then
          #remove .7z. from file name
           fileBase="${entry/\.7z\./\.}"
           sampleFileName="${fileBase}_sample.jpg"
           encFileName="${fileBase}.jpg"
          #generate sample jpeg image
           mx=320;my=256;head -c "$((3*mx*my))" /dev/urandom | convert -depth 8 -size "${mx}x${my}" RGB:- ${sampleFileName} || exit 1
           #get smaple image size
           imgSize=$(stat -c%s "$sampleFileName")
           #echo "$imgSize"
           #merge sample image and archive
           cat $sampleFileName ${entry} > "${encFileName}" || exit 1
           #attach sample image size - rounded to 10 bytes size with padded 0
           echo -n `printf "%010d" $imgSize` >> "${encFileName}" || exit 1
           rm $entry || exit 1
           rm $sampleFileName || exit 1
       fi
    done
else
    echo "$dirName is not a directory"
    exit 1
fi
