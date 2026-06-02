# TFLint configuration
# Pins the AWS ruleset plugin to a specific version to prevent silent breakage.
# Update the version intentionally — do NOT use "latest" in CI.
#
# Docs: https://github.com/terraform-linters/tflint-ruleset-aws

plugin "aws" {
  enabled = true
  version = "0.35.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Enforce Terraform core best practices
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  # Enforce snake_case for all resource/variable/output names
  format = "snake_case"
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}
