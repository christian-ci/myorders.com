# myorders.com
Terraform implementation of myorders.com challenge. 
This implementation follows my design diagram and forks into V1 and V2.
Currently I am working on the project, any code that is present in this repo has been validated and tested
If you want to validate it, Just change your credentials at the top of main.tf
If you are applying to a Region with provisioned Elastic IPs, be aware that there is a max = 5 limit of provisioned
Elastic Ips. This terraform file follows the same design diagram and 3 NAT Gateways are created per AZ. This is why I am runnig on us-east-2. 
Author: Christian Carrasquillo
