#!/bin/bash
cp $1 ./temp_$1
size=($(/usr/local/bin/ffmpeg -i $1 2>&1 | perl -lane 'print $1 if /(\d+x\d+)/'))
arrSize=(${size//x/ })
x=(${arrSize[0]})
y=(${arrSize[1]})
/usr/local/bin/ffmpeg -i $1 -sws_flags lanczos -s $(( x / 3 ))\x$(( y / 3 )) -vcodec mpeg4 -b 100kb -an temp_$1
curl -k -H "Authorization: Bearer your-token" -X POST -F "encoded_data=@"temp_$1"" https://api.clarifai.com/v1/tag/ -o temp_out.json 
rm temp_$1
