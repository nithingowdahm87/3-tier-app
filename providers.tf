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
