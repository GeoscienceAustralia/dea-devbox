# ec2-jupyter

This generates script for `userdata` section that sets up dev box from base ubuntu image.

## How to run

Then type `make`. This will generate `install.sh` suitable for pasting into
`userdata` field of the ec2 instance that will create base for AMI. Currently
AMI creation is not automated, but there is a manually built one
`dev-jupyterhub`.

