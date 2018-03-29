#!/bin/bash

set -e

source ./functions.sh
source ./machine.env

domain=${1:-$DOMAIN}
domain_prefix=$(echo $domain | cut -d . -f 1)
admin_user=${2:-$ADMIN_USER}
email=${3:-$EMAIL}

# needed for some `pip install`s
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

cat <<EOF >> /etc/environment
LC_ALL=${LC_ALL}
LANG=${LANG}
EOF

install -m 755 -d /etc/jupyterhub/
cat <<EOF > /etc/jupyterhub/jupyterhub.conf
DOMAIN=${domain}
ADMIN_USER=${admin_user}
EMAIL=${email}
OAUTH_CLIENT_ID=${OAUTH_CLIENT_ID}
OAUTH_CLIENT_SECRET=${OAUTH_CLIENT_SECRET}
OAUTH_CALLBACK_URL=${OAUTH_CALLBACK_URL}
OAUTH_CALLBACK_POSTFIX=${domain_prefix}
EOF

## Set up all extra repos
add_repos ppa:certbot/certbot ppa:nextgis/ppa

install_common_py
install_jh_proxy
install_jupyter_hub
install_notebook
install_geo_libs
install_datacube_lib
install_datacube_db
add_db_super_user "${admin_user}"
add_db_super_user "ubuntu"

apt-get clean
