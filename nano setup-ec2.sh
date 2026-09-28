#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/anonymousanemone/early_china_coinage_aws.git"
APP_DIR="$HOME/early_china_coinage_aws"
SERVER_NAME="${1:?Usage: $0 <public-ip-or-domain>}"

echo "== System packages =="
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2 git curl build-essential cloud-guest-utils

echo "== Node 22 =="
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v

echo "== 2GB swap (skip if already present) =="
if ! swapon --show | grep -q /swapfile; then
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi
free -h

echo "== Clone app =="
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

echo "== Supabase credentials =="
echo "Create $APP_DIR/.env.production with:"
echo "  NEXT_PUBLIC_SUPABASE_URL=..."
echo "  NEXT_PUBLIC_SUPABASE_ANON_KEY=..."
echo "Opening nano now -- save (Ctrl+O, Enter) and exit (Ctrl+X) when done."
read -p "Press Enter to open the editor..." _
nano .env.production

echo "== Install + build =="
npm install
NODE_OPTIONS="--max-old-space-size=896" npm run build

STANDALONE_DIR=$(dirname "$(find .next/standalone -name server.js | head -1)")
echo "Standalone server at: $STANDALONE_DIR"

cp -r public "$STANDALONE_DIR/"
cp -r .next/static "$STANDALONE_DIR/.next/"

echo "== systemd service =="
sudo tee /etc/systemd/system/coin-app.service > /dev/null <<EOF
[Unit]
Description=Early China Coinage Next.js app
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$STANDALONE_DIR
EnvironmentFile=$APP_DIR/.env.production
Environment=PORT=3000
Environment=HOSTNAME=127.0.0.1
ExecStart=$(which node) server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable coin-app
sudo systemctl start coin-app
sudo systemctl status coin-app --no-pager

echo "== Apache reverse proxy =="
sudo a2enmod proxy proxy_http headers

sudo tee /etc/apache2/sites-available/coin-app.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $SERVER_NAME

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    RequestHeader set X-Forwarded-Proto "http"

    ErrorLog \${APACHE_LOG_DIR}/coin-app-error.log
    CustomLog \${APACHE_LOG_DIR}/coin-app-access.log combined
</VirtualHost>
EOF

sudo a2ensite coin-app.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

echo "== Done =="
echo "Test locally: curl -I http://127.0.0.1"
echo "Then confirm port 80 is open in the instance's Security Group, and visit http://$SERVER_NAME"


# ./setup-ec2.sh <new-instance-public-ip>