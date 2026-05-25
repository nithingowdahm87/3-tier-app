# Bootstrap Runbook

This runbook covers the **one-time setup** required before running a full `terraform apply`. Follow every step in order. Steps marked **[one-time]** only need to be done on the very first deploy.

---

## Prerequisites

- AWS CLI configured with admin credentials for the target account
- Terraform >= 1.5.0 installed
- A Route53 hosted zone for your domain
- `jq` and `openssl` installed locally

---

## Step 1: Bootstrap the Terraform State Backend [one-time]

The S3 bucket and DynamoDB lock table must exist before Terraform can store state.

```bash
cd bootstrap-state/
terraform init
terraform apply
cd ..
```

Note the output bucket name and table name. Copy `backend.hcl.example` to `backend.hcl` and fill in those values:

```bash
cp backend.hcl.example backend.hcl
# Edit backend.hcl — fill in bucket and dynamodb_table
```

> **backend.hcl is gitignored.** Never commit it with real values.

---

## Step 2: Bootstrap the CloudFront ACM Certificate [one-time]

CloudFront requires an ACM certificate in **us-east-1** regardless of your primary region.

```bash
DOMAIN="app.example.com"

CERT_ARN=$(aws acm request-certificate \
  --domain-name "static.${DOMAIN}" \
  --subject-alternative-names "${DOMAIN}" "www.${DOMAIN}" \
  --validation-method DNS \
  --region us-east-1 \
  --query CertificateArn --output text)

echo "Certificate ARN: ${CERT_ARN}"
```

Complete DNS validation in Route53 (AWS Console → Certificate Manager → your cert → Create records in Route53), then wait for status `ISSUED`:

```bash
aws acm wait certificate-validated --certificate-arn "${CERT_ARN}" --region us-east-1
echo "Certificate validated!"
```

Set this ARN in your `terraform.tfvars`:

```hcl
cloudfront_acm_certificate_arn = "<CERT_ARN>"
```

---

## Step 3: Seed Aurora Password into Secrets Manager [one-time]

The Aurora secret shell is created first, then seeded manually.

```bash
ENV="prod"  # or staging / dev

# Phase 1: create the secret shell
terraform init -backend-config=backend.hcl
terraform apply -target=module.aurora_secret

# Phase 2: seed the password
AURORA_PASSWORD=$(openssl rand -base64 32)
aws secretsmanager put-secret-value \
  --secret-id "/${ENV}/aurora/master_password" \
  --secret-string "{\"password\": \"${AURORA_PASSWORD}\"}"

echo "Aurora password seeded. Store this securely in your password manager:"
echo "${AURORA_PASSWORD}"
```

---

## Step 4: Seed Redis AUTH Token into Secrets Manager [one-time]

```bash
ENV="prod"  # or staging / dev

# Phase 1: create the secret shell
terraform apply -target=module.redis_secret

# Phase 2: seed the token
REDIS_TOKEN=$(openssl rand -base64 32)
aws secretsmanager put-secret-value \
  --secret-id "/${ENV}/redis/auth_token" \
  --secret-string "{\"token\": \"${REDIS_TOKEN}\"}"

echo "Redis AUTH token seeded."
```

---

## Step 5: Bootstrap NLBs (resolve cert circular dependency) [one-time]

The ACM certificates in `dns_cert` modules reference NLB DNS names for Route53 alias records. On a fresh account, NLBs don't exist yet, so apply them first:

```bash
terraform apply \
  -target=module.nlb_primary \
  -target=module.nlb_secondary
```

Wait for both NLBs to be active (~2 minutes), then run the full apply.

---

## Step 6: Full Apply

```bash
terraform apply
```

Expect ~15–20 minutes for Aurora Global cluster provisioning.

---

## Step 7: Verify

```bash
# Check outputs
terraform output

# Confirm Aurora cluster is available
aws rds describe-global-clusters --query 'GlobalClusters[*].{ID:GlobalClusterIdentifier,Status:Status}'

# Confirm Global Accelerator is provisioned
aws globalaccelerator list-accelerators --query 'Accelerators[*].{Name:Name,Status:Status,DNS:DnsName}'

# Test WAF on both regions via ALB
curl -I https://app.example.com/health
```

---

## Accessing Instances (SSM Session Manager — no bastion needed)

```bash
# List running instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=myapp" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Role:Tags[?Key==`role`]|[0].Value}' \
  --output table

# Start a session (no SSH key, no open ports required)
aws ssm start-session --target <instance-id>

# Port forward to Aurora (from local machine)
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<aurora-endpoint>"],"portNumber":["3306"],"localPortNumber":["3306"]}'
```

---

## Secret Rotation Schedule

| Secret | Rotation | Method |
|--------|----------|--------|
| Aurora master password | Every 90 days | `aws secretsmanager rotate-secret` + Lambda |
| Redis AUTH token | Every 90 days | Manual re-seed + rolling ElastiCache update |
| IAM access keys (CI/CD) | Every 90 days | AWS IAM key rotation |

---

## Rollback Procedure

```bash
# Restore previous state version from S3 versioning
aws s3api list-object-versions \
  --bucket <state-bucket> \
  --prefix 3tier-app/terraform.tfstate

# Restore a specific version
aws s3api get-object \
  --bucket <state-bucket> \
  --key 3tier-app/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.backup
```
