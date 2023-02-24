# Terraform demo

## terraform-ec2-with-cloudwatchagent

这个demo是通过terraform配置ALB，EC2 with AutoscalingGroup, EC2通过userdata初始化了一个web应用、cloudwatch agent的安装

配置说明：

**variables.tf**配置了部分参数:

image_id: 这个是新加坡region的AMI AL2 X84_64，如果要换成其他区域调整成匹配的AMI ID

key_name:  配置对应region的keypair name

在**main.tf参数:**

vpcid: 配置您region对应的VPC ID

subnetIds: 配置VPC ID ，目前这边用的public subnets；

securityGroups: 配置安全组ID，开放80，8080，22

**配置cloudwatch agent**

在cloud-init.yml配置程序安装及配置初始化，这边的例子是从我的bucket下载应用，您这边需要调整成自己的。

path= `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`

这个是配置cloudwatch agent的配置，您可以参考调整成您的采集目录及日志格式
