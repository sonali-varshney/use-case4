    resource "aws_cloudwatch_log_group" "ecs_logs" {
      name              = "/ecs/${var.service_name}"
      retention_in_days = 1 # Adjust as needed
    }

