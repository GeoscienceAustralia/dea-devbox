#!/bin/sh

set -eu

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

cat <<EOF > /tmp/dea.preseed
tzdata tzdata/Areas select Australia
tzdata tzdata/Zones/Australia select Canberra
locales locales/locales_to_be_generated multiselect     en_US.UTF-8 en_AU.UTF-8 UTF-8
locales locales/default_environment_locale      select  en_AU.UTF-8
EOF

debconf-set-selections /tmp/dea.preseed

apt-get update
apt-get upgrade -y

# configure s3 transport for apt
apt-get install -y awscli
apt-get install -y python3-pip
pip3 install --no-cache boto3

aws s3 cp s3://dea-devbox-apt/apt-s3-repo-config.tgz /tmp/
(cd /; tar xvzf /tmp/apt-s3-repo-config.tgz)

# Install dea-devbox
apt-get update
apt-get install -y dea-devbox
/usr/share/dea/dea-ami-setup.sh

# in case it was installed in the base image, reconfigure
dpkg-reconfigure tzdata

# Cleanup
apt-get clean

