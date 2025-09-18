# iam.tf
resource "aws_iam_role" "cw_agent_role" {
  name               = "${var.project_name}-${var.environment}-cw-agent-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cw_agent_policy" {
  name = "${var.project_name}-${var.environment}-cw-agent"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup", "logs:CreateLogStream",
        "logs:PutLogEvents", "logs:DescribeLogStreams"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = aws_iam_policy.cw_agent_policy.arn
}

resource "aws_iam_instance_profile" "cw_agent_profile" {
  name = "${var.project_name}-${var.environment}-cw-agent-profile"
  role = aws_iam_role.cw_agent_role.name
}
