# **Runbook — Auto-Destroy Not Triggered**

## **Purpose**
• Identify why the Reaper Lambda failed to stop EC2

## **Symptoms**
• EC2 stays `running` longer than configured idle timeout  
• `/status` always returns `running`  
• Reaper logs missing or not updated  
• EventBridge shows no recent invocations

## **Checks**
• CloudWatch Logs for `lambda-reaper`  
• EventBridge rule status: `ENABLED`  
• Lambda invoke permissions for `events.amazonaws.com`  
• SSM parameter `/ci-wake/last_wake`  
• LocalStorage cooldown timer on the UI

## **Actions**
• Trigger Reaper manually using “Test” in Lambda console  
• Validate IAM policy includes `ec2:StopInstances`  
• Update the SSM parameter with a fresh timestamp  
• Re-run Terraform for the wake module: `terraform apply`

## **Escalation**
• Manual stop:  
  `aws ec2 stop-instances --instance-ids <id>`  