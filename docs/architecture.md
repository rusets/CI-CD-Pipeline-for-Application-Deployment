# **Architecture Overview**
```
ci-cd-pipeline-aws/
├── .gitignore
├── README.md                        # Main project documentation
├── LICENSE                          # MIT license

├── .github/
│   └── workflows/
│       ├── infra-wake.yml           # CI/CD for wake/status Lambdas + API Gateway
│       └── terraform.yml            # CI/CD for core Terraform infrastructure

├── app/
│   └── public/
│       ├── assets/                  # Static assets for Wake UI (images, JS, CSS)
│       └── index.html               # Wake UI — progress bar, wake button, status polling

├── wait-site/
│   └── index.html                   # Static "Wait" landing page (CloudFront/S3)

├── lambdas/
│   ├── _common/
│   │   └── timeparse.py             # Shared helpers (time calculations)
│   ├── reaper/
│   │   └── index.py                 # Reaper Lambda — auto-stop EC2 after idle
│   ├── status/
│   │   └── index.py                 # Status Lambda — returns EC2 state/IP
│   └── wake/
│       └── index.js                 # Wake Lambda — starts EC2 + updates SSM timestamp

├── build/
│   ├── reaper.zip                   # Packaged Reaper Lambda (from GitHub Actions)
│   ├── status.zip                   # Packaged Status Lambda
│   ├── wake.zip                     # Packaged Wake Lambda
│   ├── site.zip                     # Packaged static site bundle
│   └── stage/                       # Local temp dirs for archive_file (Terraform)
│       ├── reaper/
│       └── status/

├── cloudwatch/
│   └── amazon-cloudwatch-agent.json # CW Agent config — logs + CPU/Mem/Disk metrics

├── scripts/
│   ├── app.service                  # systemd unit for EC2 app autostart
│   └── deploy_on_instance.sh        # Deployment script executed on EC2 during bootstrap

├── docs/
│   ├── architecture.md              # Full system design document
│   ├── runbooks/
│   │   ├── destroy-not-triggered.md # Runbook: destroy workflow didn’t fire
│   │   ├── rollback.md              # Runbook: revert from failed deployment
│   │   └── wake-failure.md          # Runbook: wake request not working
│   └── screenshots/                 # Visual references for README + docs
│       ├── 1-wait-page.png
│       ├── 2-app-running.png
│       ├── 3-github-actions-wake.png
│       ├── 4-github-actions-terraform.png
│       ├── 5-cloudwatch-dashboard.png
│       └── 6-sns-alert-email.png

├── infra/
│   ├── backend.tf                   # Remote backend: S3 bucket + DynamoDB lock
│   ├── providers.tf                 # AWS provider + default_tags for all resources
│   ├── versions.tf                  # Required Terraform + provider versions
│   ├── variables.tf                 # Input variables for core infra
│   ├── terraform.tfvars             # Non-sensitive configuration (instance type, name)
│   ├── main.tf                      # EC2 instance, SGs, IAM instance profile
│   ├── alarms.tf                    # CloudWatch alarms (CPU, status checks)
│   ├── dashboard.tf                 # CloudWatch Dashboard JSON configuration
│   ├── sns.tf                       # SNS topic + subscriptions for failures
│   ├── iam.tf                       # IAM roles/policies (instance + CloudWatch agent)
│   ├── outputs.tf                   # Exported outputs (instance_id, SG IDs, etc.)
│   ├── user_data.sh                 # EC2 bootstrap script (start app + CW agent)
│   ├── user_data.tpl                # Template used by Terraform to inject ZIP bundle
│
│   └── infra-wake/
│       ├── backend.tf               # Remote backend for wake module
│       ├── versions.tf              # Required versions
│       ├── variables.tf             # Input variables (API name, function names)
│       ├── terraform.tfvars         # Non-sensitive env config
│       ├── main.tf                  # Lambdas + permissions
│       ├── api_gateway.tf           # API Gateway routes (/wake, /status)
│       ├── schedule.tf              # EventBridge rule (1-minute) → reaper
│       ├── iam.tf                   # IAM roles/policies for Lambdas
│       └── outputs.tf               # API URLs (wake, status), Lambda ARNs
```

## **Purpose**
• Provide a clear high-level view of the wake/sleep automation  
• Describe how Terraform, AWS, and GitHub Actions integrate  
• Outline core components and request flow

---

## **Core Components**

### **Compute**
• EC2 instance (Amazon Linux 2023)  
• Public endpoint (Wake UI redirects directly to EC2)  
• Auto-sleep via Reaper Lambda after idle timeout  

### **API Layer**
• API Gateway HTTP API  
• `/wake` → Wake Lambda  
• `/status` → Status Lambda  
• CORS restricted  
• No authentication (public demo)

### **Automation**
• EventBridge schedule (1-minute) → Reaper Lambda  
• Reaper checks SSM parameter `/ci-wake/last_wake`  
• Reaper stops EC2 if idle time exceeded  
• Wake Lambda updates the SSM timestamp and starts EC2

### **State & Configuration**
• Terraform-managed infrastructure  
• Remote backend: S3 + DynamoDB lock  
• SSM Parameter Store:
  – `/ci-wake/last_wake` (timestamp)  
  – Instance metadata used by Lambdas

### **CI/CD**
• GitHub Actions OIDC → AWS IAM  
• Secure role assumption using condition-bound trust policy  
• Automatic packaging of Lambda functions  
• Terraform plan/apply workflows for:
  – Core infra  
  – Wake module

### **Security**
• IAM least-privilege policies for Lambdas  
• SNS KMS-encrypted notifications  
• tfsec / tflint / checkov validated  
• No secrets stored in Lambda env vars  
• Public exposure limited to HTTP API + EC2 (by design)

---

## **Request Flow — Wake**

### **User Clicks "Wake up"**
• UI calls `POST /wake`  
• Wake Lambda:
  – Validates current state  
  – Starts EC2 instance (`ec2:StartInstances`)  
  – Writes current timestamp to SSM  
• Status polling begins  
• UI redirects to EC2 when instance becomes reachable

---

## **Request Flow — Status**

### **UI Polls `/status`**
• Status Lambda:
  – Reads EC2 state  
  – Resolves public IP/DNS  
  – Returns `running / stopped / pending`  
• UI updates progress bar and ETA

---

## **Auto-Sleep Flow**

### **EventBridge Trigger Every 1 Minute**
• Reaper Lambda:
  – Reads last wake timestamp from SSM  
  – Computes idle duration  
  – If idle > threshold → stops EC2  
• Logs decision and action to CloudWatch

---

## **Failure Domains**

### **Wake Failure**
• Incorrect instance ID  
• IAM role missing start permission  
• EC2 capacity or AZ issue  

### **Status Failure**
• API misconfiguration  
• EC2 terminated or replaced  

### **Reaper Failure**
• SSM missing or corrupted  
• IAM role missing stop permission  
• EventBridge disabled  

(See `/docs/runbooks/*` for detailed runbooks.)

---

