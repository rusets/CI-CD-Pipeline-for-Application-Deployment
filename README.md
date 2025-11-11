# 🚀 Ruslan AWS — Multi‑Tier “Wake & Apply” Demo (Terraform + GitHub Actions + AWS)

![IaC Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2C974B)
![Cost](https://img.shields.io/badge/Cost-Idle%20Auto--Destroy%2015m-1f6feb)

> **One‑line pitch:** Visit a public “Wait Page”, press **Wake Up**, the pipeline applies Terraform and brings the stack online, streams logs to the page, then **auto‑destroys after ~15 minutes of idle**. Minimal spend, maximum signal for recruiters.

---

## Live Demo

- **Wait Page (static):** `https://app.multi-tier.space/`  
  - Click **Wake Up** → triggers CI/CD → infra is created.  
  - After successful apply, the page **redirects** to the live app/site (see **Redirect** below).
- **Redirect target (production site):** `https://multi-tier.space/`  
- The **Wait Page S3 bucket**, **CloudFront distribution**, and **HTTP API** are **pre‑created manually** and intentionally **not re‑provisioned by Terraform** to keep the solution simple and avoid DNS churn.

> If the system sits idle for ~15 minutes, an **Idle Reaper** tears it down to save cost. Visit the wait page again to re‑create on demand.

---

## How It Works (High‑Level)

1. **Static Wait Page (S3 + CloudFront)** presents a single button: **Wake Up**.  
2. The button calls a **pre‑existing HTTP API (API Gateway v2, HTTP)** → **Lambda “wake”**.  
3. The wake Lambda **dispatches a GitHub Actions workflow** (OIDC to AWS, no long‑lived keys) to **terraform apply** the stack.  
4. While the apply runs, the page can **poll “status”** and **stream logs** (simple status Lambda).  
5. When infra is **healthy**, user is **redirected** to the running site/app (`DEFAULT_DEST`).  
6. **Heartbeat** + **Idle Reaper** monitor usage. If no activity for ~15 min → **terraform destroy** to minimize spend.

---

## Architecture (Services & Data Flow)

```
User → CloudFront → S3 (Wait Page)
             │
             └── “Wake Up” → API Gateway (HTTP)
                             └→ Lambda: wake (Node.js)
                                 └→ GitHub Actions (OIDC) → Terraform Apply
                                              │
                                              ├→ AWS: VPC / EC2 (or ECR/ECS/EKS/RDS as needed)
                                              └→ CloudWatch (logs/alarms)
                             └→ Lambda: status (Python) → Streams status/log tail
                             └→ Lambda: heartbeat (Python)
                             └→ Lambda: idle-reaper (Python) → Terraform Destroy
```

**Key AWS Services used**

- **CloudFront + S3** — global, cheap **Wait Page** delivery.
- **API Gateway (HTTP)** — public webhook endpoint for **wake/status**.
- **AWS Lambda** — serverless control plane:
  - `wake` (Node.js 20) — kicks off apply via GitHub Actions.
  - `status` (Python 3.12) — returns pipeline/log status to the UI.
  - `heartbeat` (Python 3.12) — marks activity.
  - `idle-reaper` (Python 3.12) — destroys infra after inactivity.
- **GitHub Actions + OIDC** — short‑lived auth to AWS (no secrets printed).
- **Terraform** — infra as code for the ephemeral stack.
- **CloudWatch** — logs, metrics, optional alarms.

> **Deliberate simplification:** The **S3 bucket** (`multi-tier-demo-wait-site`), **CloudFront distribution** (`EVOB3TLZSKCR0`), and **HTTP API** (`multi-tier-wait-api`, stage `prod`) already exist and are **not** re‑created by Terraform per project goal.

---

## Redirect Behavior

- On successful apply and green health‑check, the Wait Page redirects to **`https://multi-tier.space/`**.  
- The destination can be configured by the page as `DEFAULT_DEST` (static) or by status payload coming from the control plane.

---

## Repository Structure (suggested)

```
.
├── .github/workflows/
│   └── infra.yml                 # apply/destroy, OIDC → AWS
├── infra/                        # Terraform for ephemeral stack (NOT the S3/CF/API)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── ssm.tf                    # parameters (tokens, config)
│   ├── user_data.sh              # app bootstrap (preserve user code)
│   └── modules/...               # optional
├── lambdas/
│   ├── wake/                     # Node.js 20
│   ├── status/                   # Python 3.12
│   ├── heartbeat/                # Python 3.12
│   └── reaper/                   # Python 3.12
├── wait-site/                    # S3 site (HTML/CSS/JS bundle)
└── docs/
    ├── architecture.png
    ├── flow.png
    └── screenshots/              # place your ready screenshots here
```

---

## Prerequisites

- **AWS account** with access to the pre‑created:
  - S3 bucket: **`multi-tier-demo-wait-site`**
  - CloudFront distribution: **`EVOB3TLZSKCR0`**
  - API Gateway HTTP API: **`multi-tier-wait-api`**, stage **`prod`**
- **GitHub repo** with **Actions** enabled and **OIDC** trust to an AWS role.
- **Terraform >= 1.6** installed locally (for dev) and in CI runner.
- **Node.js 20** (for `wake` build) and **Python 3.12** (for others) if building locally.

---

## Secrets & Configuration

Prefer **AWS SSM Parameter Store** for secrets. Keep passwords **out of Terraform state**. Use **RDS `manage_master_user_password`** when applicable. Typical parameters:

| Parameter Name                         | Example / Notes                                      |
|---------------------------------------|------------------------------------------------------|
| `/project/github/token`               | Fine‑grained PAT if needed; prefer OIDC when possible |
| `/project/github/repo`                | `rusets/aws-multi-tier-infra`                        |
| `/project/github/workflow`            | `.github/workflows/infra.yml`                        |
| `/project/runtime/default_dest`       | `https://multi-tier.space/`                          |
| `/project/idle/timeout_minutes`       | `15`                                                 |

> For **EC2 access**, use **SSM Session Manager** (no SSH key pairs).

---

## CI/CD — GitHub Actions (infra.yml)

**Workflow dispatch** with two actions: `apply` and `destroy`. Example snippet (truncated for brevity):

```yaml
name: infra

on:
  workflow_dispatch:
    inputs:
      action:
        description: "Terraform action"
        required: true
        type: choice
        default: apply
        options: [apply, destroy]
      auto_approve:
        description: "Apply/destroy without manual approval"
        required: true
        type: boolean
        default: true
  push:
    branches: [main]
    paths:
      - "infra/**/*.tf"
      - ".github/workflows/**"

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  TF_IN_AUTOMATION: "1"
  ACTION: ${{ github.event_name == 'workflow_dispatch' && inputs.action || 'apply' }}
  AUTO_APPROVE: ${{ github.event_name == 'workflow_dispatch' && inputs.auto_approve || 'true' }}
  TF_PLUGIN_CACHE_DIR: ~/.terraform.d/plugin-cache
  BUCKET: multi-tier-demo-wait-site
```

**Explanation (why this matters):**  
- `id-token: write` + OIDC → short‑lived AWS creds (no hardcoded keys).  
- `ACTION` / `AUTO_APPROVE` control non‑interactive runs.  
- `BUCKET` used to upload the wait‑site bundle (for cache‑busting + speed).

---

## Terraform Conventions (important)

- **No one‑line HCL blocks.** Use **multiline**, clean, portfolio‑ready files.  
- **Do not** store secrets in `terraform.tfvars` or Terraform state.  
- For **RDS**, prefer `manage_master_user_password = true` and read at runtime via instance role.  
- **Preserve user app code** in `user_data.sh`; change only bootstrap & secret retrieval.  
- **Comments** go **below** code blocks in markdown, not inline.

---

## Quick Start (local verification)

```bash
# 1) Clone and enter repo
git clone https://github.com/<you>/<repo>.git
cd <repo>

# 2) Set AWS profile/region (or let GitHub Actions assume via OIDC)
export AWS_REGION=us-east-1

# 3) Build Lambda zips (if building locally)
make build   # or scripts/build.sh

# 4) Terraform init/plan/apply for ephemeral stack (local test)
cd infra
terraform init
terraform plan -out=tf.plan
terraform apply -auto-approve tf.plan

# 5) Upload/refresh Wait Page (S3 + CF)
aws s3 sync ./wait-site s3://multi-tier-demo-wait-site/ --delete
aws cloudfront create-invalidation --distribution-id EVOB3TLZSKCR0 --paths "/*"
```

**What the commands do:**  
- Clone, set region, and (optionally) build Lambda packages.  
- Apply Terraform for the **ephemeral** stack only (not S3/CF/API).  
- Sync the latest **Wait Page** assets and **invalidate** CloudFront cache.

---

## End‑to‑End via the UI

1. Open `https://app.multi-tier.space/`.  
2. Click **Wake Up**. The page calls the API → `wake` Lambda → GitHub Actions → `terraform apply`.  
3. The page polls **status** (optional log tail).  
4. On green **health‑gate**, it **redirects** to `https://multi-tier.space/`.  
5. After ~15 minutes of idle (no heartbeats), **idle‑reaper** triggers **destroy**.

---

## Cost Optimization

- **Ephemeral infra**: run only when someone needs it.  
- **Idle Reaper (~15 min)**: automated teardown on inactivity.  
- **Serverless control plane**: Lambdas are near‑zero when idle.  
- **CloudFront + S3** for the Wait Page: pennies per month.  
- **No long‑lived EC2** unless the demo is “awake”.

---

## Observability & Ops

- **CloudWatch Logs** for all Lambdas.  
- Optional **metrics/alarms** (faults, latency, throttles).  
- **Runbooks** for common failures (examples in `docs/runbook.md` suggested).  
- **Health‑gate** in CI: block success until `/health` returns 200.

---

## Security Notes

- **OIDC** from GitHub → AWS role with **least privilege** (no static keys).  
- Lock down Lambda permissions (include read actions like `lambda:GetFunction` that CI may need).  
- Keep artifacts in a controlled S3 path; avoid public buckets beyond the Wait Page.  
- Prefer **SSM Parameter Store** and **instance role** for runtime secrets.

---

## Troubleshooting

**Wake button does nothing**  
- Invalidate CloudFront after uploading new site assets.  
- Verify API Gateway endpoint/stage mapping on the Wait Page.  
- Check `wake` Lambda logs.

**Workflow starts but fails**  
- Role trust/OIDC mis‑configured; verify `aud`/`sub` conditions.  
- Missing IAM actions (e.g., `lambda:GetFunction`, `logs:CreateLogStream`).  
- Provider version drift; re‑run `terraform init -upgrade`.

**No redirect after success**  
- Ensure `DEFAULT_DEST` matches `https://multi-tier.space/`.  
- Confirm health‑gate passes (target `/health` returns 200).

**Idle destroy never happens**  
- Validate heartbeat is written; check timer expression and permissions.  
- Confirm the `idle timeout` parameter in SSM is set to `15` (minutes).

---

## Roadmap / Future Work

- Stream Terraform logs to the Wait Page UI in real time (pretty tail).  
- Add a **declarative health‑gate** in CI with rollback on failure.  
- Expand demo to a **K3s/EKS** path with Helm, Prometheus, Grafana.  
- Blue/Green or Canary for the app tier.  
- Add `OPA/Conftest` **Policy‑as‑Code** to gate risky Terraform changes.

---

## Screenshots

Place your PNGs in `docs/screenshots/` and reference them here:

- `docs/screenshots/wait-page.png`  
- `docs/screenshots/log-stream.png`  
- `docs/screenshots/redirect.png`

---

## License

MIT (or your preference).

---

### Author

**Ruslan Dashkin — “Ruslan AWS 🚀”**  
Portfolio & projects, AWS/DevOps focus.
