provider "aws" {
  region = "ap-south-1"
}

# --------------------------
# SSH Key Pair (Dynamic)
# --------------------------
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# --------------------------
# Ubuntu AMI
# --------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --------------------------
# Instances: 1 Master, 2 Workers
# --------------------------
resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "workers" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name

  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

# --------------------------
# Outputs
# --------------------------
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker1_ip" {
  value = aws_instance.workers[0].public_ip
}

output "worker2_ip" {
  value = aws_instance.workers[1].public_ip
}
