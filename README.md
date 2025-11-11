# 🚀 Ruslan AWS — CI/CD Pipeline for Application Deployment

![Terraform](https://img.shields.io/badge/IaC-Terraform-blueviolet)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-lightgrey)
![Domain](https://img.shields.io/badge/Domain-app.ci--wake.online-blue)
![Status](https://img.shields.io/badge/State-Auto%20Wake%2FSleep-green)

---

## 🌐 Live Demo

**Wait Page:** https://app.ci-wake.online

- Click **“Wake Up”** → the EC2 instance powers on automatically and the application becomes reachable.
- After **5 minutes of inactivity**, the instance shuts down to save money — all controlled by **Lambda** + **EventBridge** + **SSM**.
- GitHub Actions uses **OIDC** (no static keys) to apply Terraform.

---

## 🧠 What this project demonstrates

A production‑style, cost‑efficient deployment of an EC2‑hosted app with a **serverless control plane** and **IaC-first** approach:

- **Terraform** provisions everything end‑to‑end.
- **GitHub Actions (OIDC)** automates plan/apply/destroy.
- **S3 + CloudFront** serve a static wait page with a **Wake Up** button.
- **API Gateway (HTTP)** fronts **Lambda (wake/status/reaper)**.
- **Lambda _wake_** starts the EC2 on demand; **Lambda _status_** returns live state; **Lambda _reaper_** auto-stops when idle.
- **EventBridge** triggers reaper every minute (configurable).
- **SSM Parameter Store** stores the last wake timestamp.
- **CloudWatch Dashboards & Alarms** provide visibility and alerting (SNS email).

This is the exact pattern you would present in a DevOps/Cloud interview to prove: automation, security (OIDC), and cost control under load.

---

## ⚙️ Architecture Overview

```mermaid
flowchart TD
  U[User / Browser] -->|click Wake Up| W[Wait Page<br/>S3 + CloudFront]
  W -->|POST /wake| API[API Gateway (HTTP)]
  W -->|GET /status| API

  API --> Lwake[Lambda: wake]
  API --> Lstatus[Lambda: status]

  Lwake --> EC2[EC2 Instance<br/>Amazon Linux 2023]
  Lstatus --> EC2

  EV[EventBridge rule (every 1 min)] --> Lreaper[Lambda: reaper]
  Lreaper --> EC2

  EC2 --> CW[CloudWatch Dashboards & Alarms]
  CW --> SNS[SNS Topic (Email)]
```

> **Note:** Diagram uses simple, GitHub‑compatible Mermaid (no custom style blocks).

---

## 🧩 AWS Services used (full list)

- **Amazon EC2** — application host (Amazon Linux 2023), systemd service for app, user_data bootstrap.
- **Amazon S3** — static hosting for wait page and storing build artifacts (Lambda ZIPs, site.zip).
- **Amazon CloudFront** — CDN with custom domain `app.ci-wake.online` (ACM in `us-east-1`).
- **AWS Certificate Manager (ACM)** — public cert for the domain.
- **Amazon API Gateway (HTTP API)** — routes: `POST /wake`, `GET /status`.
- **AWS Lambda** — three functions:
  - **wake** (Node.js 20): Starts EC2, writes last wake timestamp to SSM.
  - **status** (Python 3.12): Returns EC2 state + public IP/DNS.
  - **reaper** (Python 3.12): Checks last wake and stops EC2 if idle.
- **Amazon EventBridge** — cron rule (every 1 min) → invokes `reaper`.
- **AWS Systems Manager Parameter Store** — parameter `/ci-wake/last_wake` (String, epoch seconds).
- **Amazon CloudWatch** — metrics (EC2, Lambda), dashboards, and alarms (CPU > threshold).
- **Amazon SNS** — topic for email alerts.
- **AWS IAM** — OIDC role for GitHub Actions; Lambda execution role; scoped permissions by resource prefix.
- **Terraform (remote state)** — S3 backend + DynamoDB lock table.
- **GitHub Actions** — two workflows: `terraform.yml` (infra) and `infra-wake.yml` (wake plane).

---

## 💰 Cost Optimization (complete)

| Layer | Mechanism | Why it saves money |
|------|-----------|--------------------|
| Compute | **On‑demand wake / auto‑sleep** (Lambda `wake` + `reaper`) | EC2 is **off** unless actively used; billed minutes only when needed. |
| Control plane | **Serverless** (Lambda + API GW + EventBridge) | Pay per request/invocation; near‑zero idle cost. |
| Frontend | **S3 + CloudFront** | Always‑Free/low‑cost static hosting for the wait page; keeps EC2 off. |
| Security | **OIDC to AWS** | No long‑lived keys → safer + no Secrets Manager costs for access keys. |
| Storage | **S3/DynamoDB remote state** | Pennies per month; scales; no self‑hosted state servers. |
| Monitoring | **Targeted dashboards/alarms** | Minimal custom metrics; relies on free default namespace metrics. |
| Rightsizing | **t3/t4g burstable class** | Low baseline cost, CPU credits for short bursts. |
| Region | **us‑east‑1** | Cheapest region for many managed services and ACM/CloudFront interop. |

---

## 🧪 How to trigger an alarm (for screenshots)

SSH/SSM into the EC2 instance and run one of the following to simulate high CPU:

**Amazon Linux 2 / older:**

```bash
sudo yum install -y stress
stress --cpu 4 --timeout 180
```

**Amazon Linux 2023:**

```bash
sudo dnf install -y stress-ng
sudo stress-ng --cpu 4 --timeout 180
```

You should then capture **CloudWatch Dashboard** and **Alarm** state changes.

---

## 📸 Screenshots (place these under `docs/screenshots/`)

> Ensure the paths below exist in your repo: `docs/screenshots/<file>.png`

1. **Wait page (before Wake Up)**  
   `docs/screenshots/1-wait-page.png`

2. **App running (after redirect)**  
   `docs/screenshots/2-app-running.png`

3. **GitHub Actions — infra-wake.yml successful run**  
   `docs/screenshots/3-github-actions-wake.png`

4. **GitHub Actions — terraform.yml successful run**  
   `docs/screenshots/4-github-actions-terraform.png`

5. **CloudWatch Dashboard (EC2 + Lambda panels)**  
   `docs/screenshots/5-cloudwatch-dashboard.png`

6. **SNS alert email (ALARM state)**  
   `docs/screenshots/6-sns-alert-email.png`

Inline gallery example:

| | |
|---|---|
| ![Wait](docs/screenshots/1-wait-page.png) | ![Running](docs/screenshots/2-app-running.png) |
| ![Wake CI](docs/screenshots/3-github-actions-wake.png) | ![Terraform CI](docs/screenshots/4-github-actions-terraform.png) |
| ![Dashboards](docs/screenshots/5-cloudwatch-dashboard.png) | ![SNS](docs/screenshots/6-sns-alert-email.png) |

---

## 🧾 Full Folder Structure (expanded)

```
ci-cd-pipeline-aws/
├── app/
│   └── public/
│       ├── assets/
│       │   ├── css/
│       │   └── js/
│       └── index.html
├── build/
│   ├── site.zip
│   ├── wake.zip
│   ├── status.zip
│   ├── reaper.zip
│   └── stage/
│       ├── status/
│       └── reaper/
├── cloudwatch/
│   └── amazon-cloudwatch-agent.json
├── docs/
│   └── screenshots/
│       ├── 1-wait-page.png
│       ├── 2-app-running.png
│       ├── 3-github-actions-wake.png
│       ├── 4-github-actions-terraform.png
│       ├── 5-cloudwatch-dashboard.png
│       └── 6-sns-alert-email.png
├── infra/
│   ├── alarms.tf
│   ├── backend.tf
│   ├── dashboard.tf
│   ├── iam.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── sns.tf
│   ├── terraform.tfvars
│   ├── user_data.sh
│   ├── user_data.tpl
│   ├── variables.tf
│   ├── versions.tf
│   └── infra-wake/
│       ├── backend.tf
│       ├── iam.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── schedule.tf
│       ├── terraform.tfvars
│       ├── variables.tf
│       └── versions.tf
├── lambdas/
│   ├── _common/
│   │   └── timeparse.py
│   ├── reaper/
│   │   └── index.py
│   ├── status/
│   │   └── index.py
│   └── wake/
│       └── index.js
├── scripts/
│   ├── app.service
│   └── deploy_on_instance.sh
├── wait-site/
│   ├── assets/
│   │   ├── css/
│   │   └── js/
│   └── index.html
└── .github/workflows/
    ├── terraform.yml
    └── infra-wake.yml
```

---

## 🔐 Security & IAM (high level)

- GitHub → AWS via **OIDC** role (`github-actions-ci-cd-pipeline-aws`).
- Lambda execution role: least‑privilege to **start/stop EC2** by tag or ID, **Get/Put** the exact SSM param, and **CloudWatch Logs**.
- Additional scoped policy allowing GitHub Actions to **CRUD only functions with prefix** `ruslan-aws-<env>-*` and **pass** the execution role.

---

## 🧭 Domain & Certificates

- **Wait site**: `app.ci-wake.online` via CloudFront + S3.
- **API**: custom domain `api.ci-wake.online` (optional), ACM in `us-east-1`.

> ACM example ARN (keep in repo notes if needed):  
> `arn:aws:acm:us-east-1:097635932419:certificate/0d400c46-2086-41b1-b6c2-74112715701a`

---

## 📌 Portfolio Tips

- Keep **both** workflows green and pinned in README badges.
- Include the **diagram**, the **screenshots grid**, and a short **“How it works”** GIF if you want extra flair.
- Add a short **“What I’d improve next”** section (multi‑AZ ASG; health checks; ALB; blue/green).

---

## 📦 Reproduce locally (optional)

```bash
# prerequisites: terraform >= 1.6, awscli, jq
cd infra
terraform init -upgrade
terraform plan -var="environment=dev"
terraform apply -auto-approve -var="environment=dev"
```

---

**Author:** Ruslan AWS • CI/CD & Cost‑Optimized Autowake Pattern
