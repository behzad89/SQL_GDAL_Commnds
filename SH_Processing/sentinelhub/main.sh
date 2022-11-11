 #!/bin/bash

set -e -o pipefail

# Help function that displays basic instructions on the use of the tool
print_usage() {
  echo "main.sh"
  echo " "
  echo "Stitch together tiles from your SH Batch Processing API directly from your s3 bucket, and convert it to CSVs"
  echo "main.sh [options]"
  echo " "
  echo "options:"
  echo "-h		Show brief help"
  echo "-b		AWS Bucket name"
  echo "-r		Sentinel hub run ID"
  echo "-c		country"
  echo "-s		season"
  echo "-o		Output path to folder"
  
  exit 0
}

# Define input flags and variable assignment
while getopts 'b:c:r:s:o:h' flag; do
  case "${flag}" in
    b) AWS_BUCKET="${OPTARG}" ;;
    r) RUN_ID="${OPTARG}" ;;
    c) country="${OPTARG}" ;;
    o) OUTPUT_PATH="${OPTARG}" ;;
    s) SEASON="${OPTARG}" ;;
    h) print_usage
       exit 1 ;;
  esac
done

# Check for bucket name
if [ -z ${AWS_BUCKET+x} ];then
  echo "Bucket name (-b) is unset";
  exit 1
fi

# Check for output path
if [ -z ${OUTPUT_PATH+x} ];then
  echo "Output path to file (-o) is unset";
  exit 1
fi

# Check for output CRS
if [ -z ${country+x} ];then
  echo "country (-c,) is unset";
  exit 1
fi

# Check for interpolation method
if [ -z ${RUN_ID+x} ];then
  echo "Please set RUN ID"
  exit 1
fi

if [[ ! -e $OUTPUT_PATH ]]
then
    echo "Output path $OUTPUT_PATH doesn't exist"
    exit 1
else
    OUTPUT_PATH=${OUTPUT_PATH}/${RUN_ID}
    mkdir -p $OUTPUT_PATH
fi

echo "Preparing processing..."
aws s3 ls s3://$AWS_BUCKET --recursive | awk -v R=$RUN_ID '$4 ~ R {print $4}' | grep '.tif' | awk '$0="/vsis3/'$AWS_BUCKET'/"$0' > objects_vsis3.txt

# Collect CRS information of s3 objects and write them into lists named after their UTM zone
while read line; do
  p=$(echo $line | tr -d '[:space:]')
  filename=$(gdalsrsinfo -o proj4 $p | awk -F 'zone=' '{print $2}' |cut -c 1-2)
  name=$(echo ${filename} | head -c 2)
  if [[ -z ${name} ]]
  then
      continue
  fi
  echo $p >> ${name}_list.txt
done <objects_vsis3.txt

export PGPASSWORD=57fhrtUHN8#$
bash ./sentinelhub/get_cc_grid_info.sh $country | while read CRS RES;
do
# Loop over object lists, create virtual rasters from them for each UTM zone and write to local raster file(s)
for file_list in ./*_list.txt
do
   (
  zone=$(echo $file_list | awk -F '[_/]' '{print $2}')
  gdalbuildvrt -srcnodata 0 /vsistdout/ -input_file_list $file_list | gdalwarp -t_srs EPSG:$CRS -r cubic -co compress=lzw -co bigtiff=yes -srcnodata 0 -dstnodata 0 -multi -wo NUM_THREADS=ALL_CPUS /vsistdin/ $OUTPUT_PATH/$zone\_tmp_warp.tif
  ) &
done

wait

echo "Generating COG mosaic ..."
bash ./sentinelhub/align_with_cc_grid.sh -o -i cubic -s $CRS -r $RES -f GTiff "${OUTPUT_PATH}/*tmp_warp.tif" ${OUTPUT_PATH}/mosaic.tif

gdal_translate -of COG -co BIGTIFF=YES -co BLOCKSIZE=256 -co COMPRESS=DEFLATE -co Predictor=2 -co NUM_THREADS=ALL_CPUS ${OUTPUT_PATH}/mosaic.tif ${OUTPUT_PATH}/mosaic_cog.tif
done

#Cleanup
rm objects_vsis3.txt
rm ./*_list.txt
rm $OUTPUT_PATH/*_tmp_warp.tif
rm ${OUTPUT_PATH}/mosaic.tif


wait
echo "Converting to CSVs..."
mkdir -p ${OUTPUT_PATH}/CSVs
python ./sentinelhub/extract_S2_to_csv.py --input_path ${OUTPUT_PATH}/mosaic_cog.tif --output_path ${OUTPUT_PATH}/CSVs --season $SEASON
# Import the aligned image to the DB - The user name should be chnaged!
# bash ./geo-data-pipelines/tools/raster-tools/vector-feature-tools/raster2db.sh ${OUTPUT_PATH}/mosaic.tif sentinel_2_import_fi_2018_autumn


echo "Done!"
