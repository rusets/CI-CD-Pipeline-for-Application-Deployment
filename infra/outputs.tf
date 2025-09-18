# -----------------------------------------------------------------------------
# Useful outputs
# -----------------------------------------------------------------------------
output "instance_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of the web server"
}

output "instance_public_dns" {
  value       = aws_instance.app.public_dns
  description = "Public DNS of the web server"
}

output "security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "Security Group ID"
}