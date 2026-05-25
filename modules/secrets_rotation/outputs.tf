output "aurora_rotation_lambda_arn" {
  value = length(aws_lambda_function.aurora_rotation) > 0 ? aws_lambda_function.aurora_rotation[0].arn : ""
}
output "redis_rotation_lambda_arn" {
  value = length(aws_lambda_function.redis_rotation) > 0 ? aws_lambda_function.redis_rotation[0].arn : ""
}
