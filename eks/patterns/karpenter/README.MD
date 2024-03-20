# [https://aws.github.io/aws-eks-best-practices/karpenter/]()EKS Karpenter

## Karpenter

在使用 Karpenter 之前，Kubernetes 用户需要动态调整其集群的计算容量，以支持使用 Amazon EC2 Auto Scaling 组和 Kubernetes 集群 Autoscaler 的应用程序。AWS 上近一半的 Kubernetes 客户报告说，使用 Kubernetes Cluster Autoscaler 配置集群 Auto Scaling 具有挑战性且具有限制性。

当 Karpenter 安装在集群中时，Karpenter 会观察未调度 Pod 的聚合资源请求，并决定启动新节点并终止它们，以减少调度延迟和基础设施成本。Karpenter 通过观察 Kubernetes 集群中的事件，然后将命令发送到底层云提供商的计算服务（如 Amazon EC2）来实现这一点。

## Karpenter Best Practices

[参考官网](https://aws.github.io/aws-eks-best-practices/karpenter/)

## 部署向导

```shell
terraform init
terraform plan
terraform apply

```

安装后将输出 然后在terminal执行更新kubeconfig

```
aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}
```

测试

```
kubectl apply -f karpenter.yaml
kubectl apply -f example.yaml
kubectl scale deployment inflate --replicas=3
kubectl get nodes

NAME                                                STATUS   ROLES    AGE   VERSION
fargate-ip-10-0-11-195.us-west-2.compute.internal   Ready    <none>   13m   v1.28.2-eks-f8587cb
fargate-ip-10-0-27-183.us-west-2.compute.internal   Ready    <none>   12m   v1.28.2-eks-f8587cb
fargate-ip-10-0-4-169.us-west-2.compute.internal    Ready    <none>   12m   v1.28.2-eks-f8587cb
fargate-ip-10-0-44-106.us-west-2.compute.internal   Ready    <none>   13m   v1.28.2-eks-f8587cb
ip-10-0-32-199.us-west-2.compute.internal           Ready    <none>   29s   v1.28.2-eks-a5df82a # <== EC2 created by Karpenter
```
