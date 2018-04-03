# ec2-jupyter

This generates script for `userdata` section that sets up dev box from base ubuntu image.


## How to run

Then type `make`. This will generate `install.sh` suitable for pasting into `userdata` field of the ec2 instance that will create base for AMI.

## EC2 Instance setup

Policies:

- `dns-for-dea.gadevs.ga`

But you'll probably want S3 access as well.

Ports:

- HTTP 80
- HTTPS 443
- SSH 22

If you don't need anything extra you can use `dea-dev-jupyterhub`.
