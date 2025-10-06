# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "epl_instance" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EPL Live EC2 instance"
  vpc_id      = aws_default_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP (for potential web interface)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (for potential web interface)
  ingress {
    description = "HTTPS"
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

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Use default VPC (free tier)
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# IAM Role for EC2 (if CloudWatch logs enabled)
resource "aws_iam_role" "ec2_role" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  count      = var.enable_cloudwatch_logs ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.project_name}-ec2-profile"
  role  = aws_iam_role.ec2_role[0].name
}

# EC2 Instance
resource "aws_instance" "epl_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.epl_instance.id]
  iam_instance_profile   = var.enable_cloudwatch_logs ? aws_iam_instance_profile.ec2_profile[0].name : null

  user_data = templatefile("${path.module}/user-data.sh", {
    football_api_key  = var.football_api_key
    convex_url        = var.convex_url
    convex_deploy_key = var.convex_deploy_key
    enable_mock_data  = var.enable_mock_data
    project_name      = var.project_name
  })

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30 # GB (free tier: 30GB, required for Amazon Linux 2023 AMI)
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  # Enable detailed monitoring (costs extra)
  monitoring = false

  tags = {
    Name = "${var.project_name}-server"
  }

  # Ensure instance is recreated if user data changes
  user_data_replace_on_change = true
}

# Elastic IP (optional - costs $0.005/hour when instance is stopped)
resource "aws_eip" "epl_server" {
  instance = aws_instance.epl_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}
