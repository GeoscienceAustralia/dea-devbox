#!/bin/bash

DIR=$(cd "$(dirname $(readlink -f "${BASH_SOURCE[0]}"))" && pwd)
# shellcheck source=./functions.sh
source "${DIR}/functions.sh"

[ ! -f /etc/apt/sources.list.d/nextgis-ubuntu-ppa-bionic.list ] && add_repos ppa:nextgis/ppa

datacube_version=${1:-"develop"}
gdal_version=${2:-"2.4.0"}

cat <<EOF
Installing Datacube and Geo Libs:
  DATACUBE  -- ${datacube_version}
  GDAL      -- ${gdal_version}
EOF

install_geo_libs "${gdal_version}"
install_datacube_lib "${datacube_version}"
