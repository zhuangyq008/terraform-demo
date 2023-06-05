# Infrastructure as Code with Terraform

## Prerequisites

1. Terraform installed for stack deployment https://learn.hashicorp.com/tutorials/terraform/install-cli

2. A user with proper privilleges is prepared with AK and SK for terraform run

3. Configure environment values for terraform aws provider

``` bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_REGION="us-west-2"
```
OR
[install aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) ,thean run the command `aws configure`
4. Install [!kubectl](https://kubernetes.io/docs/tasks/tools/)


### Terraform Run

You can apply the script below to setup EKS cluster for the demo.

``` bash
terraform init
terraform apply --auto-approve
```

### Terraform Cleanup

``` bash
terraform destroy --auto-approve
```

## Two Steps Setup for eShop IaC

### Step One - Terraform

- Within this step, majority of your services will be setup and configured properly
- Helmcharts and Kubernetes native supporting workloads can also be included in this step

### Step Twon - CRD apply

- Due to the limitation on Terraform Kubernetes provider for resource `kubernetes_manifast`, you have to apply all CRD resources in the second steps. Limitation: to run `terraform plan` for `kubernetes_manifast`, it requires the API access of your Kubernetes cluster.
- CRDs like OpenTelemetryOperator, Cluster Autoscaler, External Secrets and etc. should be considered to place in the second deployment steps.

## Run Through

In the current directory, you can run terraform and kubectl to finish the baseline installation

```shell
terraform plan -out=stack.out
terraform apply "stack.out"
# the command below will collect all Kubernetes yaml files to deploy
kubectl apply -f ./collector/
```

## configure eks cluster

`aws eks update-kubeconfig --region region-code --name my-cluster`
then
`kubectl get svc`

[how to create kubeconfig file](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/create-kubeconfig.html)