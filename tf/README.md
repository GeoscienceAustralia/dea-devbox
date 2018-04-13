# DevBox
Generates an AWS EC2, and runs userdata.sh to set it up.

## Requirements:
- Access to DEA AWS account
- AWS CLI installed, and credentials configured https://aws.amazon.com/cli/ 
- Terraform installed https://www.terraform.io/downloads.html 
- AWS Keypair


## Usage

`bash create.sh`
```
Enter username: yourname
Enter KeyPair Name: aws-key
```

Will give you 

```
Outputs:

dns = yourname.dea.gadevs.ga
ssh_address = ubuntu@54.252.168.33
```