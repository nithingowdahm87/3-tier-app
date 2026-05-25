terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Use partial backend config: terraform init -backend-config=backend.hcl
  backend "s3" {
    key     = "3tier-app/terraform.tfstate"
    encrypt = true
  }
}
