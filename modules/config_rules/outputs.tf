output "recorder_name"  { value = aws_config_configuration_recorder.this.name }
output "recorder_id"    { value = aws_config_configuration_recorder.this.id }
output "config_bucket"  { value = aws_s3_bucket.config.bucket }
