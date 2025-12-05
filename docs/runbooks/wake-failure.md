# **Runbook — Wake Failure**

## **Purpose**
• Identify why the EC2 instance does not start  
• Restore wake functionality quickly

## **Symptoms**
• UI shows “Status: unknown”  
• `/wake` Lambda returns errors or empty response  
• EC2 remains in `stopped` state  
• No state change after pressing “Wake up”

## **Checks**
• CloudWatch Logs for `lambda-wake`  
• IAM role permissions: `ec2:StartInstances`  
• Lambda environment variable `INSTANCE_ID`  
• API Gateway endpoint reachable  
• EC2 service limits (instance type availability)

## **Actions**
• Fix incorrect `INSTANCE_ID` if EC2 was recreated  
• Re-run `terraform apply` in `infra-wake`  
• Manually test:  
  `aws ec2 start-instances --instance-ids <id>`  
• Redeploy API Gateway stage if configuration was updated  

## **Escalation**
• Recreate entire wake module:  
  – `terraform destroy`  
  – `terraform apply`  