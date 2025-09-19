# -----------------------------------------------------------------------------
# Useful outputs for reference after terraform apply
# -----------------------------------------------------------------------------

# Public IP address of the EC2 instance (web server)
output "instance_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of the web server"
}

# Public DNS name of the EC2 instance
output "instance_public_dns" {
  value       = aws_instance.app.public_dns
  description = "Public DNS of the web server"
}

# Security Group ID assigned to the instance
output "security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "Security Group ID"
}