#!/bin/bash

set -e

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./functions.sh
source "${DIR}/functions.sh"

# needed for some `pip install`s
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

cat <<EOF >> /etc/environment
LC_ALL=${LC_ALL}
LANG=${LANG}
EOF

## Set up all extra repos
add_repos ppa:certbot/certbot ppa:nextgis/ppa

install_common_py
install_jh_proxy
install_jupyter_hub
install_notebook
install_geo_libs
install_datacube_lib
install_db
install_dev_tools

apt-get clean

systemctl enable dea-init.service
