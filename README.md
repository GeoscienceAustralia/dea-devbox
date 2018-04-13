# DevBox

Scripts for building developer focused AMI for datacube development/testing.

1. Updates DNS on restarts ({subdomain-of-your-choice}.dea.gadevs.ga)
2. Obtains SSL from "Let's Encrypt"
3. Runs JupyterHub instance with authentication via GitHub

## Launch Template

I have made a launch template `dev_jupyterhub` that uses AMI build from this
repo.

1. [Launch instance from template](https://ap-southeast-2.console.aws.amazon.com/ec2/v2/home?region=ap-southeast-2#LaunchInstanceFromTemplate:launchTemplateId=lt-00d6c986fe2cec39a)
2. Customize tags for `domain` and `admin`
3. Optionally customize `Name` tag
4. Set `Key name` field to the key you use (needed for ssh access)
5. Possibly change instance type
6. Press "Launch instance from template" button to launch

Once launched, wait a few minutes for initial setup to complete, then go to 

```
https://{subdomain-you-chose}.dea.gadevs.ga
```

you should be presented with jupyter hub authentication screen. Authentication is done via GitHub.

When not in use power down the machine. Once started again it will update DNS record accorodingly
so you will be able access it at the same address. To start instance without loging into console
you can use `aws-cli`

```
aws ec2 start-instances --instance-ids i-{your-instance-id}
```

Before destroying the instance please run the following command:

```
sudo /opt/dea/dea-destroy.sh
```

this will revoke SSL certificate before we loose access to them when disk is destroyed.


## Manual EC2 Instance setup

If not using template.

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


## Updating AMI

For now a manual process.

1. `make -C ec2-jupyter`
2. `cat ec2-jupyter/install.sh`
3. Launch ubuntu 16.04 instance with userdata set to the content of generated `ec2-jupyter/install.sh`
4. Wait for install to finish
5. Create snapshot and AMI from that
