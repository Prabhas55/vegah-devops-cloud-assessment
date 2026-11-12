terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Region of the existing (manually created) production host.
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# Region of the Disaster Recovery site provisioned by this code.
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}
