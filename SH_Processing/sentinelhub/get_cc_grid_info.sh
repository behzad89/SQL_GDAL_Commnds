set -u -e -o pipefail

GRID=$1

echo "select crs, cell_size from aoi.cc_grid_definitions where abbreviation = '$GRID' or name = '$GRID';" | psql --no-align -F " " -t -h geodb.collectivecrunch.net -U behzad -p 7432 geodb
																
