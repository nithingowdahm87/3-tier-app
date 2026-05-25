terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    archive = { source = "hashicorp/archive" }
  }
}

data "aws_partition" "current" {}
data "aws_region"    "current" {}
data "aws_caller_identity" "current" {}

# ─── IAM Role for the rotation Lambda ────────────────────────────────────────

resource "aws_iam_role" "rotation" {
  name = "${var.name_prefix}-secrets-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rotation" {
  name = "${var.name_prefix}-secrets-rotation-policy"
  role = aws_iam_role.rotation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = var.secret_arn
      },
      {
        Sid    = "VPCNetworkInterfaces"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name_prefix}-rotation:*"
      }
    ]
  })
}

# ─── Lambda ZIP (inline Python rotation logic) ────────────────────────────────

resource "local_file" "rotation_lambda_src" {
  filename = "${path.module}/lambda/rotation.py"
  content  = <<-PYTHON
import boto3, json, logging, os
logger = logging.getLogger()
logger.setLevel(logging.INFO)

SECRETS  = boto3.client("secretsmanager")
AURORA   = boto3.client("rds-data")

def handler(event, context):
    arn   = event["SecretId"]
    token = event["ClientRequestToken"]
    step  = event["Step"]
    logger.info(f"Step={step} SecretId={arn}")

    metadata = SECRETS.describe_secret(SecretId=arn)
    if not metadata["RotationEnabled"]:
        raise ValueError(f"Secret {arn} does not have rotation enabled")
    if "VersionIdsToStages" not in metadata or token not in metadata["VersionIdsToStages"]:
        raise ValueError(f"Token {token} is not valid for secret {arn}")

    if step == "createSecret":
        _create_secret(arn, token)
    elif step == "setSecret":
        _set_secret(arn, token)
    elif step == "testSecret":
        _test_secret(arn, token)
    elif step == "finishSecret":
        _finish_secret(arn, token)
    else:
        raise ValueError(f"Unknown step: {step}")

def _create_secret(arn, token):
    import secrets, string
    try:
        SECRETS.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
        logger.info("AWSPENDING already exists, skipping createSecret")
    except SECRETS.exceptions.ResourceNotFoundException:
        current = json.loads(SECRETS.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT")["SecretString"])
        alphabet = string.ascii_letters + string.digits + "!#$%^&*()-_=+"
        new_pw = "".join(secrets.choice(alphabet) for _ in range(32))
        new_secret = {**current, "password": new_pw}
        SECRETS.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps(new_secret),
            VersionStages=["AWSPENDING"]
        )
        logger.info("Created AWSPENDING version with new password")

def _set_secret(arn, token):
    # Connect to Aurora and update the MySQL user password
    pending  = json.loads(SECRETS.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")["SecretString"])
    current  = json.loads(SECRETS.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT")["SecretString"])
    host     = pending.get("host", os.environ.get("DB_HOST", ""))
    port     = int(pending.get("port", 3306))
    database = pending.get("dbname", "")
    username = pending.get("username", pending.get("user", ""))
    new_pw   = pending["password"]
    import pymysql
    conn = pymysql.connect(host=host, port=port, user=username, password=current["password"], database=database,
                           ssl_ca="/etc/ssl/certs/ca-certificates.crt", ssl_verify_cert=True, connect_timeout=5)
    with conn.cursor() as cur:
        cur.execute("ALTER USER %s@'%%' IDENTIFIED BY %s", (username, new_pw))
    conn.commit()
    conn.close()
    logger.info("Aurora password updated successfully")

def _test_secret(arn, token):
    pending = json.loads(SECRETS.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")["SecretString"])
    host    = pending.get("host", os.environ.get("DB_HOST", ""))
    port    = int(pending.get("port", 3306))
    database = pending.get("dbname", "")
    username = pending.get("username", pending.get("user", ""))
    import pymysql
    conn = pymysql.connect(host=host, port=port, user=username, password=pending["password"], database=database,
                           ssl_ca="/etc/ssl/certs/ca-certificates.crt", ssl_verify_cert=True, connect_timeout=5)
    conn.close()
    logger.info("AWSPENDING secret validated successfully")

def _finish_secret(arn, token):
    metadata      = SECRETS.describe_secret(SecretId=arn)
    current_ver   = next(v for v, stages in metadata["VersionIdsToStages"].items() if "AWSCURRENT" in stages)
    if current_ver == token:
        logger.info("Token is already AWSCURRENT, skipping finishSecret")
        return
    SECRETS.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_ver
    )
    logger.info(f"Moved AWSCURRENT to version {token}")
PYTHON
}

data "archive_file" "rotation" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
  depends_on  = [local_file.rotation_lambda_src]
}

# ─── Lambda Function ──────────────────────────────────────────────────────────

resource "aws_lambda_function" "rotation" {
  function_name    = "${var.name_prefix}-aurora-secret-rotation"
  role             = aws_iam_role.rotation.arn
  handler          = "rotation.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.rotation.output_path
  source_code_hash = data.archive_file.rotation.output_base64sha256
  timeout          = 30
  memory_size      = 128

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      DB_HOST = var.aurora_endpoint
    }
  }

  tags = var.tags
}

# ─── Allow Secrets Manager to invoke the Lambda ───────────────────────────────

resource "aws_lambda_permission" "secrets_manager" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = var.secret_arn
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "rotation" {
  name              = "/aws/lambda/${aws_lambda_function.rotation.function_name}"
  retention_in_days = 30
  tags              = var.tags
}
