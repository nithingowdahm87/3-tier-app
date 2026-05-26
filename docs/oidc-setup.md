# GitHub Actions OIDC Setup Guide

This repo uses **keyless OIDC authentication** instead of static AWS access keys.
No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` secrets are stored in GitHub.

---

## How it works

1. GitHub generates a short-lived OIDC token per workflow run
2. AWS STS exchanges that token for temporary credentials via `AssumeRoleWithWebIdentity`
3. The IAM role has a trust policy that only allows tokens from this specific repo
4. Credentials expire automatically after the job finishes

---

## One-time AWS Setup

### Step 1 — Create the GitHub OIDC Identity Provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

> If the provider already exists you will get an `EntityAlreadyExists` error — that is fine, skip this step.

---

### Step 2 — Create the IAM Role

Save the file below as `trust-policy.json`, replacing `ACCOUNT_ID`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:nithingowdahm87/3-tier-app:*"
        },
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

```bash
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document file://trust-policy.json
```

---

### Step 3 — Attach Permissions to the Role

For Terraform to plan and apply, the role needs sufficient permissions.
As a starting point (scope down further for production):

```bash
aws iam attach-role-policy \
  --role-name github-actions-terraform \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Also allow IAM operations Terraform needs:
aws iam attach-role-policy \
  --role-name github-actions-terraform \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

> **Security tip:** For production, create a custom least-privilege policy covering only
> the AWS services your Terraform modules actually manage.

---

### Step 4 — Add the Role ARN to GitHub Secrets

Go to: **Repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value |
|---|---|
| `AWS_OIDC_ROLE_ARN` | `arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform` |
| `TF_BACKEND_BUCKET` | Your S3 state bucket name |

> Remove `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` if they exist — they are no longer needed.

---

### Step 5 — Verify

Push any change to `main` and watch the Actions tab.
The **Configure AWS credentials (OIDC)** step should show:
```
Assumed role arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform
```

---

## Branch → Environment → AWS Account mapping

| Branch | Environment | State key | IAM Role session |
|---|---|---|---|
| `feature/*` / `develop` | dev | `dev/terraform.tfstate` | `terraform-plan-*` |
| `stage` | stage | `stage/terraform.tfstate` | `terraform-apply-stage-*` |
| `main` | prod | `prod/terraform.tfstate` | `terraform-apply-prod-*` |

For full environment isolation, create **one IAM role per environment** and store:
- `AWS_OIDC_ROLE_ARN_DEV`
- `AWS_OIDC_ROLE_ARN_STAGE`
- `AWS_OIDC_ROLE_ARN_PROD`

Then update the workflow `role-to-assume` per job to reference the correct secret.

---

## Module Versioning Quick Reference

After any `modules/` change merged to `main`, the `module-release.yml` workflow
auto-creates a semver Git tag. Use these tags to pin module versions:

```hcl
# Pin to an exact release (recommended for prod)
module "network" {
  source = "git::https://github.com/nithingowdahm87/3-tier-app//modules/network?ref=v1.2.0"
}

# Float to latest patch within a minor (for dev/stage)
module "alb" {
  source = "git::https://github.com/nithingowdahm87/3-tier-app//modules/alb?ref=v1.3.1"
}
```

### Bump strategy via commit message keywords:

| Keyword in commit | Version bump | Example |
|---|---|---|
| `[major]` | Major | `v1.2.3` → `v2.0.0` |
| `[minor]` | Minor | `v1.2.3` → `v1.3.0` |
| *(default)* | Patch | `v1.2.3` → `v1.2.4` |
