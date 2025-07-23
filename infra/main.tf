provider "aws" {
  region = us-east-1
}

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.k8s_key.private_key_pem
  filename = "${path.module}/k8s-key.pem"
}

# Random suffix for uniqueness
resource "random_pet" "suffix" {}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key-${random_pet.suffix.id}"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg-${random_pet.suffix.id}"
  description = "Security group for Kubernetes cluster"
  vpc_id      = data.aws_vpc.default.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "master" {
  ami                         = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/install_docker.sh")

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "workers" {
  count                       = 2
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/install_docker.sh")

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

# Output Public IPs
output "instance_ips" {
  value = [
    aws_instance.master.public_ip,
    aws_instance.workers[0].public_ip,
    aws_instance.workers[1].public_ip
  ]
}

# Output SSH Key
output "private_key" {
  value     = tls_private_key.k8s_key.private_key_pem
  sensitive = true
}
