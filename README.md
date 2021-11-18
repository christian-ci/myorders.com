# myorders.com
Terraform Example,
This implementation follows my design diagram and forks into V1 and V2.
If you'd like my design diagrams for the infrastructure. Email quantumtheory78@gmail.com.
Currently I am working on the project and I am not finished, any code that is present in this repo has been validated and tested with AWS
If you want to validate it, Just change your credentials at the top of main.tf and the region if you wish. 
***If you are applying to a Region with provisioned Elastic IPs, be aware that there is a max = 5 limit of provisioned
Elastic Ips. This terraform file follows the same design diagram and 3 NAT Gateways are created per AZ. This is why I am runnig on us-east-2.*** 

Author: Christian Carrasquillo 
