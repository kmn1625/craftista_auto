resource "tls_private_key" "k8s_keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = tls_private_key.k8s_keygen.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "${path.module}/k8s.pem"
  content  = tls_private_key.k8s_keygen.private_key_pem
}
