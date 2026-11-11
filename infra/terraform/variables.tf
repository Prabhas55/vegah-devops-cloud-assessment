variable "dr_region" {
  description = "AWS region for secondary DR infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

variable "dr_availability_zone" {
  description = "DR availability zone"
  type        = string
  default     = "ap-southeast-1a"
}

variable "vpc_cidr" {
  description = "DR VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "DR public subnet CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "ami_id" {
  description = "Ubuntu AMI ID in Singapore"
  type        = string
  default     = "ami-063d94c44d4eba6e0"
}

variable "instance_type" {
  description = "DR EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Encrypted root EBS volume size"
  type        = number
  default     = 30
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "VEGAH"
}
