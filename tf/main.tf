# Configure terraform

provider "aws" {
  region = "ap-southeast-2"
}

terraform {
  backend "s3" {
    bucket         = "dea-devs-tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform"
  }
}

# Variables

variable "servername" {
  description = "The name of your server, should be something unique"
}

variable "keypair_name" {
  description = "The name of your keypair"
}

variable "dns_zone" {
  default = "devbox.gadevs.ga"
}

# Create server

resource "aws_instance" "devbox" {
  ami           = "ami-50c93132"
  instance_type = "t2.micro"
  user_data     = "${file("userdata.sh")}"

  tags {
    Name = "${var.servername}-DevBox"
  }

  associate_public_ip_address = true
}

# Configure DNS

data "aws_route53_zone" "selected" {
  name = "${var.dns_zone}."
}

resource "aws_route53_record" "record" {
  name    = "${var.servername}"
  zone_id = "${data.aws_route53_zone.selected.id}"
  type    = "A"
  ttl     = "300"

  records = ["${aws_instance.devbox.public_ip}"]
}

# Outputs
output "ssh_address" {
  value = "ubuntu@${aws_instance.devbox.public_ip}"
}

output "dns" {
  value = "${aws_route53_record.record.fqdn}"
}
