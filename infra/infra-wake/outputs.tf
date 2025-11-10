############################################
# Outputs (fill these after you wire API)
############################################
output "wake_function_name" {
  value       = aws_lambda_function.wake.function_name
  description = "Lambda name for wake"
}

output "status_function_name" {
  value       = aws_lambda_function.status.function_name
  description = "Lambda name for status"
}

output "reaper_function_name" {
  value       = aws_lambda_function.reaper.function_name
  description = "Lambda name for idle reaper"
}
