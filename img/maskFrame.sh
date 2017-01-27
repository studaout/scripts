#!/bin/bash

if [ $# -ne 1 ]; then
    echo "$0: usage: $0 dir_name"
    exit 1
fi

#ffmpeg -i P1050821.MOV -vframes 1 -f image2 imagefile.jp
 #ffmpeg -i 100_0624.MOV -vframes 5 -f image2 imagefoo-%03d.jpeg
dirName=$1
encDirName="${dirName}_enc"
tmpDir="${dirName}_tmp"
echo "Directory name: $dirName. Encoded files directory name $encDirName ."

if [ -d "$dirName" ]
then
    echo "Processing $dirName"
    mkdir $encDirName || exit 1
    #tar and archive with part size <= 10M
    tar cf - $dirName | 7z a -si -v10m $dirName || exit 1
    mv ${dirName}.7z.* $encDirName || exit 1
    fileCount=$(ls -1 | wc -l)
    firstVideoFile=$(ls -1 $dirName/* | grep -i -e mov$ -e mts$ -e avi$ -e mp4$ | head -1)
    mkdir $tmpDir || exit 1
    ffmpeg -i $firstVideoFile -vframes $fileCount -f image2 $tmpDir/sample%03d.jpg || exit 1
    cd $encDirName || exit 1
    sampleFileCounter=1
    for entry in *; do
       if [ -f "$entry" ]; then
          #remove .7z. from file name
           fileBase="${entry/\.7z\./\.}"
           #zero padded counter - fCounter
           printf -v fCounter "%03d" $sampleFileCounter
           sampleFileName="sample${fCounter}.jpg"
           encFileName="${fileBase}.jpg"
           #get smaple image size
           imgSize=$(stat -c%s "../$tmpDir/$sampleFileName")
           #echo "$imgSize"
           #merge sample image and archive
           cat ../$tmpDir/$sampleFileName ${entry} > "${encFileName}" || exit 1
           #attach sample image size - rounded to 10 bytes size with padded 0
           echo -n `printf "%010d" $imgSize` >> "${encFileName}" || exit 1
           rm $entry || exit 1
           let sampleFileCounter=sampleFileCounter+1
       fi
    done
    cd ../ || exit 1
    rm -fr $tmpDir
else
    echo "$dirName is not a directory"
    exit 1
fi
