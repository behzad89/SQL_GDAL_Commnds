for f in *.tif
do
   gdaladdo -ro --config COMPRESS_OVERVIEW JPEG --config PHOTOMETRIC_OVERVIEW YCBCR --config INTERLEAVE_OVERVIEW PIXEL --config GDAL_NUM_THREADS 12 $f 2 4 8 16 32 64
done
