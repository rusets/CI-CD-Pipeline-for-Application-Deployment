#!/bin/bash
# -----------------------------------------------------------------------------
# User Data (cloud-init)
# - Installs Apache & unzip on Amazon Linux 2023
# - Unpacks website files provided by Terraform (Base64 ZIP) to /var/www/html
# - Shows a small fallback page if index.html isn't present
# -----------------------------------------------------------------------------
set -euxo pipefail

PROJECT_NAME="${PROJECT_NAME}"
ENVIRONMENT="${ENVIRONMENT}"
ARCHIVE_B64="${ARCHIVE_B64}"

# 1) Install packages
dnf -y update
dnf -y install httpd unzip

# 2) Prepare web root
install -d -m 0755 /var/www/html
rm -rf /var/www/html/*

# 3) Unpack site from Base64 ZIP (created by Terraform from infra/app/public)
tmp_zip="/tmp/site.zip"
echo "$ARCHIVE_B64" | base64 -d > "$tmp_zip"
unzip -o "$tmp_zip" -d /var/www/html/ || true

# 4) Ownership & SELinux (if enabled)
chown -R apache:apache /var/www/html || true
restorecon -R /var/www/html || true

# 5) Fallback page if no index.html was in the archive
if [ ! -f /var/www/html/index.html ]; then
  cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <title>Apache on Amazon Linux 2023</title>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <style>
    body{margin:0;height:100vh;display:grid;place-items:center;background:#0f172a;color:#e2e8f0;font:16px/1.6 system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,'Helvetica Neue',Arial}
    .card{max-width:720px;padding:28px;border-radius:16px;background:#0b1220;border:1px solid #1f2a44;box-shadow:0 10px 30px rgba(0,0,0,.35)}
    h1{margin:0 0 8px;font-size:28px}
    p{margin:8px 0 0;color:#9fb3c8}
    code{background:#12203a;border:1px solid #1f2a44;border-radius:6px;padding:2px 6px}
  </style>
</head>
<body>
  <main class="card">
    <div style="margin-bottom:8px;padding:4px 10px;border-radius:999px;background:#12203a;border:1px solid #1f2a44;display:inline-block;color:#9fb3c8">
      Apache on Amazon Linux 2023
    </div>
    <h1>It works!</h1>
    <p>Files weren't found in your local archive. Put your site into <code>infra/app/public/</code> and re-apply Terraform.</p>
  </main>
</body>
</html>
HTML
fi

# 6) Start Apache
systemctl enable --now httpd