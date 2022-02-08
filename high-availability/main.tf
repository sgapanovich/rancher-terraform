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
############################# I N S T A N C E S #############################
# create 3 instances 
resource "aws_instance" "aws_instance" {
  count = 3
  ami                    = var.aws_ami
  instance_type          = var.aws_instance_type
  subnet_id              = var.aws_subnet_a
  vpc_security_group_ids = [var.aws_security_group]
  key_name               = var.aws_key_name

  root_block_device {
    volume_size = var.aws_instance_size
  }

  tags = {
    Name = "${var.aws_prefix}-${count.index}"
  }
}


############################# L O A D   B A L A N C E R #############################
# create a target group for 80
resource "aws_lb_target_group" "aws_lb_target_group_80" {
  name        = "${var.aws_prefix}-80"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.aws_vpc
  health_check {
    protocol          = "TCP"
    port              = "traffic-port"
    healthy_threshold = 3
    interval          = 10
  }
}

# create a target group for 443
resource "aws_lb_target_group" "aws_lb_target_group_443" {
  name        = "${var.aws_prefix}-443"
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.aws_vpc
  health_check {
    protocol          = "TCP"
    port              = 443
    healthy_threshold = 3
    interval          = 10
  }
}

# attach instances to the target group 80
resource "aws_lb_target_group_attachment" "attach_tg_80" {
  count = length(aws_instance.aws_instance)
  target_group_arn = aws_lb_target_group.aws_lb_target_group_80.arn
  target_id        = aws_instance.aws_instance[count.index].id
  port             = 80
}

# attach instances to the target group 443
resource "aws_lb_target_group_attachment" "attach_tg_443" {
  count = length(aws_instance.aws_instance)
  target_group_arn = aws_lb_target_group.aws_lb_target_group_443.arn
  target_id        = aws_instance.aws_instance[count.index].id
  port             = 443
}

# create a load balancer
resource "aws_lb" "aws_lb" {
  load_balancer_type = "network"
  name               = "${var.aws_prefix}-lb"
  internal           = false
  ip_address_type    = "ipv4"
  subnets            = [var.aws_subnet_a, var.aws_subnet_b, var.aws_subnet_c]
}

# add a listener for port 80
resource "aws_lb_listener" "aws_lb_listener_80" {
  load_balancer_arn = aws_lb.aws_lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aws_lb_target_group_80.arn
  }
}

# add a listener for port 443
resource "aws_lb_listener" "aws_lb_listener_443" {
  load_balancer_arn = aws_lb.aws_lb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aws_lb_target_group_443.arn
  }
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
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.aws_lb.dns_name]
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
