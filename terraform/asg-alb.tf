# Launch Template
resource "aws_launch_template" "example" {
  name          = "example-launch-template"
  image_id      = "ami-12345678" # Replace with your AMI ID
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = "subnet-12345678" # Replace with your subnet ID
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "example-instance"
    }
  }
}
# Target Group
resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-12345678" # Replace with your VPC ID
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Application Load Balancer
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-12345678"] # Replace with your security group ID
  subnets            = ["subnet-12345678", "subnet-87654321"] # Replace with your subnet IDs
  enable_deletion_protection = false
}
# Listener for ALB
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  vpc_zone_identifier = ["subnet-12345678", "subnet-87654321"] # Replace with your subnet IDs
  target_group_arns = [aws_lb_target_group.example.arn]
  tag {
    key                 = "Name"
    value               = "example-asg-instance"
    propagate_at_launch = true
  }
}