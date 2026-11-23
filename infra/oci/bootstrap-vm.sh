#!/usr/bin/env bash
# First-time setup of the staging VM (SWM-36 / SWM-202). Run ON the VM as the ubuntu user:
#   bash <(curl -fsSL <raw URL>)
# Installs Docker (with compose) and Tailscale, adds an optional 8 GB swap file,
# then starts Tailscale, which prints a login link for you to open.
# Safe to re-run. Opens no firewall ports; Tailscale only makes outbound connections.
set -euo pipefail

echo "== Updating packages"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

if ! command -v docker >/dev/null; then
  echo "== Installing Docker"
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"

if ! command -v tailscale >/dev/null; then
  echo "== Installing Tailscale"
  curl -fsSL https://tailscale.com/install.sh | sudo sh
fi

if [ ! -f /swapfile ]; then
  echo "== Adding 8 GB swap"
  sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
  sudo mkswap /swapfile >/dev/null && sudo swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

echo "== Starting Tailscale (open the link it prints and sign in with the same account as your Mac and phone)"
sudo tailscale up --ssh=false || true

echo
echo "== Done. Log out and back in so the docker group applies, then run:"
echo "   docker --version && docker compose version && tailscale ip -4"
