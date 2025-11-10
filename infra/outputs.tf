############################################
# Useful outputs for reference after terraform apply
############################################
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the web server"
  value       = aws_instance.app.public_dns
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.app_sg.id
}
