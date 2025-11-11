
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
After **5 minutes of inactivity**, it shuts down automatically — managed by AWS Lambda and CloudWatch.

---

## 🧠 Project Overview

This project demonstrates a **production-grade AWS CI/CD pipeline** that deploys and manages an application using Infrastructure as Code (IaC).  
It combines Terraform, GitHub Actions, and serverless automation to minimize cost while keeping the environment responsive and observable.

**Core features:**
- Full **Infrastructure as Code** (Terraform)
- **GitHub Actions (OIDC)** — no long-term AWS credentials
- **Serverless control plane:** Lambda + EventBridge
- **Static wait page** on **S3 + CloudFront**
- **Real-time monitoring** via CloudWatch and SNS

---

## ⚙️ Architecture Overview

```mermaid
flowchart TD
  A[Wait Page (S3 + CloudFront)] -->|POST /wake| B[API Gateway (HTTP)]
  A -->|GET /status| B
  B --> C[Lambda: wake]
  B --> D[Lambda: status]
  C --> E[(EC2 Instance)]
  D --> E
  F[EventBridge Rule (1m)] --> G[Lambda: reaper]
  G --> E
  E --> H[CloudWatch Dashboards & Alarms]
  H --> I[SNS Email Notifications]
```

---

## 🧩 AWS Components

| Category | Services |
|-----------|-----------|
| **Compute** | EC2 (Amazon Linux 2023) — app hosting |
| **Serverless** | Lambda (`wake`, `status`, `reaper`) |
| **API & Events** | API Gateway (HTTP), EventBridge |
| **State & Config** | SSM Parameter Store (`/ci-wake/last_wake`), S3, DynamoDB (Terraform backend) |
| **Monitoring & Alerts** | CloudWatch (metrics, dashboards, alarms), SNS (email) |
| **Security & Access** | IAM roles, OIDC trust for GitHub Actions |

---

## 💰 Cost Optimization

| Mechanism | Description |
|------------|-------------|
| 💤 **Auto Sleep** | EC2 automatically stops after inactivity (via `reaper`). |
| ⚡ **Wake on Demand** | EC2 only starts when a user clicks “Wake Up”. |
| ☁️ **Static Wait Page** | S3 + CloudFront = Always-Free tier. |
| 🧠 **Serverless Control Plane** | Lambda only runs for milliseconds. |
| 💾 **S3 + DynamoDB Backend** | Cheap, durable Terraform state management. |

---

## 🚀 CI/CD Workflow (GitHub Actions)

- **OIDC authentication** — no static AWS credentials.  
- `terraform.yml`: main infrastructure (EC2, IAM, CloudWatch, SNS).  
- `infra-wake.yml`: Lambda packaging, IAM, and scheduling logic.  
- **Concurrency groups** prevent simultaneous runs.  
- **Terraform plan/apply/destroy** automated per commit.  

---

## 📊 Monitoring & Alerts

- **Dashboards:**
  - EC2 — CPU Utilization, Status Checks  
  - Lambda — Invocations, Duration, Errors  
  - CloudWatch Agent — Memory, Disk  
- **Alarms:**
  - CPU > 70% → triggers **SNS email**
- **SSM:**  
  - `/ci-wake/last_wake` tracks the last wake timestamp

### 🧪 Simulate Load (trigger alert)

```bash
sudo dnf install -y stress-ng
sudo stress-ng --cpu 4 --timeout 120
```

---

## 🧭 Domains & Certificates

| Component | Domain | Description |
|------------|---------|-------------|
| 🌐 Wait Page | [app.ci-wake.online](https://app.ci-wake.online) | Hosted on S3 + CloudFront |
| ⚙️ API Gateway | api.ci-wake.online | Custom domain + ACM certificate |

---

## 🧾 Folder Structure

```
ci-cd-pipeline-aws/
├── app/
│   └── public/
│       ├── index.html
│       └── assets/
│           ├── css/
│           └── js/
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── providers.tf
│   ├── backend.tf
│   ├── outputs.tf
│   ├── alarms.tf
│   ├── dashboard.tf
│   ├── sns.tf
│   ├── user_data.sh
│   ├── user_data.tpl
│   └── infra-wake/
│       ├── main.tf
│       ├── iam.tf
│       ├── schedule.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf
│       └── versions.tf
├── lambdas/
│   ├── wake/    └── index.js
│   ├── status/  └── index.py
│   ├── reaper/  └── index.py
│   └── _common/ └── timeparse.py
├── wait-site/
│   ├── index.html
│   └── assets/
│       ├── css/
│       └── js/
├── scripts/
│   ├── deploy_on_instance.sh
│   └── app.service
├── cloudwatch/
│   └── amazon-cloudwatch-agent.json
├── .github/workflows/
│   ├── terraform.yml
│   └── infra-wake.yml
└── README.md
```

---

## 🖼️ Screenshots

| # | Description | Image |
|---|--------------|--------|
| 1️⃣ | Wait Page (before wake) | ![Wait Page](docs/screenshots/1-wait-page.png) |
| 2️⃣ | Running Application | ![App Running](docs/screenshots/2-app-running.png) |
| 3️⃣ | GitHub Actions — infra-wake.yml | ![Wake Workflow](docs/screenshots/3-github-actions-wake.png) |
| 4️⃣ | GitHub Actions — terraform.yml | ![Terraform Workflow](docs/screenshots/4-github-actions-terraform.png) |
| 5️⃣ | CloudWatch Dashboard | ![CloudWatch Dashboard](docs/screenshots/5-cloudwatch-dashboard.png) |
| 6️⃣ | SNS Email Alert | ![SNS Email Alert](docs/screenshots/6-sns-alert-email.png) |

---

## 🧠 Key Highlights

- **Fully automated AWS deployment** with Terraform and GitHub Actions.  
- **Zero manual credentials** — OIDC trust policy.  
- **Dynamic cost control** — instance wakes/sleeps automatically.  
- **Visual dashboards & alerts** for real-world observability.  
- **Portfolio-grade presentation** — real domain, screenshots, full automation.

---

© 2025 Ruslan AWS Projects — All rights reserved.
