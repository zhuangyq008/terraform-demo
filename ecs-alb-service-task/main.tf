module "ecs-alb-service-task_example_complete" {
  source  = "cloudposse/ecs-alb-service-task/aws//examples/complete"
  version = "0.66.4"
  # insert the 23 required variables here
}
#https://registry.terraform.io/modules/cloudposse/ecs-alb-service-task/aws/latest/examples/complete?tab=inputs
#https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
variable "task_cpu" {
  default = 256
}
variable "task_memory" {
  default = 1024
}
#Description: Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION
variable "propagate_tags" {
  default = "SERVICE"
}
variable "container_environment" {
  default = [
    {

    }
  ]
}
#Valid values are `CODE_DEPLOY` and `ECS`
variable "deployment_controller_type" {
  default = "ECS"
}
variable "assign_public_ip" {
  default = true
}
variable "ignore_changes_task_definition" {
  default = false
}
variable "deployment_minimum_healthy_percent" {
    default = 50
  
}
variable "desired_count" {
  default = 2
}
variable "container_readonly_root_filesystem" {
  default = true
}
variable "container_essential" {
  default = true
}
variable "container_image" {
  default = "nginx"
}
variable "container_memory" {
  default = 512
}
variable "network_mode" {
  default = "FARGATE"
}