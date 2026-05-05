#! /bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

LOG_FILE="/var/log/custom-init.log"
sudo touch "$LOG_FILE" && sudo chmod 644 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting custom-init"

trap 'echo "[$(date +%Y-%m-%d %H:%M:%S)] ERROR: Failed at line $LINENO (exit code: $?)"' ERR

# Update systemd-resolved
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Update systemd-resolved"
sudo sed -i '/^#DNS=/c\DNS=8.8.8.8 1.1.1.1' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Updating apt package index
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Updating apt package index"
sudo apt-get update


# PKG
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Installing base packages"
sudo apt-get install --yes --no-install-recommends \
  curl vim nano fail2ban ufw \
  ca-certificates gnupg \
  software-properties-common openssl

# Disable services
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Disabling unnecessary services (snapd, lvm2-monitor)"
for pkg in snapd snapd.socket lvm2-monitor; do
  if systemctl list-unit-files | grep -q "^$pkg"; then
    sudo systemctl stop "$pkg" || true
    sudo systemctl disable "$pkg" || true
  fi
done


# Remove old Docker packages
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Removing old Docker packages"
sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Remove bloat packages (not needed on Docker/K8s runtime node)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Removing bloat packages (build tools, python bloat, desktop packages)"
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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Checking if open-iscsi is safe to remove"
if ! lsblk -o NAME,TRAN 2>/dev/null | grep -q iscsi; then
  sudo apt-get remove --yes open-iscsi || true
fi

# Add Docker's official GPG key
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Adding Docker official GPG key"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Adding Docker APT repository"
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Updating apt package index with Docker repository"
sudo apt update

# Install Docker
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Installing Docker CE and plugins"
sudo apt-get install --yes --no-install-recommends \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Adding stackops user to docker group"
if id "stackops" &>/dev/null; then
  sudo usermod --append --groups docker stackops
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: User stackops not found, skipping docker group assignment"
fi

# Config
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Configuring Docker daemon (log rotation)"
sudo mkdir -p /etc/docker
echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "512m",
    "max-file": "3"
  }
}' | sudo tee /etc/docker/daemon.json

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Enabling and starting Docker service"
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Cleaning up unused packages and apt cache"
sudo apt-get -y autoremove
sudo apt-get -y clean

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: custom-init completed successfully"
