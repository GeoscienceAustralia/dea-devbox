# ec2-jupyter

This generates script for `userdata` section that sets up dev box from base ubuntu image.

## How to run

Then type `make`. This will generate `install.sh` suitable for pasting into
`userdata` field of the ec2 instance that will create base for AMI. Currently
AMI creation is not automated, but there is a manually built one
`dev-jupyterhub`.

## EC2 Instance setup

Policies:

- `dns-for-dea.gadevs.ga` for updating DNS records
- `AmazonEC2ReadOnlyAccess` for querying tags
- `AmazonSSMReadOnlyAccess` for querying secrets

These are part of `dev-jupyter` role, should be tuned to have smaller permission
surface, particularly SSM.

But you'll probably want S3 access as well.

Ports:

- HTTP 80
- HTTPS 443
- SSH 22

If you don't need anything extra you can use `dea-dev-jupyterhub`.


## Launch Template

I have made a launch template `dev_jupyterhub` that uses AMI build from this
repo (currently manually for now).

1. Launch instance from template and select template and version
2. Customize tags for `domain` and `admin`
3. Optionally customize `Name` tag
4. Possibly change instance type
5. Press "Launch instance from template" button to launch
