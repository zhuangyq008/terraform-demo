output "go_app_alb_endpoint" {
  value = "http://${aws_lb.devax.dns_name}:${aws_lb_listener.devax.port}/version"
}

output "target_health_url" {
  value = "${aws_lb_target_group.devax.protocol}"
}