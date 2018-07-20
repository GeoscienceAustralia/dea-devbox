#!/bin/bash

set -eu

DIR=$(cd "$(dirname $(readlink -f "${BASH_SOURCE[0]}"))" && pwd)
# shellcheck source=./functions.sh
source "${DIR}/functions.sh"

install_notebook_extras
install_dev_tools
dea-install-datacube

ln -fs /usr/share/zoneinfo/Australia/Canberra /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
