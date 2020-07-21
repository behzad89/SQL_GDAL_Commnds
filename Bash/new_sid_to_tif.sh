#! /bin/bash

printf "%s\n" {1..8} | cat /data/mnt/work/lithuania/ortophotos/sid/ORT10LT_2018/SID/ort_files_2018.txt|while read n
do

if [[ -e /data/mnt/work/lithuania/ortophotos/ort_2018/"${n%.*}.tif" ]]
then
    echo "File /data/mnt/work/lithuania/ortophotos/ort_2018/"${n%.*}.tif" already exists, skipping"
    continue
fi
 echo "Starting conversion"
 gdal_translate -a_srs EPSG:3346 -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 /data/mnt/work/lithuania/ortophotos/sid/ORT10LT_2018/SID/"${n}" /data/mnt/work/lithuania/ortophotos/ort_2018/"${n%.*}.tif" &
 
 if (( ++i % 8 == 0 ))
 then
  echo "Waiting..."
  wait
 fi
done

