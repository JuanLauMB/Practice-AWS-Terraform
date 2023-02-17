# Mission-1-AWS-Terraform
- Install Apache on the Apache web servers.
- Install Nginx on the Nginx web servers.
- The web servers should be able to access the PostgreSQL RDS instance on port 5432.
- Create a scheduled scaling rule on your spot fleet so that it will scale in to 0 instance at 5PM PHT and scale out to 2 instance at 8AM PHT.
- Create a lambda function and cloudwatch rules for the scheduled start/stop of your RDS instance. Follow the same scale in/out schedule of the spot fleet. You may use any programming language that you prefer.
- Configure the ALB so that requests with the path /apache will forward the to the Apache web servers and requests with the path /nginx will forward to the Nginx web servers.
- **Note:** Be as strict as possible with your security group rules.
- *** Partially completed. Scheduled scale in/out of RDS using Lambda and Cloudwatch not included.
