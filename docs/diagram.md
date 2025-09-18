```mermaid
flowchart LR
  A[Developer Push to main] --> B[GitHub Actions]
  B --> C[OIDC Assume Role in AWS]
  C --> D[Upload Zip to S3 (artifacts)]
  D --> E[SSM SendCommand -> EC2]
  E --> F[deploy_on_instance.sh pulls from S3]
  F --> G[systemd restart app]
  G --> H[Health check localhost:8080/health]
  G --> I[Logs -> CloudWatch]
