#!/bin/bash
# -----------------------------------------------------------------------------
# User Data — Deploys site on Amazon Linux 2023
# -----------------------------------------------------------------------------

set -euxo pipefail

PROJECT_NAME="${PROJECT_NAME}"
ENVIRONMENT="${ENVIRONMENT}"
ARCHIVE_B64="${ARCHIVE_B64}"

# Install Apache and unzip
dnf -y update
dnf -y install httpd unzip

# Prepare web root
install -d -m 0755 /var/www/html
rm -rf /var/www/html/*

# Unpack site archive from Base64 ZIP
tmp_zip="/tmp/site.zip"
echo "$ARCHIVE_B64" | base64 -d > "$tmp_zip"
unzip -o "$tmp_zip" -d /var/www/html/ || true

# Set permissions and restore SELinux context
chown -R apache:apache /var/www/html || true
restorecon -R /var/www/html || true

# Create fallback page if index.html is missing
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
    <p>Files weren't found in your local archive. Put your site into <code>app/public/</code> and re-apply Terraform.</p>
  </main>
</body>
</html>
HTML
fi

# Enable and start Apache
systemctl enable --now httpd