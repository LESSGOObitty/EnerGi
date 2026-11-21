#!/usr/bin/env bash
set -euo pipefail
if ! command -v anvil >/dev/null 2>&1; then
    curl -L paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup
fi
sudo mkdir -p /opt/bitcoin-erc721
sudo chown -R "$USER:$USER" /opt/bitcoin-erc721
sudo tee /etc/systemd/system/anvil-evm.service > /dev/null <<EOF
[Unit]
Description=Foundry Anvil Local EVM Node (Chain 31337)
After=network.target
[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/bitcoin-erc721
ExecStart=$HOME/.foundry/bin/anvil --host 0.0.0.0 --port 8545 --chain-id 31337 --state /opt/bitcoin-erc721/anvil_state.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now anvil-evm.service
sudo systemctl status anvil-evm.service --no-pager