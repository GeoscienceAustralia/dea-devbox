# ec2-jupyter

This generates script for `userdata` section that sets up dev box from base ubuntu image.


## How to run

First create file `machine.env`

```
DOMAIN=<pick machine prefix>.dea.gadevs.ga
ADMIN_USER=<your github user name>
EMAIL=<your email>@ga.gov.au
OAUTH_CLIENT_ID=<this won't be needed>
OAUTH_CLIENT_SECRET=<this won't be needed>
```

Then type `make`. This will generate `install.sh` suitable for pasting into `userdata` field of the ec2 instance.

