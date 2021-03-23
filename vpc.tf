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