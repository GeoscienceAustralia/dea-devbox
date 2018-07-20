#!/bin/sh

set -eu
apt-get update

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

# Cleanup
apt-get clean

