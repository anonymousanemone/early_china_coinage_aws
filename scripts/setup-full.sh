#!/usr/bin/env bash
set -euo pipefail

# One-time setup of a blank Ubuntu server (e.g. a small EC2 instance): the app
# (systemd) and Apache with HTTPS, using the live RDS database through an SSH
# tunnel via numismatics.org. The instance can't reach RDS itself;
# numismatics.org can. A reference more than a script: you can paste the
# lines in one at a time. For the ANS server (reaches RDS directly, Apache run
# by ANS) use setup-ans.sh instead.
#
#   ./setup-full.sh <public-ip-or-domain>
#
# Because the box is small, it gets a 2GB swap file and the build is capped
# at 896MB of Node memory so it doesn't run out of RAM; the ANS server needs
# neither.
#
# NOT in git, so a pull never brings or changes them (recreate by hand):
#   .env.production, the tunnel key, the systemd units and the Apache site.
#
# Without a domain, pass the server's public IP: it's turned into an
# <ip-with-dashes>.sslip.io hostname (sslip.io resolves it back to the IP),
# which Let's Encrypt will issue a real certificate for.
# Before running: the Security Group must allow 22 (SSH), 80 and 443 — and
# nothing else.
#
# The app will write to the LIVE database.

REPO_URL="https://github.com/anonymousanemone/early_china_coinage_aws.git"
APP_DIR="$HOME/early_china_coinage_aws"
TARGET="${1:?Usage: $0 <public-ip-or-domain>}"
RDS_HOST="<host>"
JUMP_HOST="numismatics.org"
JUMP_PORT="<port>"
JUMP_USER="<user>"

