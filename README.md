# DevBox

Scripts for building developer focused AMI for datacube development/testing.

1. Updates DNS on restarts ({subdomain-of-your-choice}.devbox.gadevs.ga)
2. Load wild-card SSL certificate from S3 (not saved to EBS)
3. Runs JupyterHub instance with authentication via GitHub

## Launch Template

I have made a launch template `devbox` that uses AMI build from this
repo.

1. [Launch instance from template](https://ap-southeast-2.console.aws.amazon.com/ec2/v2/home?region=ap-southeast-2#LaunchInstanceFromTemplate:launchTemplateId=lt-0f58ab771dd16e763)
2. Customize tags for
   - `domain` set to `{subdomain-of-your-choice}.devbox.gadevs.ga`
   - `admin` set to your GitHub username
   - `Name` descriptive name shown in the "Instances" table on AWS console (optional)
3. Set `Key name` field to the key you use (needed for ssh access)
4. Possibly change instance type
5. Press "Launch instance from template" button to launch

Once launched, wait a few minutes for initial setup to complete, then go to

```
https://{subdomain-you-chose}.devbox.gadevs.ga
```

you should be presented with jupyter hub authentication screen. Authentication is done via GitHub.

When not in use power down the machine. Once started again it will update DNS record accorodingly
so you will be able access it at the same address. To start instance without loging into console
you can use `aws-cli`

```
aws ec2 start-instances --instance-ids i-{your-instance-id}
```

## Manual EC2 Instance setup

If not using template.

Policies:

- `devbox-route53` for updating DNS records
- `AmazonEC2ReadOnlyAccess` for querying tags
- `AmazonSSMReadOnlyAccess` for querying secrets
- S3 read access to `/dea-devbox-config/SSL/certs.tgz.gpg`

These are part of `dea-devbox` role, should be tuned to have smaller permission
surface, particularly SSM.

Ports:

- HTTPS 443 (limit to GA office)
- SSH 22 (limit to GA office)

If you don't need anything extra you can use security groups: `ga-http` and `ga-ssh`.


## Instance Configuration

Parameter store is used to configure common instance parameters

- `/dev/jupyterhub/oauth.callback.url` url for redirect lambda
- `/dev/jupyterhub/oauth.client.id` GitHub oauth app client id
- `/dev/jupyterhub/oauth.client.secret` GitHub aouth app secret key (encrypted)
- `/dev/devbox/key` symmetric key used to encrypt certificates

Wild-card certificates are stored in `s3://dea-devbox-config/SSL/certs.tgz.gpg`
encrypted with the key kept in `/dev/devbox/key`.

Per instance configuration is done via tags

- `admin` GitHub username for admin user of the JupyterHub
- `domain` Need to be set to `{your-unique-subdomain}.devbox.gadevs.ga`

Once logged in, `admin` user can add more users, including with admin privileges.


## Updating AMI

- Build `dea-devbox-${version}.deb` by running `make`
- Upload it to private apt repo `make upload`
- Build AMI `cd ami && packer devbox.json` or `make ami`

To build `.deb` you need `make dpkg-dev fakeroot pip3 jinja2-cli`, to upload to
private apt repo we use ruby based tool: `deb-s3`.

```
apt-get install -y make fakeroot dpkg-dev python3-pip ruby git
pip3 install jinja2-cli
gem install deb-s3

git clone https://github.com/GeoscienceAustralia/dea-devbox.git
cd dea-devbox
make && make upload
```

You need `dea-devbox-apt-rw` policy or general write to S3 permissions, to upload to the repo.


## Updating SSL

TODO
