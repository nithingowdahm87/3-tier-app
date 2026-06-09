# Running This Project with Terragrunt

Terragrunt auto-creates the S3 state bucket and DynamoDB lock table — no manual AWS CLI steps needed.

## Prerequisites

```bash
# Install Terragrunt (already done if you followed setup)
wget https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Verify
terragrunt --version
terraform --version   # must be >= 1.5.0
```

## Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your real values
```

## First-Time Setup

```bash
cd ~/terraform_infra_3tier/3-tier-app

# Pull latest
git pull origin main

# Init — Terragrunt auto-creates:
#   S3 bucket:  nithin-3tier-prod-tfstate
#   DynamoDB:   nithin-3tier-prod-tfstate-lock
terragrunt init
```

You will see:
```
Remote state S3 bucket nithin-3tier-prod-tfstate does not exist or you don't have permissions to access it.
Would you like Terragrunt to create it? (y/n) y
```
Type **y** — Terragrunt creates the bucket with versioning + encryption automatically.

## Plan and Apply

```bash
terragrunt plan
terragrunt apply
```

## Override Region / Environment

```bash
# Use staging environment
TF_VAR_environment=staging TF_VAR_primary_region=ap-south-1 terragrunt init

# Use a different primary region
TF_VAR_primary_region=us-east-1 terragrunt plan
```

## State Bucket Naming Convention

| Variable | Default | Result |
|---|---|---|
| `TF_VAR_environment` | `prod` | `nithin-3tier-prod-tfstate` |
| `TF_VAR_primary_region` | `ap-south-1` | stored in `ap-south-1` |

## Destroy

```bash
terragrunt destroy
```

> **Note:** `backend.hcl` and `backend_generated.tf` are in `.gitignore` — never commit them.
