provider "aws" {
  region     = "us-east-1"
}
data "aws_ecs_cluster" "mycluster" {
  cluster_name = var.cluster_name
}

resource "aws_ecs_task_definition" "service" {
  family = "my-service"
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "public.ecr.aws/nginx/nginx:1.23"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

}
resource "aws_ecs_service" "my_svc" {
  name            = "my_svc"
  cluster = data.aws_ecs_cluster.mycluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 2
#   iam_role        = aws_iam_role.foo.arn
#   depends_on      = [aws_iam_role_policy.foo]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  
}


