#!/bin/bash
#
#==============================================================================
# DBpia n8n Workflow - Raspberry Pi Deployment Script
#
# Usage: ./deploy.sh [--skip-checks] [--with-worker] [--dev]
#==============================================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE="$PROJECT_DIR/.env.example"
BACKUP_DIR="$PROJECT_DIR/backups"
DATA_DIR="$PROJECT_DIR/data"
MIN_RAM_MB=4096
MIN_DISK_GB=8

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Hardware check
check_hardware() {
    log_step "Checking Hardware"
    [[ -f /proc/device-tree/model ]] && {
        local model=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null)
        log_info "Detected: $model"
    }
    local arch=$(uname -m)
    if [[ "$arch" != "aarch64" && "$arch" != "arm64" ]]; then
        log_warn "Designed for ARM64. Current: $arch"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    else
        log_success "Architecture: ARM64"
    fi
}

check_ram() {
    log_step "Checking RAM"
    local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mb=$((total_kb / 1024))
    log_info "Total RAM: ${total_mb}MB"
    if [[ $total_mb -lt $MIN_RAM_MB ]]; then
        log_warn "Recommended: ${MIN_RAM_MB}MB+"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    else
        log_success "RAM check passed"
    fi
}

check_disk() {
    log_step "Checking Disk Space"
    local avail_gb=$(df -BG "$PROJECT_DIR" | tail -1 | awk '{print $4}' | tr -d 'G')
    log_info "Available: ${avail_gb}GB"
    if [[ $avail_gb -lt $MIN_DISK_GB ]]; then
        log_error "Need ${MIN_DISK_GB}GB+, have ${avail_gb}GB"
        exit 1
    fi
    log_success "Disk space OK"
}

check_docker() {
    log_step "Checking Docker"
    if ! command -v docker &> /dev/null; then
        log_warn "Docker not found. Installing..."
        sudo apt-get update -qq
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/raspbian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/raspbian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo usermod -aG docker $USER
        log_success "Docker installed. Log out/in for group changes."
        exit 0
    fi
    log_success "Docker installed"
    docker info &> /dev/null || { log_error "Docker daemon not running"; exit 1; }
}

setup_environment() {
    log_step "Setting Up Environment"
    if [[ -f "$ENV_FILE" ]]; then
        log_info ".env exists"
        read -p "Reconfigure? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
        mkdir -p "$BACKUP_DIR"
        cp "$ENV_FILE" "$BACKUP_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    # Generate encryption key
    if command -v openssl &> /dev/null; then
        KEY=$(openssl rand -hex 32)
    else
        KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 64 | head -n 1)
    fi
    sed -i "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$KEY/" "$ENV_FILE"
    log_success "Environment configured"
}

setup_directories() {
    log_step "Creating Directories"
    mkdir -p "$DATA_DIR"/{ingest,logs,postgres}
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$PROJECT_DIR/memory"/{errors,decisions,learnings}
    log_success "Directories created"
}

pull_images() {
    log_step "Pulling Docker Images"
    cd "$PROJECT_DIR"
    docker compose pull
    log_success "Images pulled"
}

start_services() {
    log_step "Starting Services"
    cd "$PROJECT_DIR"
    [[ "$ENABLE_WORKER" == "true" ]] && docker compose --profile worker up -d || docker compose up -d
    log_success "Services started"
}

show_info() {
    cd "$PROJECT_DIR"
    echo ""
    docker compose ps
    echo ""
    source "$ENV_FILE"
    log_info "n8n: ${N8N_PROTOCOL:-http}://${N8N_HOST:-localhost}:${N8N_PORT:-5678}"
    echo ""
    log_info "Commands: ./scripts/{stop.sh,restart.sh,healthcheck.sh,backup.sh}"
}

# Parse args
SKIP_CHECKS=false
ENABLE_WORKER=false
for arg in "$@"; do
    case $arg in
        --skip-checks) SKIP_CHECKS=true ;;
        --with-worker) ENABLE_WORKER=true ;;
    esac
done

clear
echo -e "${BOLD}${CYAN} _      ____  ____    _    _ ${NC}"
echo -e "${BOLD}${CYAN}| |    / __ \|  _ \  / \  | |${NC}"
echo -e "${BOLD}${CYAN}| |   | |  | | |_) |/ _ \ | |${NC}"
echo -e "${BOLD}${CYAN}| |___| |__| |  _ <|  _ \| |___${NC}"
echo -e "${BOLD}${CYAN}|______\____/|_| \_\_| \_\_____|${NC}"
echo -e "${BOLD}${CYAN}     n8n Deployment${NC}"
echo ""

[[ "$SKIP_CHECKS" == false ]] && {
    check_hardware
    check_ram
    check_disk
    check_docker
}
setup_environment
setup_directories
pull_images
start_services
show_info
echo ""
log_success "Deployment complete!"
