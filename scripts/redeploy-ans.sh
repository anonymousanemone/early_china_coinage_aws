#!/usr/bin/env bash
set -euo pipefail

# Redeploys the app on the ANS server: pull the latest code from GitHub,
# rebuild, put the new build in place and restart the service. A reference
# more than a script: paste the lines you need. For example, after changing
# only .env.production, skip to "Rebuild" (NEXT_PUBLIC_* values are baked in
# at build time) or just run the restart line.
#
# Set up by setup-ans.sh, which also lists what is NOT in git and so is not
# changed by a pull: .env.production, the systemd unit and the Apache proxy.

PROJECT_DIR=/usr/local/projects/chec
APP_DIR=/usr/local/projects/early_china_coinage_aws
RUN_DIR=$PROJECT_DIR/standalone

echo "== Pull latest =="
cd "$APP_DIR"
git pull --ff-only origin main

echo "== Rebuild =="
npm ci
# Optional: confirm the read-only login still works before building.
# DATABASE_URL_USER="$(grep '^DATABASE_URL_USER=' .env.production | cut -d= -f2-)" node scripts/check-counts.mjs
npm run build        # reads .env.production by itself

echo "== Put the build in place =="
STANDALONE_DIR=$(dirname "$(find .next/standalone -name server.js -not -path '*/node_modules/*' | head -1)")
echo $STANDALONE_DIR
cp -r public "$STANDALONE_DIR/"
cp -r .next/static "$STANDALONE_DIR/.next/"
sudo rm -rf "$RUN_DIR"
sudo cp -r "$STANDALONE_DIR" "$RUN_DIR"
# The service writes its page and image caches under $RUN_DIR/.next.
sudo chown -R "$(systemctl show -p User --value chec)" "$RUN_DIR"

echo "== Restart =="
sudo systemctl restart chec
sudo systemctl status chec --no-pager
curl -I http://127.0.0.1:3000/     # expect HTTP 200 (use the PORT from .env.production)
# If it fails: sudo journalctl -u chec -n 50 --no-pager
