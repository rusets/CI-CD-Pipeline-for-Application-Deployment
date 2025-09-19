# IAM role for CloudWatch Agent (to allow EC2 to push logs/metrics)
resource "aws_iam_role" "cw_agent_role" {
  # Role name includes project and environment (e.g., ruslan-aws-dev-cw-agent-role)
  name = "${var.project_name}-${var.environment}-cw-agent-role"

  # Trust policy: EC2 service can assume this role
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

# Trust relationship: allow EC2 service to assume this role
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] # EC2 instances
    }
  }
}

# Custom IAM policy for CloudWatch Agent
resource "aws_iam_policy" "cw_agent_policy" {
  name = "${var.project_name}-${var.environment}-cw-agent"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      # Permissions needed by the CloudWatch Agent to write logs
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      Resource = "*"
    }]
  })
}

# Attach the CloudWatch policy to the role
resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = aws_iam_policy.cw_agent_policy.arn
}

# Instance profile to attach the IAM role to an EC2 instance
resource "aws_iam_instance_profile" "cw_agent_profile" {
  name = "${var.project_name}-${var.environment}-cw-agent-profile"
  role = aws_iam_role.cw_agent_role.name
}