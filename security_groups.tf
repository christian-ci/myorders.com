module "gaccelerator_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    
    name = "gaccelerator_sg"
    description = "Security Group for Global Accelerator"
    vpc_id = module.vpc.vpc_id
    ingress_cidr_blocks = ["0.0.0.0/0"]
    ingress_rules = ["https-443-tcp", "http-80-tcp"]
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

module "db_sg" {
    source  = "terraform-aws-modules/security-group/aws"
    version = ">=3.18.0"
    
    name = "db_sg"
    description = "Security Group for the PostgreSQL Database"
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