provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "${path.module}/k8s-key.pem"
  content  = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Allow SSH and Kubernetes traffic"
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

resource "aws_instance" "master" {
  ami           = "ami-0c02fb55956c7d316" # Ubuntu 22.04 in us-east-1
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data = file("${path.module}/install_docker.sh")
  tags = { Name = "k8s-master" }
}

resource "aws_instance" "workers" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  user_data = file("${path.module}/install_docker.sh")
  tags = { Name = "k8s-worker-${count.index + 1}" }
}

output "instance_ips" {
  value = [
    aws_instance.master.public_ip,
    aws_instance.workers[0].public_ip,
    aws_instance.workers[1].public_ip
  ]
}

resource "local_file" "instance_ips" {
  filename = "${path.module}/instance_ips.txt"
  content  = join("\n", [
    aws_instance.master.public_ip,
    aws_instance.workers[0].public_ip,
    aws_instance.workers[1].public_ip
  ])
}
