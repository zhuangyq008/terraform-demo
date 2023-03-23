output "redis_endpoint" {
  value = aws_elasticache_cluster.devax-demo.cluster_address
}