#!/bin/bash

set -e

source ./functions.sh

# needed for some `pip install`s
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

cat <<EOF >> /etc/environment
LC_ALL=${LC_ALL}
LANG=${LANG}
EOF

export SKIP_LAUNCH=1

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

install -m 644 dea-init.service /etc/systemd/system/dea-init.service
systemctl enable dea-init.service
