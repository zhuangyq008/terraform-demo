# Terraform demo

## 配置准备

1. [安装AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. 配置IAM用户并分配创建资源需要的权限，导出AK，SK
3. [安装Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## terraform-ec2-with-cloudwatchagent

这个demo是通过terraform配置ALB，EC2 with AutoscalingGroup, EC2通过userdata初始化了一个web应用、cloudwatch agent的安装

配置说明：

配置好AWS CLI 的**aws_access_key_id, aws_secret_access_key**

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

## 执行

```
cd terraform-ec2-with-cloudwatchagent
terraform init 
terraform validate #检查配置
terraform paln
terraform apply #应用配置
terraform destroy # 销毁配置
```

## Terraform维护命令

### 删除某个资源


要单独删除 Terraform 配置文件中的某个资源（resource），可以使用 `terraform destroy` 命令。具体操作如下：

1. 在 Terraform 配置文件目录下运行 `terraform state list` 命令，列出当前所有的资源。
2. 找到要删除的资源在列表中的名称（resource name），并记录下来。
3. 运行 `terraform destroy -target=<resource_name>` 命令，其中 `<resource_name>` 是要删除的资源的名称。例如，要删除一个名为 `aws_instance.example` 的 EC2 实例，可以运行以下命令：

terraform destroy -target=aws_instance.example

Terraform 将只删除指定的资源，而不会删除其他资源。在删除前，它会提示你确认是否要删除该资源。如果你确认要删除，请输入 `yes`，Terraform 将删除该资源。

请注意，使用 `terraform destroy` 命令删除资源只会删除该资源在 Terraform 中的状态，而不会直接删除 AWS 或其他云提供商的实际资源。要删除实际的资源，请使用相应的云提供商工具（如 AWS CLI）。
