provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "ap-south-1"
}

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.k8s_key.private_key_pem
  sensitive = true
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow SSH, K8s, HTTP"
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
  ingress {
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

resource "aws_instance" "master" {
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]
  tags = { Name = "k8s-master" }
}

resource "aws_instance" "workers" {
  count         = 2
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]
  tags = { Name = "k8s-worker-${count.index}" }
}

output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = aws_instance.workers[*].public_ip
}

# Provision Kubernetes
resource "null_resource" "install_k8s" {
  depends_on = [aws_instance.master, aws_instance.workers]

  provisioner "file" {
    source      = "${path.module}/kube-install.sh"
    destination = "/home/ubuntu/kube-install.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.k8s_key.private_key_pem
      host        = aws_instance.master.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/kube-install.sh",
      "sudo /home/ubuntu/kube-install.sh ${join(" ", aws_instance.workers[*].private_ip)}"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.k8s_key.private_key_pem
      host        = aws_instance.master.public_ip
    }
  }
}
