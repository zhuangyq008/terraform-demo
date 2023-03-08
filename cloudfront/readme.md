# 配置Cloudfront分布


## 配置准备

1. [安装AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. 配置IAM用户并分配创建资源需要的权限，导出AK，SK
3. [安装Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## 代码说明

* 配置分布的源为S3
* 配置S3的访问策略是OAC
* 配置S3的行为，缓存配置
* 配置地理访问限制
* 配置访问日志写入日志存储桶

## 执行命令

```
# terraform cli
terraform init
terraform plan
terraform apply
```
