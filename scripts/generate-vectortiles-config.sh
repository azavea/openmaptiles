#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

cd /import

if [ "$#" -ne 1 ]; then
    echo "We need only 1 area parameter!"
    exit
fi

AREA=$1
DOCKER_COMPOSE_FILE=./docker-compose-config.yml

ls "${AREA}.osm.pbf"  -la
osmconvert  --out-statistics  ${AREA}.osm.pbf  > ./osmstat.txt

lon_min=$( cat osmstat.txt | grep "lon min:" |cut -d":" -f 2 )
lon_max=$( cat osmstat.txt | grep "lon max:" |cut -d":" -f 2 )
lat_min=$( cat osmstat.txt | grep "lat min:" |cut -d":" -f 2 )
lat_max=$( cat osmstat.txt | grep "lat max:" |cut -d":" -f 2 )
timestamp_max=$( cat osmstat.txt | grep "timestamp max:" |cut -d" " -f 3 )

echo "--------------------------------------------"
echo BBOX: "$lon_min,$lat_min,$lon_max,$lat_max"
echo TIMESTAMP MAX = $timestamp_max
echo MIN_ZOOM: "$MIN_ZOOM"
echo MAX_ZOOM: "$MAX_ZOOM"
echo "--------------------------------------------"

cat > $DOCKER_COMPOSE_FILE  <<- EOM
version: "2"
services:
  generate-vectortiles:
    environment:
      BBOX: "$lon_min,$lat_min,$lon_max,$lat_max"
      OSM_MAX_TIMESTAMP : "$timestamp_max"
      OSM_AREA_NAME: "$AREA"
      MIN_ZOOM: "$MIN_ZOOM"
      MAX_ZOOM: "$MAX_ZOOM"
EOM
