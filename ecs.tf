resource "aws_ecs_cluster" "main" {
  name = "cb-cluster"
}


resource "aws_ecs_task_definition" "app" {
  family                   = "cb-app-task"
  execution_role_arn       = "arn:aws:iam::672472203143:role/ecsTaskExecutionRole"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "672472203143.dkr.ecr.us-east-1.amazonaws.com/petclinic",
    "memory": ${var.fargate_memory},
    "name": "petclinic",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name            = "cb-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = 2
  launch_type     = "FARGATE"
  #iam_role        = "arn:aws:iam::672472203143:role/ecs"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "petclinic"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front_end]
}


