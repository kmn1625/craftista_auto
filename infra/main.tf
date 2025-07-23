provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key-${random_id.suffix.hex}"   # ✅ Unique key
  public_key = tls_private_key.k8s_key.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "${path.module}/k8s-key.pem"
  content  = tls_private_key.k8s_key.private_key_pem
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg-${random_id.suffix.hex}"  # ✅ Unique name
  description = "Kubernetes Cluster SG"
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

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "master" {
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-master-${random_id.suffix.hex}"
  }

  user_data = file("${path.module}/install_docker.sh")
}

resource "aws_instance" "workers" {
  count         = 2
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-worker-${count.index + 1}-${random_id.suffix.hex}"
  }

  user_data = file("${path.module}/install_docker.sh")
}

output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = [for instance in aws_instance.workers : instance.public_ip]
}

output "private_key" {
  value     = local_file.private_key.filename
  sensitive = true
}