if [[ "$TARGET" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
  SERVER_NAME="${TARGET//./-}.sslip.io"
else
  SERVER_NAME="$TARGET"
fi
echo "Site will be https://$SERVER_NAME"

echo "== System packages =="
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2 certbot gettext-base git curl build-essential cloud-guest-utils

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

echo "== Tunnel to RDS =="
# No passphrase, so the tunnel service can start on its own. ssh-copy-id asks
# for <user>'s numismatics.org password once and authorizes the key there.
ssh-keygen -t ed25519 -f ~/.ssh/chec_tunnel -N "" -C "chec-test-ec2-tunnel"
ssh-keyscan -p "$JUMP_PORT" "$JUMP_HOST" >> ~/.ssh/known_hosts
ssh-copy-id -i ~/.ssh/chec_tunnel.pub -p "$JUMP_PORT" "$JUMP_USER@$JUMP_HOST"

# Nothing else on this box uses 3306, so the tunnel's local end takes it.
sudo tee /etc/systemd/system/chec-tunnel.service > /dev/null <<EOF
[Unit]
Description=SSH tunnel to RDS via $JUMP_HOST
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/ssh -i $HOME/.ssh/chec_tunnel -p $JUMP_PORT -N \\
  -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \\
  -L 127.0.0.1:3306:$RDS_HOST:3306 \\
  $JUMP_USER@$JUMP_HOST
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now chec-tunnel
sleep 3
timeout 5 bash -c "</dev/tcp/127.0.0.1/3306" && echo TUNNEL_OK
# If not: sudo journalctl -u chec-tunnel -n 50 --no-pager

echo "== App settings (.env.production) =="
# Every variable the app reads in production:
# DATABASE_URL_ADMIN      read/write login: edits and sign-in.
# DATABASE_URL_USER       read-only login: every page's reads. Required.
# BETTER_AUTH_SECRET      signs login sessions; generated, never typed.
# BETTER_AUTH_URL         the site's public address, https.
# ADMIN_EMAILS            only these signed-in accounts can edit.
# AUDIT_LOG_PATH          where rows deleted through the edit UI are logged.
# NEXT_PUBLIC_*           baked into the pages at BUILD time, so changing them
#                         needs a rebuild (redeploy-full.sh). MAPBOX_TOKEN is
#                         optional: without it the Mapbox map layer is not offered.
# The RDS logins are the same as in .env.prod, with the host swapped for the
# tunnel's 127.0.0.1.
read -r -p "Admin email(s), comma-separated: " ADMIN_EMAILS
mkdir -p "$APP_DIR/logs"
( umask 077 && cat > .env.production <<EOF
DATABASE_URL_ADMIN=mysql://CHANGE_ME_RW_USER:CHANGE_ME_PASSWORD@127.0.0.1:3306/chec
DATABASE_URL_USER=mysql://CHANGE_ME_RO_USER:CHANGE_ME_PASSWORD@127.0.0.1:3306/chec
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
BETTER_AUTH_URL=https://$SERVER_NAME
ADMIN_EMAILS=$ADMIN_EMAILS
AUDIT_LOG_PATH=$APP_DIR/logs/deletions.log
NEXT_PUBLIC_SITE_URL=https://$SERVER_NAME
NEXT_PUBLIC_MAPBOX_TOKEN=
EOF
)
${EDITOR:-nano} .env.production     # fill in the CHANGE_ME values, then save

echo "== Install, check the database, build =="
npm ci
# Read-only check of each login (prints row counts). The build also reads the
# database, so find out now if a login or the tunnel is wrong.
for var in DATABASE_URL_USER DATABASE_URL_ADMIN; do
  DATABASE_URL_USER="$(grep "^$var=" .env.production | cut -d= -f2-)" node scripts/check-counts.mjs
done
NODE_OPTIONS="--max-old-space-size=896" npm run build

STANDALONE_DIR=$(dirname "$(find .next/standalone -name server.js -not -path '*/node_modules/*' | head -1)")
echo "Standalone server at: $STANDALONE_DIR"

cp -r public "$STANDALONE_DIR/"
cp -r .next/static "$STANDALONE_DIR/.next/"

echo "== systemd service =="
# HOSTNAME=127.0.0.1: the app only accepts connections from Apache on this
# machine, never directly from the internet.
sudo tee /etc/systemd/system/chec-app.service > /dev/null <<EOF
[Unit]
Description=Early China Coinage Next.js app
After=network.target chec-tunnel.service
Wants=chec-tunnel.service

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
sudo systemctl enable chec-app
sudo systemctl start chec-app
sudo systemctl status chec-app --no-pager

echo "== HTTPS certificate (Let's Encrypt) =="
# Apache's stock site serves /var/www/html on port 80, which is all the
# webroot challenge needs; renewals reuse the same path (see the template's
# port-80 vhost), and the deploy hook reloads Apache with the new certificate.
sudo certbot certonly --webroot -w /var/www/html -d "$SERVER_NAME" \
  --agree-tos --register-unsafely-without-email --non-interactive \
  --deploy-hook "systemctl reload apache2"

echo "== Apache reverse proxy =="
sudo a2enmod ssl proxy proxy_http headers rewrite
SERVER_NAME="$SERVER_NAME" APP_UPSTREAM=127.0.0.1:3000 \
  SSL_CERT="/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem" \
  SSL_KEY="/etc/letsencrypt/live/$SERVER_NAME/privkey.pem" \
  envsubst '${SERVER_NAME} ${APP_UPSTREAM} ${SSL_CERT} ${SSL_KEY}' < scripts/apache/chec-app.conf.template \
  | sudo tee /etc/apache2/sites-available/chec-app.conf > /dev/null

sudo a2ensite chec-app.conf
sudo a2dissite 000-default.conf
sudo apache2ctl configtest
sudo systemctl reload apache2

echo "== Done =="
echo "Your existing login works if it is already in the RDS database; otherwise"
echo "create each editor's login (prompts for the password):"
echo "  cd $APP_DIR && node --env-file=.env.production scripts/create-user.mjs <email>"
echo "Then visit https://$SERVER_NAME"
