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
    password = "testingenvironmentdev1"
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