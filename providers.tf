terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.53"
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
  required_version = ">= 1.5.0"

  # backend "s3" {} block is intentionally removed.
  # Terragrunt generates backend_generated.tf at init time,
  # which auto-creates the S3 bucket + DynamoDB lock table.
}

provider "aws" {
  region = var.primary_region
  default_tags { tags = { ManagedBy = "terraform" } }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
  default_tags { tags = { ManagedBy = "terraform" } }
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  default_tags { tags = { ManagedBy = "terraform" } }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags { tags = { ManagedBy = "terraform" } }
}
