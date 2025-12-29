# 1. Application Load Balancer (ALB)
# checkov:skip=CKV2_AWS_20: "To use HTTPS/TLS, I need a custom domain, but not being utilised in this lab"
# checkov:skip=CKV2_AWS_103: "To use HTTPS/TLS, I need a custom domain, but not being utilised in this lab"

resource "aws_lb" "load_balancer" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# The Target Group (where the traffic goes)
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Requried for Fargate

  health_check {
    path                = "/api/results" # my flask web-app's health endpoint
    healthy_threshold   = 2              # number of consecutive health check successes required before considered healthy
    unhealthy_threshold = 10             # number of consective health check failures required before considering a target unhealthy
    # this us to prevent boot loops (where the app tries to start, gets killed for being too slow, tries again and gets killed again)
    # by setting to 10, I'm giving the container ample time to finish the startup logic and become stable before the ALB gives up on it
    # HOWEVER, in high-frequency environments you want to fail fast and would set it low
  }
}

# The Listener (listens on port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# In real prod environments, HTTPS on the ALB must have an SSL/TLS certificate, and although ACM gives free certaficates, it requires a custom domain that costs to purchase and setup in route 53 DNS records, additionally the port would be 443 and protocol HTTPS, and a second listener on port 80 to redirect traffic to port 443.


# 2. ECS Cluster

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"
}

# 3. Task Definition
resource "aws_ecs_task_definition" "app_task_def" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256                                 # 0.25 vCPU
  memory                   = 512                                 # 0.5 GB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn # ARN of the IAM task executation role that the ECS container agent and docker daemon assumes
  task_role_arn            = aws_iam_role.ecs_task_role.arn      # ARN of IAM role that allows my ECS container task to make calls to other AWS services

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ],

      # Env variables (sensitive data hidden)
      environment = [
        { name = "DB_HOST", value = var.db_endpoint },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username }
      ],


      # Secrets (injected from secrets manager)
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = var.db_secret_arn
        }
      ],


      # CloudWatch Logs configuration for Observability and Debugging
      logConfiguration = {
        logDriver = "awslogs" # Connects container outputs directly to AWS CloudWatch
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}" # creates a folder in CloudWatch to organise logs for this project
          "awslogs-stream-prefix" = "ecs"                      # adds a prefix to the specific log file so I can tell which container instance generated which log
          "awslogs-region"        = "us-east-1"                # defines the region the logs are coming from
          "awslogs-create-group"  = "true"                     # convenient feature (if log folder doesnt exist, create it for me)
        }
      }
    }
  ])
}

# 4. ECS Service (The Manager)
resource "aws_ecs_service" "name" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task_def.arn
  desired_count   = 2 # Run 2 copies (instances)

  # Network Configuration
  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true # Required because I'm in public subnets, providing the containers with public IPs
  }

  # Load Balancer Configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "web"
    container_port   = 5000
  }

  # Capacity Provider (Using spot instances), telling ECS ex 
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

}