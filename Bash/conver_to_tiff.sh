#! /bin/bash

# By Behzad Valipour Sh. (bvs@collectivecrunch.com)
# Bash script to read MrSID files in a directory and convert them into GeoTiff files.
# In the next step write to a multi-band GeoTiff. 


echo "Conversion of SID to GeoTiff"
for filename in /data/mnt/work/lithuania/ortophotos/sid/ORT10LT_2019/*.sid 
do
n=${filename#*/ORT10LT_2018/}
n=${n%.*}

if [[ -e /data/mnt/work/lithuania/ortophotos/ort_2019/$n.tif ]]
then
    echo "File /data/mnt/work/lithuania/ortophotos/ort_2019/$n.tif already exists, skipping"
    continue
fi

gdal_translate -a_srs EPSG:3346 -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 $filename /data/mnt/work/lithuania/ortophotos/ort_2018/$n.tif
done
echo "Conversion was Done!"

echo "Getting the list of converted files"
ls /data/mnt/work/lithuania/ortophotos/ort_2019/*.tif > list.txt

echo "Making mosaic out of file's list"
gdalwarp -co BIGTIFF=YES --optfile /data/mnt/work/lithuania/ortophotos/ort_2019/list.txt /work/lithuania/ortophotos/ort_2019/ort_mosaic_lithuania_2019.tif

echo "Process was done!"
