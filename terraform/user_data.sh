#!/bin/bash
# Bootstrap for the DR host (rendered by Terraform templatefile). Secrets are NOT set here.
set -euxo pipefail
exec > >(tee /var/log/vegah-bootstrap.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg git jq unzip openssl dnsutils bc

# Docker Engine + Compose plugin
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
usermod -aG docker ubuntu

# 2 GB swap (small instances)
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# AWS CLI v2 (used for S3 backups with the instance role)
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
# Clone the requested application branch
REPO_DIR="/home/ubuntu/vegah-devops-cloud-assessment"

if [ ! -d "$REPO_DIR/.git" ]; then
  if [ -e "$REPO_DIR" ]; then
    echo "ERROR: Repository destination exists but is not a Git repository"
    exit 1
  fi

  sudo -u ubuntu git clone \
    --branch "${repo_branch}" \
    --single-branch \
    "${repo_url}" \
    "$REPO_DIR"
fi
# Validate installed tools
docker --version
docker compose version
aws --version
git --version

# Ensure Docker is running
systemctl is-active --quiet docker

# Mark bootstrap complete only after successful validation
touch /var/log/vegah-bootstrap.done

echo "VEGAH DR host bootstrap completed successfully."
