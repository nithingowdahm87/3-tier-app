## Description
<!-- Briefly describe what this PR does and why -->

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature / module (non-breaking change that adds functionality)
- [ ] Breaking change (changes that would cause existing infra to be replaced/destroyed)
- [ ] Documentation update
- [ ] CI/CD improvement
- [ ] Dependency bump (Dependabot)

## Pre-Merge Checklist

### Code Quality
- [ ] `terraform fmt -recursive` run and output is clean
- [ ] `terraform validate` passes locally (or in CI)
- [ ] TFLint passes (`tflint --recursive`)
- [ ] No hardcoded account IDs, ARNs, or secret values
- [ ] All new variables have `description`, `type`, and `validation` blocks
- [ ] All new outputs have `description` (and `sensitive = true` if they expose secrets)

### Security
- [ ] Checkov / tfsec scan passes (CI enforces this automatically)
- [ ] Trivy IaC scan passes (CI enforces this automatically)
- [ ] No new IAM `*` actions or `Resource: "*"` without justification
- [ ] No new public-facing resources without WAF/SG restriction
- [ ] No secrets or credentials committed (check `.gitignore` covers all secret files)

### Infrastructure Impact
- [ ] `terraform plan` output reviewed and attached/linked below
- [ ] Any resource **replacements** (`-/+`) are intentional and documented
- [ ] `terraform.tfvars.example` updated if new variables were added
- [ ] `environments/dev/terraform.tfvars.example` updated if applicable
- [ ] `environments/stage/terraform.tfvars.example` updated if applicable
- [ ] `environments/prod/terraform.tfvars.example` updated if applicable

### Documentation
- [ ] `README.md` updated if architecture, bootstrap steps, or variables changed
- [ ] Module `variables.tf` and `outputs.tf` comments updated
- [ ] `docs/` updated if applicable

## Terraform Plan Summary
<!-- Paste the plan summary or link to the CI plan artifact -->
<details>
<summary>Plan output</summary>

```hcl
# Paste terraform plan output here
```

</details>

## Additional Notes
<!-- Any context, trade-offs, follow-up tasks, or links to issues -->
