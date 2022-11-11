function help
{
    echo "Usage: $0 [-n source_nodata_value] [-f FORMAT=geotiff] -o OVERWRITE[=false] -m [THREADING ALL_CPUS] [-i INTERPOLATION] -s TARGET_SRS -r TARGET_RES INFILE OUTFILE"
    exit
}

while getopts ":s:r:i:hom:f:n:" opt; do
    case "$opt" in
	s)
	    TARGET_SRS=$OPTARG
	    ;;
	f)
	    FORMAT=$OPTARG
	    ;;
	o)
	    OVERWRITE="-overwrite"
	    ;;
	r)
	    TARGET_RES=$OPTARG
	    ;;
	i)
	    INTERPOLATION=$OPTARG
	    ;;
	m)
	    THREADS=$OPTARG
	    ;;
	n)
	    NODATA=$OPTARG
	    ;;
	h)
	    help
	    ;;
	*) 
	    help
	    ;;
	:) 
	    echo "optarg not set"
	    exit
	    ;;
    esac
done

shift $((OPTIND-1))

if [[ -z $INTERPOLATION ]]
then
    INTERPOLATION=cubic
fi

if [[ -z $OVERWRITE ]]
then
    OVERWRITE=""
fi

if [[ -z $THREADS ]]
then
    THREADS=6
fi

if [[ -z $FORMAT ]]
then
    FORMAT=GTiff
fi

if [[ -z $AWS_CONFIG ]]
then
    AWS_CONFIG=""
fi

if [[ -z $NODATA ]]
then
    NODATA_ARG=""
else
    NODATA_ARG="-srcnodata $NODATA"
fi

set -e -u

INFILE=$1
OUTFILE=$2

gdalwarp $NODATA_ARG $AWS_CONFIG ${OVERWRITE} -of $FORMAT -tap -r $INTERPOLATION -t_srs "EPSG:$TARGET_SRS" -tr $TARGET_RES $TARGET_RES -co COMPRESS=LZW -co TILED=YES -co BIGTIFF=YES -multi -wo NUM_THREADS=$THREADS $INFILE $OUTFILE 
