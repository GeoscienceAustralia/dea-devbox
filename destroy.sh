read -p "Enter username: " username

export TF_VAR_servername=$username
export TF_VAR_keypair_name="filler"

terraform init -backend-config="key=dev/$TF_VAR_servername-devbox"
terraform destroy -force