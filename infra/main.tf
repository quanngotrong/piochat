provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
}

module "acm_dns_validation" {
  source      = "./modules/acm_dns_validation"
  domain_name = var.domain_name
}

output "acm_certificate_arn" {
  value = module.acm_dns_validation.acm_certificate_arn
}

module "vpc" {
  source = "./modules/vpc"
}

# Create an IAM role for EC2 to access other AWS services (e.g., S3, CloudWatch)
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "EC2-S3-Access-Policy"
  description = "Policy to allow EC2 instances to access S3 buckets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",  # Replace with your bucket name
          "arn:aws:s3:::${var.bucket_name}/*" # Access to objects in the bucket
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch Template for EC2 instances
resource "aws_launch_template" "app_launch_template_be" {
  name_prefix   = "app-launch-template-be"
  image_id      = "ami-0995922d49dc9a17d" # Example AMI ID, replace with your desired one
  instance_type = "t3.micro"
  user_data     = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y aws-cli
                EOF

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg_be" {
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = module.vpc.subnet_ids # Replace with your subnets

  launch_template {
    id      = aws_launch_template.app_launch_template_be.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG Instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true
}

# Security Group for ALB
resource "aws_security_group" "alb_sg_be" {
  name        = "alb-security-group-be"
  description = "Allow HTTP and HTTPS traffic for ALB"
  vpc_id      = module.vpc.vpc_id # Replace with your VPC ID

  # Allow HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Application Load Balancer (ALB)
resource "aws_lb" "alb_be" {
  name               = "my-alb-be"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg_be.id] # Replace with your security group ID
  subnets            = module.vpc.subnet_ids             # Replace with your subnets
}

# Create ALB Listener for HTTP
resource "aws_lb_listener" "http_listener_be" {
  load_balancer_arn = aws_lb.alb_be.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_be.arn
  }
}

# Create ALB Listener for HTTPS (with SSL)
resource "aws_lb_listener" "https_listener_be" {
  load_balancer_arn = aws_lb.alb_be.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # Example SSL policy
  certificate_arn   = module.acm_dns_validation.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_be.arn
  }
}

# Create ALB Target Group
resource "aws_lb_target_group" "alb_target_group_be" {
  name     = "my-alb-target-group-be"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id # Replace with your VPC ID

  health_check {
    path                = "/health"
    port                = "5000"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach Auto Scaling Group to the Target Group
resource "aws_autoscaling_attachment" "asg_attachment_be" {
  autoscaling_group_name = aws_autoscaling_group.asg_be.name
  lb_target_group_arn    = aws_lb_target_group.alb_target_group_be.arn
}

# Create Route 53 DNS Record pointing to ALB
resource "aws_route53_record" "alb_record" {
  zone_id = "Z0004565205363BK2R36U"  # Replace with your Route 53 Hosted Zone ID
  name    = "app.${var.domain_name}" # Replace with your subdomain
  type    = "A"
  alias {
    name                   = aws_lb.alb_be.dns_name
    zone_id                = aws_lb.alb_be.zone_id
    evaluate_target_health = true
  }
}
