#!/bin/bash
set -euxo pipefail

# -----------------------------------------------------------------------------
# User Data — Deploy static site from Git repository
# -----------------------------------------------------------------------------

SITE_GIT_URL="${SITE_GIT_URL}"
SITE_BRANCH="${SITE_BRANCH}"
SITE_SUBDIR="${SITE_SUBDIR}"

# Install Apache and Git
dnf -y update
dnf -y install httpd git

# Clone repository
workdir="/root/site"
rm -rf "$workdir"
git clone --depth 1 --branch "$SITE_BRANCH" "$SITE_GIT_URL" "$workdir"

# Select source directory
if [ -n "$SITE_SUBDIR" ] && [ "$SITE_SUBDIR" != "." ]; then
  SRC="$workdir/$SITE_SUBDIR"
else
  SRC="$workdir"
fi

# Deploy to Apache document root
install -d -m 0755 /var/www/html
shopt -s dotglob nullglob
cp -a "$SRC"/* /var/www/html/ || true
shopt -u dotglob nullglob
chown -R apache:apache /var/www/html || true

# Fallback page if index.html missing
if [ ! -f /var/www/html/index.html ]; then
  cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Apache is running 🎉</title>
  <style>
    html,body{height:100%}
    body{margin:0;display:grid;place-items:center;background:#0f172a;color:#e2e8f0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,Arial}
    .card{max-width:720px;padding:32px 28px;border-radius:16px;background:#0b1220;border:1px solid #1f2a44;box-shadow:0 10px 30px rgba(0,0,0,.35)}
    .pill{display:inline-block;margin-bottom:12px;padding:4px 10px;border-radius:999px;background:#12203a;border:1px solid #1f2a44;font-size:12px;color:#9fb3c8}
    h1{margin:0 0 8px}
    p{margin:8px 0 0;color:#b6c2d9}
  </style>
</head>
<body>
  <main class="card">
    <div class="pill">Apache on Amazon Linux 2023</div>
    <h1>It works!</h1>
    <p>Files weren't found in your repository/subdir. Put your site into <code>app/public</code> (or update <em>site_subdir</em>) and re-apply Terraform.</p>
  </main>
</body>
</html>
HTML
fi

# Enable and start Apache
systemctl enable --now httpd