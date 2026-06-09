terraform {
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
  backend "s3" {}
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Required for CloudFront ACM certificates and Global resources
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
