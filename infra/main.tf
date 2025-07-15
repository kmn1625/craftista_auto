terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }

  required_version = ">= 1.3"
}

provider "aws" {
  region = var.aws_region
}

# Step 2: Delete existing key pair (if it exists) to avoid Duplicate error
resource "null_resource" "delete_old_key" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 delete-key-pair --key-name "k8s-auto-key" || true
    EOT
  }

  # Ensures it always runs
  triggers = {
    always_run = timestamp()
  }
}
