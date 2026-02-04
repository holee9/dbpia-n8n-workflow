# Deployment Guide - DBpia n8n Workflow on Raspberry Pi 5

This guide covers deployment of the DBpia n8n workflow system on Raspberry Pi 5.

## Hardware Requirements

### Minimum
- Raspberry Pi 5 (4GB RAM)
- 32GB microSD card (Class 10)
- 5V 5A power supply

### Recommended
- Raspberry Pi 5 (8GB RAM)
- 128GB NVMe SSD (with NVMe Base)
- 5V 5A official power supply
- Active cooling

## OS Setup

### 1. Install Raspberry Pi OS 64-bit

```bash
# Use Raspberry Pi Imager
# Select: Raspberry Pi OS (64-bit) Lite
# Enable SSH, set username/password
# Configure wireless LAN
```

### 2. Update System

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git wget ca-certificates gnupg
```

## Docker Installation

```bash
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/raspbian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/raspbian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

## Application Deployment

```bash
# Clone repository
cd ~
git clone <repository-url> dbpia-n8n-workflow
cd dbpia-n8n-workflow

# Configure environment
cp .env.example .env
nano .env  # Edit required variables

# Start services
docker compose up -d

# Check status
docker compose ps
```

## Accessing n8n

After deployment:
- URL: `http://<your-raspberry-pi-ip>:5678`
- Login with credentials from `.env`

## Troubleshooting

### View logs
```bash
docker compose logs -f n8n
```

### Restart services
```bash
docker compose restart
```

### Check resource usage
```bash
docker stats
```
