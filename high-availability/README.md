### Terraform script to create a high availability Rancher server in aws ### 

The script:
1. creates 3 instances in aws
2. creates target groups for ports 80 and 443
3. creates a load balancer
4. create a route 53 record
5. uses RKE to create a k8s cluster
6. uses helm to install certs and rancher

NOTE: 
as you can see almost all parameters are using variables but the values for those variables are not present. I store them in a `.sh` file on my local and run `./variables.sh` before running `terraform apply`.

This is a variables.sh file with environment variables for this script (fill out with your values):
```
# aws creds
export TF_VAR_aws_region=
export TF_VAR_aws_access_key=
export TF_VAR_aws_secret_key=

#######################################################################

# aws instance info
# ec2 info
export TF_VAR_aws_prefix=
export TF_VAR_aws_ami=ami-
export TF_VAR_aws_instance_type=
export TF_VAR_aws_subnet_a=
export TF_VAR_aws_subnet_b=
export TF_VAR_aws_subnet_c=
export TF_VAR_aws_security_group=
export TF_VAR_aws_key_name=
export TF_VAR_aws_instance_size=
export TF_VAR_aws_vpc=
# route 53 info
export TF_VAR_aws_route_zone_name=

#######################################################################

# ssh info
export TF_VAR_ssh_private_key_path=

# kubeconfig path
export TF_VAR_kube_config_path=

#######################################################################

# rancher info
export TF_VAR_rancher_tag_version=
export TF_VAR_rancher_chart_version=
export TF_VAR_rancher_password=
```

You also can use a separate file to store variables `.tfvars`. 
Please refer to the official documents how to use variables in terraform https://www.terraform.io/language/values