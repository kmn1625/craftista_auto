# workers.tf

resource "aws_instance" "worker" {
  count                       = 3
  ami                         = var.ubuntu_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  key_name                    = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  user_data                   = file("cloud-init/worker.yaml")

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}
