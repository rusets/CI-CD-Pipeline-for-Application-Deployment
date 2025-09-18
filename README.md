<<<<<<< HEAD
# CI-CD-Pipeline-for-Application-Deployment
=======
# ⚙️ CI/CD Pipeline with GitHub Actions → AWS EC2

Automated build/test/deploy of a sample Node.js app to AWS EC2 using GitHub Actions + OIDC (no static keys).  
Zero-touch deployments on every push to `main`, with logs and metrics in CloudWatch.

## 📌 Overview
- Pipeline: **lint/test → build → upload artifact → SSM deploy → health check**
- Deploy uses **AWS Systems Manager** (no SSH)
- Logs shipped to **CloudWatch** (`/ci-cd/app`, `/ci-cd/deploy`)

## 🛠 Tech Stack
AWS EC2, IAM (OIDC), SSM, CloudWatch, S3 · GitHub Actions · Node.js

## 🧱 Stages
1) Test (`npm test`)  
2) Build (`zip` artifact)  
3) Upload to S3  
4) SSM RunCommand calls server-side `deploy_on_instance.sh`  
5) Systemd restarts app; health checked at `localhost:8080/health`

## 📂 Layout
- `app/` – demo Node app  
- `infra/` – Terraform: OIDC role, S3, EC2, roles, SG  
- `scripts/` – `app.service`, `deploy_on_instance.sh`  
- `cloudwatch/` – CW Agent config  
- `.github/workflows/ci-cd.yml` – pipeline

## ▶️ Quick Start
1. `cd infra && terraform init && terraform apply -auto-approve`
2. Copy outputs:
   - `deploy_role_arn` → GitHub Variable `DEPLOY_ROLE_ARN`
   - `artifact_bucket` → GitHub Variable `ARTIFACT_BUCKET`
3. Push to `main`. Action runs, uploads artifact, deploys via SSM.
4. Open: `http://<instance_public_ip>:8080` (see terraform output)

## 🔭 Observability
- CloudWatch Log Groups: `/ci-cd/app`, `/ci-cd/deploy`
- Metrics: CPU, memory, disk via CloudWatch Agent

## 🔒 Security
- OIDC (short-lived creds). No AWS keys stored.
- Instance permission: SSM + read-only to artifact bucket.
>>>>>>> b3543bb (init: push local project)
