# outputs.tf

output "master_ips" {
  description = "Public IPs of Kubernetes master nodes"
  value       = aws_instance.master[*].public_ip
}

output "worker_ips" {
  description = "Public IPs of Kubernetes worker nodes"
  value       = aws_instance.worker[*].public_ip
}
