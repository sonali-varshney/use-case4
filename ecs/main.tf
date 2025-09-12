resource "aws_ecs_cluster" "mycluster" {
  name = "testcluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Create an IAM role for your ECS tasks that grants permissions to write logs to CloudWatch. This role will be associated with your ECS task definition.
resource "aws_iam_role" "ecs_task_execution_role" {
    name = "${var.service_name}-ecs-task-execution-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
    role       = aws_iam_role.ecs_task_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_policy" "ecs_cloudwatch_logs_policy" {
    name        = "${var.service_name}-ecs-cloudwatch-logs-policy"
    description = "Allows ECS tasks to write logs to CloudWatch"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = aws_cloudwatch_log_group.ecs_logs.arn
      }]
    })
  }

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_logs_policy_attachment" {
   role       = aws_iam_role.ecs_task_execution_role.name
   policy_arn = aws_iam_policy.ecs_cloudwatch_logs_policy.arn
      }


resource "aws_ecs_task_definition" "service" {
  family = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "10"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  
  #specify the logConfiguration for your containers, linking them to the CloudWatch log group created earlier.
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "nginx"
                logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
              "awslogs-region"        = var.aws_region
              "awslogs-stream-prefix" = "ecs"
            }
          }
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
    {
      name      = "apachecontainer"
      image     = "apache"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]
    }
  ])

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}



resource "aws_ecs_service" "myservice" {
  name            = "testservice"
  cluster         = aws_ecs_cluster.mycluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
#  iam_role        = aws_iam_role.foo.arn #
#  depends_on      = [aws_iam_role_policy.foo]
   launch_type     = "FARGATE"
   network_configuration {
       # subnets          = [aws_subnet.private.id]
        security_groups  = [aws_security_group.app_sg.id]
        assign_public_ip = true # Or false if using a load balancer in a public subnet
      }

  #load_balancer {
  #  target_group_arn = aws_lb_target_group.foo.arn
 #   container_name   = "mongo"
#    container_port   = 8080
#  }
}