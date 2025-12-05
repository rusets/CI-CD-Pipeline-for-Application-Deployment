# **Runbook — Rollback**

## **Purpose**
• Restore system functionality after a failed deployment

## **Triggers**
• API stops responding  
• Lambda functions fail or timeout  
• UI shows incorrect or frozen state  
• EC2 does not start or stops unexpectedly

## **Checks**
• Last GitHub Actions deployment logs  
• Terraform state in S3 and DynamoDB lock table  
• `terraform output` values  
• CloudWatch Logs for all wake/status/reaper Lambdas

## **Rollback Steps**
• Re-apply previous commit:  
  `terraform apply` on the last known good revision  
• Unlock Terraform state if stuck in DynamoDB  
• Rebuild only wake module:  
  – `cd infra-wake`  
  – `terraform destroy`  
  – `terraform apply`  
• Verify new `INSTANCE_ID` and update Lambda env vars

## **Escalation**
• Full environment rebuild:  
  – `terraform destroy` in `infra`  
  – `terraform apply`  
  – redeploy `infra-wake`  