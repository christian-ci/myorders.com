provider "aws" {
    region = "us-east-2"
    shared_credentials_file = "/home/christian/.aws/credentials"
    }
 
module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = ">=2.77.0"
    #Configuration
    name = "myorders-vpc"
    cidr = "10.1.0.0/16"
    azs  = ["us-east-2a", "us-east-2b", "us-east-2c"]
    #Subnets
    private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
    public_subnets = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
    #Network DNS enable and Nat over the available AZs
    enable_dns_hostnames = true
    enable_dns_support = true
    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true
    #VPC Endpoint for S3
    enable_s3_endpoint = true
    s3_endpoint_type = "Gateway"
    s3_endpoint_private_dns_enabled = false    
    }
output "vpc_id" {
     value = module.vpc.vpc_id
}
output "private_subnets_id" {
  value = module.vpc.private_subnets
}
module "gaccelerator_sg" {

    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    name = "gaccelerator_sg"
    description = "Security Group for Global Accelerator"
    vpc_id = module.vpc.vpc_id
    ingress_cidr_blocks = ["0.0.0.0/0"]
    ingress_rules = ["https-443-tcp", "http-80-tcp"]
}
output "gaccelerator_sg_id" {
    value = module.gaccelerator_sg.this_security_group_id
}
module "alb_sg" {
    
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    name = "alb_sg"
    description = "Security Group for Application Load Balancer"
    vpc_id = module.vpc.vpc_id
    ingress_cidr_blocks = ["0.0.0.0/0"]
    ingress_rules = ["https-443-tcp", "http-80-tcp"]  
}
output "alb_sg_id" {
  value = module.alb_sg.this_security_group_id
}
module "bastion_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    name = "bastion_sg"
    description = "Security Group for Bastion"
    vpc_id = module.vpc.vpc_id
    ingress_with_cidr_blocks = [
       { from_port = 22
        to_port = 22
        protocol = "tcp"
        description = "Allow access to Bastion Servers"
        cidr_blocks = "69.174.156.172/32"
       },
    ]   
}
output "bastion_sg_id" {
  value = module.bastion_sg.this_security_group_id
}
module "app_server_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    name = "app_server_sg"
    description = "Security Group for App Server"
    vpc_id = module.vpc.vpc_id
    ingress_with_source_security_group_id = [
       { 
        from_port = 80
        to_port = 80
        protocol = "tcp"
        source_security_group_id = module.alb_sg.this_security_group_id
       },
       {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        source_security_group_id = module.alb_sg.this_security_group_id
       },
    ]     
}
output "app_server_sg_id" {
    value = module.app_server_sg.this_security_group_id
}
module "sftp_server_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    name = "sftp_server_sg"
    description = "Security Group for SFTP server"
    vpc_id = module.vpc.vpc_id
    ingress_with_source_security_group_id = [
       { 
        from_port = 22
        to_port = 22
        protocol = "tcp"
        source_security_group_id = module.app_server_sg.this_security_group_id
       },       
    ]  
}
output "sftp_server_sg" {
  value = module.sftp_server_sg.this_security_group_id
}
module "db_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    name = "db_sg"
    description = "Security Group for SFTP server"
    vpc_id = module.vpc.vpc_id
    ingress_with_source_security_group_id = [
       { 
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        source_security_group_id = module.app_server_sg.this_security_group_id
       },       
    ]  
}
output "db_sg_id" {
  value = module.db_sg.this_security_group_id
}
locals {
  bucket_name = "s3-private-uploads-${random_string.random.result}"
}

data "aws_canonical_user_id" "current" {}

resource "random_string" "random" {
  length = 5
  special = true
  override_special = "-"
  upper = false
}

resource "aws_kms_key" "objects" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

resource "aws_iam_role" "this" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = ">=1.21.0"

  bucket                         = "myorders-logs-${random_string.random.result}"
  acl                            = "log-delivery-write"
  force_destroy                  = true
  attach_elb_log_delivery_policy = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "cloudwatch_log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = ">=1.21.0"

  bucket = "cloudwatch-logs-${random_string.random.result}"
  acl    = null
  grant = [{
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = data.aws_canonical_user_id.current.id
    }, {
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"    
  }]
  force_destroy = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "s3uploadprivate" {
    source = "terraform-aws-modules/s3-bucket/aws"
    version = ">=1.21.0"    
}
module "rds" {
    source = "terraform-aws-modules/rds/aws"
    version = ">=2.34.0"
    identifier = "myordersdb"
    #Main Engine, Instance Class and Storage config
    engine = "postgres"
    engine_version = "13.1"
    major_engine_version = "13"
    instance_class = "db.t3.medium"
    allocated_storage = 20
    max_allocated_storage = 100
    storage_encrypted = true
    create_db_parameter_group = false
    #Master account credentials 
    name = "myordersdb"
    username = "myordersadmin"
    create_random_password = true
    #Networking Settings
    port = 5432
    multi_az = true
    subnet_ids = module.vpc.private_subnets
    vpc_security_group_ids = [module.db_sg.this_security_group_id]
    #Monitoring and Maintance Windows
    maintenance_window = "Mon:03:01-Mon:06:00"
    backup_window = "01:00-03:00"
    enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
    backup_retention_period = 7
    deletion_protection = false
    #Performance Insights Config
    performance_insights_enabled = true
    performance_insights_retention_period = 7
    create_monitoring_role = true
    monitoring_interval = 60
}

# module "privates3" {
#     source = "terraform-aws-modules/s3-bucket/aws"
#     version = ">=1.21.0"

    
# }
# testing branch