#!/bin/sh

set -eu

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

cat <<EOF > /tmp/dea.preseed
tzdata tzdata/Areas select Australia
tzdata tzdata/Zones/Australia select Sydney
locales locales/locales_to_be_generated multiselect     en_US.UTF-8 en_AU.UTF-8 UTF-8
locales locales/default_environment_locale      select  en_AU.UTF-8
EOF

debconf-set-selections /tmp/dea.preseed

apt-get update
apt-get upgrade -y

# configure s3 transport for apt
apt-get install -y python3-pip curl
pip3 install --no-cache boto3 awscli

install -D -m 755 ./s3.py /usr/lib/apt/methods/s3

# Install tools for building/running xar files
curl --silent -L https://github.com/Kirill888/static-xarexec/releases/download/v0.1.2/xarexec-static.tgz | (cd /bin/; tar xzv)

# Install dea-devbox
install -D -m 644 ./dea-devbox.list /etc/apt/sources.list.d/dea-devbox.list
apt-get update
apt-get install -y dea-devbox
/usr/share/dea/dea-ami-setup.sh

# configure time zone
timedatectl set-timezone Australia/Sydney
timedatectl

# Cleanup
apt-get clean

# Check versions of important apps

echo "Datacube"
datacube --version
echo "RIO"
rio --version
rio --gdal-version
echo "GDAL"
gdal-config --version

