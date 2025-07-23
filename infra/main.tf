provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "masters" {
  count         = 2
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  subnet_id     = var.subnet_id
  tags = {
    Name = "k8s-master-${count.index}"
  }
}

resource "aws_instance" "workers" {
  count         = 3
  ami           = var.ami_id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  subnet_id     = var.subnet_id
  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

resource "null_resource" "k8s_setup" {
  depends_on = [aws_instance.masters, aws_instance.workers]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https curl kubeadm kubelet kubectl containerd",
      "sudo kubeadm init --apiserver-advertise-address=${aws_instance.masters[0].private_ip} --pod-network-cidr=10.244.0.0/16",
      "mkdir -p $HOME/.kube",
      "sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.masters[0].public_ip
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@${aws_instance.masters[0].public_ip}:/home/ubuntu/.kube/config ./kubeconfig"
  }
}

output "kubeconfig_path" {
  value = "${path.module}/kubeconfig"
}
