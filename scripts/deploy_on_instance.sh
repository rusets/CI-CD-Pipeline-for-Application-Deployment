#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_S3_URI="${1:?Usage: deploy_on_instance.sh s3://bucket/key.zip}"
APP_ROOT="/opt/app"
RELEASES="${APP_ROOT}/releases"
CURRENT="${APP_ROOT}/current"
DEPLOY_LOG="/var/log/app/deploy.log"

log(){ printf "[%s] %s\n" "$(date -Iseconds)" "$*" | tee -a "$DEPLOY_LOG" ; }

sudo mkdir -p /var/log/app
sudo touch "$DEPLOY_LOG"
sudo chown -R ec2-user:ec2-user /var/log/app

log "Starting deploy. Artifact: ${ARTIFACT_S3_URI}"
sudo mkdir -p "$RELEASES"
sudo chown -R ec2-user:ec2-user "$APP_ROOT" "$RELEASES"

TMP="/tmp/artifact-$$"
mkdir -p "$TMP"
aws s3 cp "$ARTIFACT_S3_URI" "$TMP/artifact.zip"
unzip -o "$TMP/artifact.zip" -d "$TMP/unpacked"

SHA="$(date +%Y%m%d%H%M%S)"
TARGET="${RELEASES}/${SHA}"
mkdir -p "$TARGET"
# Expect artifact to contain 'app/' folder
cp -r "$TMP/unpacked/app/"* "$TARGET/"

pushd "$TARGET" >/dev/null
if [[ -f package.json ]]; then
  log "Installing dependencies (npm ci --omit=dev)"
  npm ci --omit=dev
fi
popd >/dev/null

# Rollover symlink
if [[ -L "$CURRENT" || -e "$CURRENT" ]]; then sudo rm -rf "$CURRENT"; fi
sudo ln -s "$TARGET" "$CURRENT"

# Install/enable service (first time)
if ! systemctl list-unit-files | grep -q "^app.service"; then
  sudo cp /opt/bootstrap/app.service /etc/systemd/system/app.service
  sudo systemctl daemon-reload
  sudo systemctl enable app.service
fi

log "Restarting service"
sudo systemctl restart app.service

log "Health check"
sleep 2
curl -fsS "http://localhost:8080/health" >/dev/null && log "Health OK" || (log "Health FAILED"; exit 1)

log "Deploy finished: ${TARGET}"
