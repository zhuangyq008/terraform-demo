# Use Terraform to build a classic three-tier architecture stack

![1679623260073](image/three-tier.jpg)

![1679623269805](image/iam-role.jpg)

* Terraform will create below resources
  * VPC
  * Application Load Balancer
  * Public & Private Subnets
  * EC2 instances
  * RDS instance
  * ElastiCache
  * AutoScalingGroup
  * Internet Gateway
  * Security Groups for Web & IAM Role
  * Route Table

## Configuration

./variables.tf 配置您这边资源的部署区域变量region: ap-southeast-1 (默认新加坡)

./application/variables.tf 配置app_ami 应用的AMI，如果有更换区域这个要调整

./application/variables.tf 配置app_inst_type对应的机型
