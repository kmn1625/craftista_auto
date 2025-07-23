output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_ips" {
  value = [for w in aws_instance.k8s_workers : w.public_ip]
}

output "private_key" {
  sensitive = true
  value     = tls_private_key.k8s_keygen.private_key_pem
}
