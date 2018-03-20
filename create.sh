read -p "Enter username: " username
read -p "Enter KeyPair Name: " keypair

# convert variables to be read by terraform
export TF_VAR_servername=$username
export TF_VAR_keypair_name=$keypair

terraform init -backend-config="key=dev/$TF_VAR_servername-devbox"
terraform plan
terraform apply -auto-approve