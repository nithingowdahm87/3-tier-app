# ─── AWS Organisations SCP Deployment ────────────────────────────────────────
# Requires AWS Organizations master account credentials.
# Apply with: terraform init && terraform apply
# Then attach policies to OUs via aws_organizations_policy_attachment.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

resource "aws_organizations_policy" "security_services" {
  name        = "DenyDisableSecurityServices"
  description = "Prevents disabling CloudTrail, GuardDuty, Config, and Security Hub"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/scp_security_services.json")
}

resource "aws_organizations_policy" "s3_public_access" {
  name        = "DenyS3PublicAccess"
  description = "Prevents disabling S3 Block Public Access at account or bucket level"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/scp_s3_public_access.json")
}

resource "aws_organizations_policy" "region_restriction" {
  name        = "RestrictToApprovedRegions"
  description = "Denies API calls to non-approved AWS regions"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/scp_region_restriction.json")
}

resource "aws_organizations_policy" "protect_state" {
  name        = "ProtectTerraformState"
  description = "Prevents deletion or modification of Terraform state S3 bucket and DynamoDB lock table"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/scp_protect_state.json")
}

# ─── Attach SCPs to a target OU ──────────────────────────────────────────────
# Uncomment and set your OU ID before applying.
# resource "aws_organizations_policy_attachment" "security_services" {
#   policy_id = aws_organizations_policy.security_services.id
#   target_id = "ou-xxxx-yyyyyyy"  # Replace with your Workloads OU ID
# }
# resource "aws_organizations_policy_attachment" "s3_public_access" {
#   policy_id = aws_organizations_policy.s3_public_access.id
#   target_id = "ou-xxxx-yyyyyyy"
# }
# resource "aws_organizations_policy_attachment" "region_restriction" {
#   policy_id = aws_organizations_policy.region_restriction.id
#   target_id = "ou-xxxx-yyyyyyy"
# }
# resource "aws_organizations_policy_attachment" "protect_state" {
#   policy_id = aws_organizations_policy.protect_state.id
#   target_id = "ou-xxxx-yyyyyyy"
# }
