# DevBox

Scripts for building developer focused AMI for datacube development/testing.

1. Updates DNS on restarts ({subdomain-of-your-choice}.dea.gadevs.ga)
2. Obtains SSL from "Let's Encrypt"
3. Runs JupyterHub instance with authentication via GitHub


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

If you don't need anything extra you can use security group `dea-dev-jupyterhub`.

## Launch Template

I have made a launch template `dev_jupyterhub` that uses AMI build from this
repo (currently manually for now).

1. Launch instance from template and select template and version
2. Customize tags for `domain` and `admin`
3. Optionally customize `Name` tag
4. Possibly change instance type
5. Press "Launch instance from template" button to launch


## Updating AMI

For now a manual process.

1. `make -C ec2-jupyter`
2. `cat ec2-jupyter/install.sh`
3. Launch ubuntu 16.04 instance with userdata set to the content of generated `ec2-jupyter/install.sh`
4. Wait for install to finish
5. Create snapshot and AMI from that
