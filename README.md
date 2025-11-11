# 🚀 Ruslan AWS — CI/CD Pipeline for Application Deployment

![Terraform](https://img.shields.io/badge/IaC-Terraform-blueviolet)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-lightgrey)
![Domain](https://img.shields.io/badge/Domain-app.ci--wake.online-blue)
![Status](https://img.shields.io/badge/State-Auto%20Wake%2FSleep-green)

---

## 🌐 Live Demo

🔹 **Wait Page:** [https://app.ci-wake.online](https://app.ci-wake.online)  
When you click **“Wake Up”**, the EC2 instance powers on automatically and the site becomes available.  
After **5 minutes of inactivity**, it shuts down to save cost — all managed automatically by Lambda and CloudWatch.

---

## 🧠 Project Overview

This project demonstrates a **fully automated CI/CD infrastructure pipeline** for deploying and managing a web application on AWS, integrating:

- **Terraform** — Infrastructure as Code for all resources  
- **GitHub Actions (OIDC)** — secure CI/CD automation without static keys  
- **Serverless control plane** — Lambda-based wake/sleep logic for EC2 lifecycle management  
- **S3 + CloudFront** — static “wake page” hosted on Always-Free tier  
- **API Gateway (HTTP)** — triggers Lambda for wake/status operations  
- **CloudWatch + EventBridge + SNS** — monitoring, scheduled tasks, and alerting  

It showcases **real-world AWS automation** while staying **highly cost-optimized and portfolio-ready**.

---

## ⚙️ Architecture Overview

Core workflow:

1. **User clicks “Wake Up”** on S3-hosted wait page (via CloudFront).  
2. **API Gateway (HTTP)** triggers `wake` Lambda.  
3. `wake` Lambda starts EC2 instance and records timestamp in **SSM Parameter Store**.  
4. `status` Lambda responds to front-end requests and checks instance state/IP.  
5. `reaper` Lambda (via **EventBridge**) stops EC2 if idle > 5 minutes.  
6. **CloudWatch** monitors instance health, CPU, and Lambda metrics.  
7. **SNS** sends alerts via email when thresholds are breached.

---

## 🧩 AWS Services Used

| Category | Services | Description |
|-----------|-----------|-------------|
| **Compute** | EC2, Lambda | EC2 hosts the app; Lambda automates wake/sleep cycle |
| **CI/CD** | GitHub Actions (OIDC) | Securely runs Terraform without long-lived keys |
| **Storage** | S3 | Static site for wake page + Terraform state backend |
| **Networking** | CloudFront, API Gateway | Global CDN + API endpoints for control plane |
| **Monitoring** | CloudWatch, EventBridge | Metrics, dashboards, scheduled reaper trigger |
| **Notifications** | SNS | Sends email when alarms (CPU/Status) fire |
| **Security** | IAM, SSM Parameter Store | Roles, policies, and dynamic runtime parameters |
| **Database/State** | DynamoDB | Terraform state locking table |

---

## 🚀 CI/CD Pipeline — GitHub Actions

- **Workflow:** `terraform.yml` (main infra) and `infra-wake.yml` (Lambda control plane)  
- **Authentication:** OIDC trust between GitHub and AWS IAM role  
- **Stages:** plan → apply → destroy (manual or on push)  
- **Concurrency control:** prevents overlapping deployments  
- **Artifacts:** build ZIPs for Lambda functions automatically  

Example jobs include:
- **terraform.yml** — deploys EC2, CloudWatch, SNS, and backend infra  
- **infra-wake.yml** — builds and updates Lambda functions (wake/status/reaper)

---

## 🧠 Lambda Functions

| Function | Runtime | Purpose |
|-----------|----------|----------|
| `wake` | Node.js 20.x | Starts EC2 instance via tag or ID |
| `status` | Python 3.12 | Returns instance state and IP for front-end |
| `reaper` | Python 3.12 | Auto-stops EC2 after `idle_minutes` threshold |

Lambdas share a common library `_common/timeparse.py` for timestamp handling.

---

## 💰 Cost Optimization Strategy

| Mechanism | Description |
|------------|-------------|
| 💤 **Auto Sleep** | EC2 automatically stops after 5 minutes of inactivity |
| ⚡ **Wake on Demand** | EC2 starts only when user clicks “Wake Up” |
| ☁️ **S3 + CloudFront** | Wait site fully static (Always-Free tier) |
| 🧠 **Serverless Control Plane** | Lambdas only run for milliseconds per event |
| 💾 **Terraform State Backend** | S3 + DynamoDB for low-cost, reliable state |
| 📉 **Monitoring Alerts** | Automatically stop or notify when CPU > 70% |

---

## 📊 Monitoring and Alerts

- **CloudWatch Dashboards:**  
  - EC2 CPU Utilization, Status Checks, and NetworkIn/Out  
  - Lambda Invocations & Duration for wake/status/reaper  
- **CloudWatch Alarms:**  
  - `ruslan-aws-dev-CPUHigh` → triggers SNS email notification  
- **SNS Topics:**  
  - `ruslan-aws-dev-alerts` — sends operational alerts  

Example command to simulate CPU load (for testing alarms):

```bash
sudo dnf install -y stress-ng
sudo stress-ng --cpu 4 --timeout 120
```

---

## 🧭 Domain and Certificates

| Component | Domain | Certificate ARN |
|------------|---------|----------------|
| 🌐 **Wait Page** | [app.ci-wake.online](https://app.ci-wake.online) | `arn:aws:acm:us-east-1:097635932419:certificate/0d400c46-2086-41b1-b6c2-74112715701a` |
| ⚙️ **API Gateway** | api.ci-wake.online | Same ACM certificate (via Route53 + Namecheap) |

---

## 🧾 Folder Structure

```
ci-cd-pipeline-aws/
├── app/                    # Web app (deployed to EC2)
├── wait-site/              # S3 + CloudFront static wait page
├── infra/                  # Terraform IaC
│   ├── infra-wake/         # Lambda + API submodule
│   ├── alarms.tf
│   ├── dashboard.tf
│   ├── sns.tf
│   ├── iam.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── user_data.sh
│   └── versions.tf
├── lambdas/                # Serverless control plane
│   ├── wake/
│   ├── status/
│   ├── reaper/
│   └── _common/
├── cloudwatch/             # CloudWatch Agent config
├── scripts/                # Helper scripts
└── docs/
    └── screenshots/        # Documentation visuals
```

---

## 🧠 Key Highlights

- ✅ **Zero manual steps** — end-to-end automation via Terraform + GitHub Actions  
- 🔐 **Secure OIDC auth** — no static credentials stored anywhere  
- ☁️ **Real AWS infrastructure** — demonstrates professional IaC setup  
- ⚙️ **Serverless orchestration** — wake/sleep lifecycle controlled via Lambda  
- 💸 **Cost-efficient design** — instance runs only when needed  
- 📊 **Visual observability** — CloudWatch dashboards and alarms  
- 🧩 **Portfolio-Ready** — clear structure, automation, and live demo

---

## 🖼️ Screenshots

| Preview | Description |
|----------|-------------|
| ![Wait Page](docs/screenshots/1-wait-page.png) | Wake Page hosted on S3 + CloudFront |
| ![App Running](docs/screenshots/2-app-running.png) | Live site after EC2 wake-up |
| ![GitHub Actions - Wake](docs/screenshots/3-github-actions-wake.png) | GitHub Actions — infra-wake.yml success |
| ![GitHub Actions - Terraform](docs/screenshots/4-github-actions-terraform.png) | Main Terraform CI/CD pipeline |
| ![CloudWatch Dashboard](docs/screenshots/5-cloudwatch-dashboard.png) | CPU & StatusCheck metrics dashboard |
| ![SNS Alert Email](docs/screenshots/6-sns-alert-email.png) | CloudWatch → SNS alert email sample |

---

## 🧩 Author

**Ruslan Dashkin** — AWS Certified Cloud Engineer  
📎 [GitHub Portfolio](https://github.com/rusets) • 🌐 [rusets.com](https://rusets.com)

