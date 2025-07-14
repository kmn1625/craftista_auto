# masters.tf

resource "aws_instance" "master" {
  count                       = 2
  ami                         = var.ubuntu_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  key_name                    = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  user_data                   = file("cloud-init/master.yaml")

  tags = {
    Name = "k8s-master-${count.index + 1}"
    Role = "master"
  }
}
