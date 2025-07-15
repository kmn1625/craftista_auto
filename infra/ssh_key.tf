# Generate new SSH key pair locally
resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS EC2 key pair (depends on deletion of old key)
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-auto-key"
  public_key = tls_private_key.k8s_key.public_key_openssh

  depends_on = [null_resource.delete_old_key] # <- from main.tf

  lifecycle {
    create_before_destroy = true
  }
}

# Save the private key locally for SSH access
resource "local_file" "private_key" {
  content         = tls_private_key.k8s_key.private_key_pem
  filename        = "k8s-auto-key.pem"
  file_permission = "0600"
}
