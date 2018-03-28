# ec2-jupyter

This generates script for `userdata` section that sets up dev box from base ubuntu image.


## How to run

First create file `machine.env`

```
DOMAIN=<pick machine prefix>.dea.gadevs.ga
ADMIN_USER=<your github user name>
EMAIL=<your email>@ga.gov.au
OAUTH_CLIENT_ID=<this won't be needed in the future>
OAUTH_CLIENT_SECRET=<this won't be needed in the future>
```

Then type `make`. This will generate `install.sh` suitable for pasting into `userdata` field of the ec2 instance.

## EC2 Instance setup

Policies:

- `dns-for-dea.gadevs.ga`

But you'll probably want S3 access as well.

Ports:

- HTTP 80
- HTTPS 443
- SSH 22
