terraform {
  required_version = ">= 1.10.0"  # 1.10+ required for S3 native locking (use_lockfile=true)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Use partial backend config: terraform init -backend-config=backend.hcl
  # State keys are per-environment: dev/terraform.tfstate, stage/terraform.tfstate, prod/terraform.tfstate
  backend "s3" {}
}
