############################# T E R R A F O R M #############################
# use aws provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.0"
    }
  }
}

# aws settings
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

############################# E C 2 #############################
# resource to create an instance
resource "aws_instance" "aws_instance" {
  ami             = var.aws_ami
  instance_type   = var.aws_instance_type
  subnet_id       = var.aws_subnet
  vpc_security_group_ids = [var.aws_security_group]
  key_name = var.aws_key_name

  root_block_device {
    volume_size = var.aws_instance_size
  }

  tags = {
    Name = var.aws_prefix
  }

  # SSH into the instance
  connection {
    type        = "ssh"
    host        = aws_instance.aws_instance.public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  # run docker install command
  provisioner "remote-exec" {
    inline = [
      "sudo docker run -d --privileged --restart=unless-stopped -p 80:80 -p 443:443 -e CATTLE_BOOTSTRAP_PASSWORD=${var.rancher_password} rancher/rancher:${var.rancher_version} --acme-domain ${var.aws_prefix}.${var.aws_route_zone_name}"
    ]
  }
}

# print the instance info
output "instance_public_ip" {
  value = aws_instance.aws_instance.public_ip
}
output "instance_private_ip" {
  value = aws_instance.aws_instance.private_ip
}

############################# R O U T E   5 3 #############################
# find route 53 zone id 
data "aws_route53_zone" "zone" {
  name = var.aws_route_zone_name
}

# create a route53 record using the aws_instance
resource "aws_route53_record" "route_53_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.aws_prefix
  type    = "A" 
  ttl     = "300"
  records = [aws_instance.aws_instance.public_ip]
}

# print route53 full record
output "route_53_record" {
  value = aws_route53_record.route_53_record.fqdn
}

############################# V A R I A B L E S #############################
variable "aws_prefix" {}

variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_ami" {}
variable "aws_instance_type" {}
variable "aws_subnet_a" {}
variable "aws_subnet_b" {}
variable "aws_subnet_c" {}
variable "aws_security_group" {}
variable "aws_key_name" {}
variable "aws_instance_size" {}
variable "aws_vpc" {}

variable "aws_route_zone_name" {}

variable "ssh_private_key_path" {}

variable "rancher_version" {}
variable "rancher_password" {}
