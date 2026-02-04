#\!/bin/bash
#
==============================================================================
# DBpia n8n Workflow - Start Services Script
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

preflight_check() {
    log_step "Running pre-flight checks..."
    if [[ \! -f "$ENV_FILE" ]]; then
        log_error ".env file not found. Please run ./deploy.sh first."
        exit 1
    fi
    if \! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available."
        exit 1
    fi
    if \! docker info &> /dev/null; then
        log_error "Docker daemon is not running."
        exit 1
    fi
    cd "$PROJECT_DIR"
    if docker compose ps | grep -q "Up"; then
        log_warn "Some services are already running."
        read -p "Restart them? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose restart
            return 0
        else
            exit 0
        fi
    fi
    log_success "Pre-flight checks passed"
}

start_services() {
    log_step "Starting services..."
    cd "$PROJECT_DIR"
    docker compose up -d
    log_info "Services started"
    docker compose ps
}

check_service_health() {
    local service=$1
    cd "$PROJECT_DIR"
    local container_name=$(docker compose ps -q "$service")
    if [[ -z "$container_name" ]]; then return 1; fi
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    case "$health_status" in
        healthy) log_success "$service: Healthy"; return 0 ;;
        unhealthy) log_error "$service: Unhealthy"; return 1 ;;
        *) log_info "$service: $health_status"; return 2 ;;
    esac
}

wait_for_healthy() {
    log_step "Waiting for services to be healthy..."
    local services=("postgres" "redis" "n8n")
    local elapsed=0
    while [[ $elapsed -lt 120 ]]; do
        local healthy_count=0
        for service in "${services[@]}"; do
            check_service_health "$service" >/dev/null 2>&1 && ((healthy_count++))
        done
        if [[ $healthy_count -eq ${#services[@]} ]]; then
            log_success "All services are healthy\!"
            return 0
        fi
        echo -ne "\r${CYAN}[PROGRESS]${NC} Healthy: $healthy_count/${#services[@]} - ${elapsed}s"
        sleep 5
        ((elapsed+=5))
    done
    echo
    log_error "Timeout waiting for services"
    return 1
}

show_service_status() {
    echo ""
    log_step "Service Status:"
    cd "$PROJECT_DIR"
    for svc in postgres redis n8n; do
        if check_service_health "$svc" >/dev/null 2>&1; then
            echo -e "  ${GREEN}v${NC} $svc: Running"
        else
            echo -e "  ${RED}x${NC} $svc: Not healthy"
        fi
    done
}

show_access_info() {
    echo ""
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        local host="${N8N_HOST:-localhost}"
        local port="${N8N_PORT:-5678}"
        local protocol="${N8N_PROTOCOL:-http}"
        log_info "n8n: ${protocol}://${host}:${port}"
    fi
}

ENABLE_WORKER=false
WAIT_FLAG=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-worker) ENABLE_WORKER=true; shift ;;
        --wait) WAIT_FLAG=true; shift ;;
        *) echo "Usage: $0 [--with-worker] [--wait]"; exit 1 ;;
    esac
done

echo -e "${BOLD}${CYAN}============================================${NC}"
echo -e "${BOLD}${CYAN}DBpia n8n - Start Services${NC}"
echo -e "${BOLD}${CYAN}============================================${NC}"
echo ""

preflight_check
start_services
[[ "$WAIT_FLAG" == true ]] && wait_for_healthy
show_service_status
show_access_info

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Services started successfully\!${NC}"
echo -e "${GREEN}============================================${NC}"
