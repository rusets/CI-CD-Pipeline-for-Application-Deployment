############################################
# KMS key — SNS topic encryption
############################################
resource "aws_kms_key" "sns" {
  description         = "KMS key for SNS alerts (${var.project_name}-${var.environment})"
  enable_key_rotation = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sns-kms"
  })
}

############################################
# SNS Topic — CloudWatch alarms (encrypted with CMK)
############################################
resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-${var.environment}-alerts"
  kms_master_key_id = aws_kms_key.sns.arn
  tags              = local.common_tags
}

############################################
# SNS Subscription — email (optional)
############################################
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = trimspace(var.alert_email)
}
