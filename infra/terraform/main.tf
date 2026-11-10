locals {
  common_tags = {
    Project     = var.project_name
    Environment = "disaster-recovery"
    ManagedBy   = "Terraform"
  }
}
