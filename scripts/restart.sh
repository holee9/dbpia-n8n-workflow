#\!/bin/bash
#
==============================================================================
# DBpia n8n Workflow - Restart Services Script
#
Usage: ./restart.sh [--with-worker] [--wait] [--sequential]
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD=033[1m\
NC=033[0m\

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
MAX_WAIT=120
RESTART_DELAY=5

check_service_health() {
    local service=$1
    cd "$PROJECT_DIR"
    local container_name=$(docker compose ps -q "$service" 2>/dev/null || echo "")
    [[ -z "$container_name" ]] && return 1
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    [[ "$health_status" == "healthy" ]]
}

sequential_restart() {
    log_step "Performing sequential restart (zero-downtime)..."
    cd "$PROJECT_DIR"
    local services=("redis" "postgres" "n8n")
    for service in "${services[@]}"; do
        if \! docker compose ps -q "$service" &>/dev/null; then
            log_warn "$service not running, skipping..."
            continue
        fi
        log_info "Restarting $service..."
        docker compose restart "$service"
        sleep "$RESTART_DELAY"
        local elapsed=0
        while [[ $elapsed -lt $MAX_WAIT ]]; do
            if check_service_health "$service" 2>/dev/null; then
                log_success "$service is healthy"
                break
            fi
            echo -ne "\r${CYAN}[WAIT]${NC} $service starting... ${elapsed}s"
            sleep 5
            ((elapsed+=5))
        done
        echo
    done
    if [[ "$ENABLE_WORKER" == true ]]; then
        log_info "Restarting n8n-worker..."
        docker compose --profile worker restart n8n-worker 2>/dev/null || true
    fi
}

standard_restart() {
    log_step "Restarting all services..."
    cd "$PROJECT_DIR"
    if [[ "$ENABLE_WORKER" == true ]]; then
        docker compose --profile worker restart
    else
        docker compose restart
    fi
    log_info "Waiting ${RESTART_DELAY}s for services to initialize..."
    sleep "$RESTART_DELAY"
}

wait_for_healthy() {
    log_step "Verifying service health..."
    cd "$PROJECT_DIR"
    local services=("postgres" "redis" "n8n")
    local elapsed=0
    while [[ $elapsed -lt $MAX_WAIT ]]; do
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
    log_warn "Some services may still be starting..."
}

show_status() {
    echo ""
    log_step "Service Status:"
    cd "$PROJECT_DIR"
    docker compose ps
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
SEQUENTIAL_FLAG=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-worker) ENABLE_WORKER=true; shift ;;
        --wait) WAIT_FLAG=true; shift ;;
        --sequential) SEQUENTIAL_FLAG=true; shift ;;
        *) echo "Usage: $0 [--with-worker] [--wait] [--sequential]"; exit 1 ;;
    esac
done

echo -e "${BOLD}${CYAN}============================================${NC}"
echo -e "${BOLD}${CYAN}DBpia n8n - Restart Services${NC}"
echo -e "${BOLD}${CYAN}============================================${NC}"
echo ""

if [[ "$SEQUENTIAL_FLAG" == true ]]; then
    sequential_restart
else
    standard_restart
fi

[[ "$WAIT_FLAG" == true ]] && wait_for_healthy
show_status
show_access_info

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Services restarted successfully\!${NC}"
echo -e "${GREEN}============================================${NC}"
