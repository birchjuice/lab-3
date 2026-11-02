terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    tls = {
      source = "hashicorp/tls"
    }

    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Find the latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate SSH key locally
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload public key to AWS
resource "aws_key_pair" "ssh" {
  key_name   = "alroma-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Save private key locally
resource "local_sensitive_file" "ssh_private_key" {
  filename        = "${path.module}/alroma-key.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0400"
}

# Create security group
resource "aws_security_group" "web" {
  name        = "alroma-web"
  description = "Security group for web servers"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create web server
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name = aws_key_pair.ssh.key_name

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    Name = "web"
  }
}

# Output public IP address
output "public_ip" {
  value = aws_instance.web.public_ip
}
