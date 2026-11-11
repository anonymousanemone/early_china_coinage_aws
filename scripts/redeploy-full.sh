#!/usr/bin/env bash
set -euo pipefail

# Connects the test EC2 app (setup-full.sh) to the live RDS database through
# an SSH tunnel via numismatics.org. The test instance can't reach RDS itself;
# numismatics.org can, so connections arrive from there just as they will once
# the app is hosted on numismatics.org. When it moves there, drop the tunnel
# and use the RDS hostname directly (as in .env.prod).
#
# A reference more than a script: paste it section by section. Most sections
# run on the EC2 instance as the user that runs chec-app; step 2 runs on
# numismatics.org. Paste "Settings" first in every new shell.
#
# The app will write to the LIVE database.

echo "== Settings (EC2; paste in every new shell) =="
RDS_HOST="<host>"
JUMP_HOST="numismatics.org"
JUMP_PORT="<port>"
JUMP_USER="<user>"
TUNNEL_PORT=3306
APP_DIR="$HOME/early_china_coinage_aws"

echo "== 1. Tunnel key (EC2) =="
ssh-keygen -t ed25519 -f ~/.ssh/chec_tunnel -N "" -C "chec-test-ec2-tunnel"
cat ~/.ssh/chec_tunnel.pub                 # copy for step 2
curl -s https://checkip.amazonaws.com      # this instance's public IP, for step 2
# Without an Elastic IP the public IP changes on stop/start; give it one first
# or leave from= out in step 2.

echo "== 2. Authorize the key (on numismatics.org, as <user>) =="
# Append one line to ~<user>/.ssh/authorized_keys. The key can then only
# forward to RDS: no shell, and only from the EC2 instance's IP.
#
#   restrict,port-forwarding,permitopen="<host>:3306",from="<EC2_PUBLIC_IP>" ssh-ed25519 AAAA... chec-test-ec2-tunnel
#
# If numismatics.org firewalls port <port>, allow the EC2 IP there too.

echo "== 3. Test the tunnel by hand (EC2) =="
ssh-keyscan -p "$JUMP_PORT" "$JUMP_HOST" >> ~/.ssh/known_hosts
ssh -i ~/.ssh/chec_tunnel -p "$JUMP_PORT" -N \
  -L "127.0.0.1:$TUNNEL_PORT:$RDS_HOST:3306" "$JUMP_USER@$JUMP_HOST"
# Leave that running; in a second session (paste Settings there first):
timeout 5 bash -c "</dev/tcp/127.0.0.1/$TUNNEL_PORT" && echo TUNNEL_OK
# Then Ctrl-C the ssh above.

echo "== 4. Tunnel as a service (EC2) =="
sudo tee /etc/systemd/system/chec-tunnel.service > /dev/null <<EOF
[Unit]
Description=SSH tunnel to RDS via $JUMP_HOST
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/ssh -i $HOME/.ssh/chec_tunnel -p $JUMP_PORT -N \\
  -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \\
  -L 127.0.0.1:$TUNNEL_PORT:$RDS_HOST:3306 \\
  $JUMP_USER@$JUMP_HOST
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now chec-tunnel
sudo systemctl status chec-tunnel --no-pager

echo "== 5. Point the app at the tunnel (EC2) =="
# In $APP_DIR/.env.production, set the RDS logins to 127.0.0.1:3307:
#   DATABASE_URL_ADMIN=mysql://<rw_user>:<password>@127.0.0.1:3307/chec
#   DATABASE_URL_USER=mysql://<ro_user>:<password>@127.0.0.1:3307/chec
# Start the app after the tunnel:
sudo mkdir -p /etc/systemd/system/chec-app.service.d
sudo tee /etc/systemd/system/chec-app.service.d/tunnel.conf > /dev/null <<EOF
[Unit]
After=chec-tunnel.service
Wants=chec-tunnel.service
EOF
sudo systemctl daemon-reload
# No rebuild: only NEXT_PUBLIC_* values are baked in at build time.
sudo systemctl restart chec-app
curl -I http://127.0.0.1:3000/     # expect HTTP 200

# If it fails: sudo journalctl -u chec-tunnel -n 50 --no-pager
#   "Permission denied"      -> key or from= IP in step 2
#   timeout                  -> numismatics.org firewall on port <port>
#   app log: connect ETIMEDOUT -> tunnel is up but numismatics.org can't reach RDS
#   (app log: sudo journalctl -u chec-app -n 50 --no-pager)
