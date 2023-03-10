output "svc_alb" {
  value = aws_ecs_service.my_svc.id
}