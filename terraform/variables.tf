variable "primary_region" {
  description = "AWS region of the existing primary EC2 instance"
  type        = string
  default     = "ap-south-1"
}

variable "dr_region" {
  description = "AWS region for the DR site"
  type        = string
  default     = "ap-southeast-1"
}

variable "primary_ip" {
  description = "Public (Elastic) IP of the primary host - used for security-group rules and the Route 53 health check"
  type        = string
}

variable "primary_sg_id" {
  description = "Existing Mumbai primary security group ID, reserved for future DR networking configuration"
  type        = string
  default     = ""
}

variable "repo_url" {
  description = "Git repository cloned onto the DR host"
  type        = string
  default     = "https://github.com/Prabhas55/vegah-devops-cloud-assessment.git"
}

variable "repo_branch" {
  description = "Git branch to deploy on the DR host"
  type        = string
  default     = "assessment-2-dr"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR form (e.g. 203.0.113.7/32) allowed to SSH to the DR host"
  type        = string
}

variable "ssh_public_key" {
  description = "Contents of your SSH public key (e.g. ~/.ssh/id_ed25519.pub)"
  type        = string
}

variable "instance_type" {
  description = "DR instance size (t3.small recommended; t3.micro is tight for Postgres + Redis + app)"
  type        = string
  default     = "t3.small"
}


variable "domain_name" {
  description = "Public Route 53 hosted zone (e.g. example.com). Leave empty to skip DNS failover resources"
  type        = string
  default     = ""
}

variable "record_name" {
  description = "Sub-domain for the app (app -> app.example.com)"
  type        = string
  default     = "app"
}

variable "dns_ttl" {
  description = "TTL in seconds for the failover records (lower = faster failover)"
  type        = number
  default     = 30
}


variable "primary_instance_id" {
  description = "Mumbai primary EC2 instance ID to stop before DR promotion"
  type        = string
}
