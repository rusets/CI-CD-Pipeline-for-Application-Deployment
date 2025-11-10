############################################
# IAM — Trust policy (EC2 assumes role)
############################################
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

############################################
# IAM — Role for CloudWatch Agent on EC2
############################################
resource "aws_iam_role" "cw_agent_role" {
  name               = "${var.project_name}-${var.environment}-cw-agent-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

############################################
# IAM — Attach AWS managed policies
# - CloudWatchAgentServerPolicy: logs + metrics
# - AmazonSSMManagedInstanceCore: SSM Session Manager
############################################
resource "aws_iam_role_policy_attachment" "attach_cwagent_managed" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "attach_ssm_core" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

############################################
# IAM — Instance profile for EC2
############################################
resource "aws_iam_instance_profile" "cw_agent_profile" {
  name = "${var.project_name}-${var.environment}-cw-agent-profile"
  role = aws_iam_role.cw_agent_role.name
}
