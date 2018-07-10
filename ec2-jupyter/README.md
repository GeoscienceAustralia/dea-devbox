# ec2-jupyter

This generates script for `userdata` section that sets up dev box from base ubuntu image.

## How to run

Then type `make`. This will generate `install.sh` suitable for pasting into
`userdata` field of the ec2 instance that will create base for AMI. Currently
AMI creation is not automated, but there is a manually built one
`dev-jupyterhub`.

## Instance Configuration

Parameter store is used to configure common instance parameters

- `/dev/jupyterhub/email` set to dea developer email address (given to Let's Encrypt)
- `/dev/jupyterhub/oauth.callback.url` url for redirect lambda
- `/dev/jupyterhub/oauth.client.id` GitHub oauth app client id
- `/dev/jupyterhub/oauth.client.secret` GitHub aouth app secret key (encrypted)

Per instance configuration is done via tags

- `admin` GitHub username for admin user of the JupyterHub
- `domain` Need to be set to `{your-unique-subdomain}.devbox.gadevs.ga`

Once logged in `admin` user can add more users, including with admin privileges.
