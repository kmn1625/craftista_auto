provider "aws" {
  region = "us-east-1"
}

# Generate SSH Key Pair Locally
resource "tls_private_key" "k8s" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Key Pair in AWS
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = tls_private_key.k8s.public_key_openssh

  lifecycle {
    prevent_destroy = false
  }
}

# Save Private Key Locally for GitHub Artifact
resource "local_file" "private_key" {
  content  = tls_private_key.k8s.private_key_pem
  filename = "${path.module}/k8s-key.pem"
}

# Security Group
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Allow SSH and K8s ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
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

# Master Node
resource "aws_instance" "master" {
  ami           = "ami-08e5424edfe926b43"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-master"
  }

  user_data = file("${path.module}/install_docker.sh")
}

# Worker Nodes
resource "aws_instance" "workers" {
  count         = 2
  ami           = "ami-08e5424edfe926b43"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }

  user_data = file("${path.module}/install_docker.sh")
}

output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = [for w in aws_instance.workers : w.public_ip]
}

output "private_key" {
  value     = tls_private_key.k8s.private_key_pem
  sensitive = true
}
