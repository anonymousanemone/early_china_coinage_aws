echo "== Install + build =="
npm install
npm run build

STANDALONE_DIR=$(dirname "$(find .next/standalone -name server.js | head -1)")
echo "Standalone server at: $STANDALONE_DIR"

cp -r public "$STANDALONE_DIR/"
cp -r .next/static "$STANDALONE_DIR/.next/"

echo "== Copying Standalone to Project dir =="
sudo rm -r /usr/local/projects/chec/standalone
sudo cp -r "$STANDALONE_DIR" /usr/local/projects/chec/standalone

echo "== systemd service =="

sudo systemctl daemon-reload
sudo systemctl enable coin-app
sudo systemctl start coin-app
sudo systemctl status coin-app --no-pager