#!/bin/bash

# we create symlinks to transient files that disappear after reboot
# so we need to clean them on boot
find /etc/nginx/conf.d/ -xtype l -delete
