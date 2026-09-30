#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/early_china_coinage_aws"
cd "$APP_DIR"

echo "== Pull latest =="
git pull --ff-only origin main

echo "== Install + build =="
npm ci
NODE_OPTIONS="--max-old-space-size=896" npm run build

STANDALONE_DIR=$(dirname "$(find .next/standalone -name server.js | head -1)")
cp -r public "$STANDALONE_DIR/"
cp -r .next/static "$STANDALONE_DIR/.next/"

echo "== Restart service =="
sudo systemctl restart coin-app
sudo systemctl status coin-app --no-pager
