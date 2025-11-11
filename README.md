# 🚀 Ruslan AWS — CI/CD Pipeline for Application Deployment

![Terraform](https://img.shields.io/badge/IaC-Terraform-blueviolet)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-lightgrey)
![Domain](https://img.shields.io/badge/Domain-app.ci--wake.online-blue)
![Status](https://img.shields.io/badge/State-Auto%20Wake%2FSleep-green)

---

## 🌐 Project Overview

**Ruslan AWS CI/CD Pipeline** demonstrates a **production‑grade, fully automated deployment system** built on **AWS** using **Terraform** and **GitHub Actions (OIDC)**.  
It deploys a cost‑optimized web application infrastructure that wakes up automatically on user demand and sleeps during idle time — keeping costs near zero while maintaining instant availability.

**Key goals:**
- Complete end‑to‑end Infrastructure as Code on AWS.
- Zero manual steps — everything runs via Terraform and CI/CD.
- Smart Auto‑Wake / Auto‑Sleep lifecycle powered by Lambda and CloudWatch.
- Real AWS domains, SSL, metrics, and email alerts — ready for portfolio demos.

---

## ⚙️ Architecture Overview

```mermaid
flowchart TD
  A[Wait Page (S3 + CloudFront)] -->|Wake Up| B[API Gateway (HTTP)]
  B --> C[Lambda — wake]
  B --> D[Lambda — status]
  C --> E[EC2 Instance]
  D --> E
  F[Lambda — reaper (EventBridge 1m)] --> E
  E --> G[CloudWatch Metrics & Dashboards]
  G --> H[SNS Email Notifications]
```

---

## 🧩 Components and AWS Services

| Category | Service | Purpose |
|-----------|----------|----------|
| **Compute** | EC2 | Hosts the main application (Amazon Linux 2023 + Apache) |
| **Serverless** | Lambda | wake, status, reaper — start/stop logic |
| **API Management** | API Gateway (HTTP) | Triggers Lambda via REST endpoints |
| **Automation** | EventBridge | Runs the reaper function every minute |
| **Storage** | S3 | Hosts static wait page |
| **CDN / SSL** | CloudFront + ACM | HTTPS delivery for app.ci-wake.online |
| **Monitoring** | CloudWatch | Dashboards, metrics, logs |
| **Notifications** | SNS | Sends CPU/Status alerts via email |
| **Secrets / Config** | SSM Parameter Store | Stores last wake timestamp |
| **CI/CD** | GitHub Actions (OIDC) | Terraform plan/apply/destroy |
| **Infrastructure Code** | Terraform | Complete IaC for all AWS resources |

---

## 💰 Cost Optimization

| Mechanism | Description |
|------------|-------------|
| 💤 **Auto Sleep** | EC2 stops automatically after 5 minutes of inactivity |
| ⚡ **Wake on Demand** | EC2 starts when user clicks “Wake Up” |
| ☁️ **S3 + CloudFront** | Always‑Free static hosting for wait page |
| 🧠 **Serverless Control Plane** | Lambda executes in milliseconds — near‑free |
| 💾 **Terraform State Backend** | Stored in S3 + DynamoDB for reliability |

---

## 🚀 CI/CD Workflow (GitHub Actions)

- OIDC authentication (no AWS keys stored)
- Terraform Init → Plan → Apply pipeline
- Two workflows:
  - **terraform.yml** — main infrastructure (EC2, CloudWatch, SNS, etc.)
  - **infra‑wake.yml** — serverless layer (wake/status/reaper)
- Concurrency locking ensures no parallel runs

---

## 📊 Monitoring

CloudWatch Dashboards include:
- EC2 CPU & Status Checks
- Lambda Invocations & Errors (wake, status, reaper)
- CWAgent metrics (memory, disk)
- SNS Alerts (email)

---

## 🧭 Domain & Certificates

| Component | Domain | Certificate ARN |
|------------|---------|----------------|
| 🌐 Wait Site | [app.ci-wake.online](https://app.ci-wake.online) | `arn:aws:acm:us-east-1:097635932419:certificate/0d400c46-2086-41b1-b6c2-74112715701a` |
| ⚙️ API Gateway | api.ci-wake.online | Same ACM certificate |

---

## 🧪 Simulate Load (Trigger Alarm)

```bash
sudo dnf install -y stress-ng
sudo stress-ng --cpu 4 --timeout 120
```

Run this on EC2 to exceed 70% CPU and trigger CloudWatch alarm.

---

## 📁 Folder Structure

```
ci-cd-pipeline-aws/
├── app/public/
├── infra/
│   ├── main.tf, variables.tf, dashboard.tf, sns.tf
│   ├── infra-wake/ (wake/status/reaper Lambdas)
├── lambdas/
│   ├── wake/index.js
│   ├── status/index.py
│   └── reaper/index.py
├── wait-site/
│   ├── index.html + assets/
├── .github/workflows/
│   ├── terraform.yml
│   └── infra-wake.yml
└── README.md
```

---

## 📸 Screenshots

| # | Description | File |
|---|--------------|------|
| 1️⃣ | Wait Page (before wake) | `docs/screenshots/1-wait-page.png` |
| 2️⃣ | App Running (after wake) | `docs/screenshots/2-app-running.png` |
| 3️⃣ | GitHub Actions – infra‑wake.yml | `docs/screenshots/3-github-actions-wake.png` |
| 4️⃣ | GitHub Actions – terraform.yml | `docs/screenshots/4-github-actions-terraform.png` |
| 5️⃣ | CloudWatch Dashboard | `docs/screenshots/5-cloudwatch-dashboard.png` |
| 6️⃣ | SNS Alert Email | `docs/screenshots/6-sns-alert-email.png` |

---

## 🧠 Highlights

- Fully automated Terraform CI/CD pipeline.  
- Real AWS domain with SSL and auto‑wake logic.  
- EventBridge + Lambda enable intelligent shutdown.  
- CloudWatch dashboards visualize uptime & metrics.  
- Portfolio‑ready example of DevOps automation.
