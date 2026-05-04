#! /bin/bash
set -euo pipefail

sudo apt-get update

# systemd-resolved
sudo sed -i '/^#DNS=/c\DNS=8.8.8.8 1.1.1.1' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# PKG
sudo apt-get install --yes --no-install-recommends \
  curl vim nano fail2ban ufw \
  ca-certificates gnupg \
  software-properties-common openssl

# Disable services
for pkg in snapd snapd.socket lvm2; do sudo systemctl stop $pkg; done
for pkg in snapd snapd.socket lvm2; do sudo systemctl disable $pkg; done

# Remove old Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove --yes $pkg || true
done

# Remove bloat packages (not needed on Docker/K8s runtime node)
BLOAT_PKGS=(
  # Build tools - reduces attack surface (no compiler = harder to compile exploits)
  build-essential g++ g++-13 gcc gcc-13 cpp cpp-13
  make patch dpkg-dev rpcsvc-proto lto-disabled-list
  # Python bloat
  python3-pip python3-pip-whl
  python3-virtualenv virtualenv
  python3-wheel python3-wheel-whl
  python3-setuptools python3-setuptools-whl
  python3-launchpadlib python3-lazr.restfulclient python3-lazr.uri python3-wadllib
  # Desktop/GUI - irrelevant on server
  packagekit
  xdg-user-dirs shared-mime-info
  sgml-base xml-core
  # Insecure/deprecated
  telnet inetutils-telnet
  apt-transport-https
)
sudo apt-get remove --yes "${BLOAT_PKGS[@]}" || true

# Remove open-iscsi only if not used for boot disk
if ! lsblk -o NAME,TRAN 2>/dev/null | grep -q iscsi; then
  sudo apt-get remove --yes open-iscsi || true
fi

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install --yes --no-install-recommends \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo usermod --append --groups docker stackops

# Config
sudo mkdir -p /etc/docker
echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "512m",
    "max-file": "3"
  }
}' | sudo tee /etc/docker/daemon.json

mkdir -p /etc/systemd/system/docker.service.d

sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

sudo apt-get -y autoremove
sudo apt-get -y clean
