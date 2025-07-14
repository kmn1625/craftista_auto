# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of EC2 instance to use"
  type        = string
  default     = "t3.medium"
}

variable "ubuntu_ami" {
  description = "Ubuntu AMI ID for the region"
  type        = string
  default     = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS for us-east-1
}
