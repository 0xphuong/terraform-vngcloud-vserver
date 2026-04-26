#! /bin/bash
sudo apt-get update

# systemd-resolved
sudo sed -i '/^#DNS=/c\DNS=8.8.8.8 1.1.1.1' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# PKG
sudo apt-get install --yes --no-install-recommends curl vim nano fail2ban ufw python3-pip ca-certificates curl gnupg apt-transport-https software-properties-common virtualenv openssl

# Disable service
for pkg in snapd snapd.socket lvm2; do sudo sudo systemctl stop $pkg; done
for pkg in snapd snapd.socket lvm2; do sudo sudo systemctl disable $pkg; done

# recheck docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# # Add Docker's official GPG key:
# sudo install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg

# # Add the repository to Apt sources:
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt-get update

# # Install
# sudo apt-get install --yes --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# sudo usermod --append --groups docker stackops

sudo apt-get --yes --no-install-recommends install docker.io
sudo systemctl enable docker
sudo usermod --append --groups docker stackops

# # Config
echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "256m"
    }
}' | sudo tee /etc/docker/daemon.json

mkdir -p /etc/systemd/system/docker.service.d

sudo systemctl daemon-reload
sudo systemctl restart docker

# 
sudo apt-get -y autoremove
sudo apt-get -y clean 
