#!/bin/bash
#
#==============================================================================
# DBpia n8n Workflow - Health Check Script
#
# Usage: ./healthcheck.sh [--verbose] [--quiet] [--json]
# Exit codes: 0=healthy, 1=unhealthy, 2=critical
#==============================================================================
set -e

GREEN='[0;32m'
YELLOW='[1;33m'
RED='[0;31m'
CYAN='[0;36m'
BOLD='[1m'
NC='[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
DISK_WARN=80
DISK_CRIT=90
MEM_WARN=80
MEM_CRIT=90

OVERALL_HEALTHY=true
UNHEALTHY=()
WARNINGS=()

log_info() { [[ "$QUIET" != true ]] && echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; WARNINGS+=("$1"); }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; UNHEALTHY+=("$1"); OVERALL_HEALTHY=false; }
log_ok() { [[ "$QUIET" != true ]] && echo -e "${GREEN}[OK]${NC} $1"; }

check_docker() {
    if ! docker info &> /dev/null; then
        log_error "Docker daemon not running"
        return 2
    fi
    log_ok "Docker: Running"
}

check_container() {
    local svc=$1
    cd "$PROJECT_DIR"
    local cnt=$(docker compose ps -q "$svc" 2>/dev/null || echo "")
    if [[ -z "$cnt" ]]; then
        log_error "$svc: Not running"
        return 2
    fi
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$cnt" 2>/dev/null || echo "none")
    case "$health" in
        healthy) log_ok "$svc: Healthy" ;;
        unhealthy) log_error "$svc: Unhealthy"; return 1 ;;
        *) log_ok "$svc: Running" ;;
    esac
}

check_n8n_http() {
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    local host="${N8N_HOST:-localhost}"
    local port="${N8N_PORT:-5678}"
    local url="http://$host:$port/healthz"
    local code=000
    if command -v curl &>/dev/null; then
        code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    elif command -v wget &>/dev/null; then
        wget -q --spider --timeout=5 "$url" 2>/dev/null && code=200
    fi
    if [[ "$code" == "200" ]]; then
        log_ok "n8n HTTP: 200 OK"
        return 0
    else
        log_error "n8n HTTP: Failed"
        return 1
    fi
}

check_postgres() {
    cd "$PROJECT_DIR"
    if ! docker compose ps -q postgres &>/dev/null; then
        log_error "PostgreSQL: Not running"
        return 2
    fi
    local result=$(docker compose exec -T postgres pg_isready -U "${DB_USER:-n8n}" -d "${DB_NAME:-n8n}" 2>&1 || echo "failed")
    if echo "$result" | grep -q "accepting connections"; then
        log_ok "PostgreSQL: Ready"
        return 0
    else
        log_error "PostgreSQL: Not ready"
        return 1
    fi
}

check_redis() {
    cd "$PROJECT_DIR"
    if ! docker compose ps -q redis &>/dev/null; then
        log_error "Redis: Not running"
        return 2
    fi
    local result=$(docker compose exec -T redis redis-cli ping 2>/dev/null || echo "failed")
    if [[ "$result" == "PONG" ]]; then
        log_ok "Redis: PONG"
        return 0
    else
        log_error "Redis: Not responding"
        return 1
    fi
}

check_disk() {
    local used_percent=$(df "$PROJECT_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
    if [[ $used_percent -ge $DISK_CRIT ]]; then
        log_error "Disk: ${used_percent}% used (critical)"
        return 2
    elif [[ $used_percent -ge $DISK_WARN ]]; then
        log_warn "Disk: ${used_percent}% used (warning)"
        return 1
    else
        log_ok "Disk: ${used_percent}% used"
    fi
}

check_memory() {
    local total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local used=$((100 - (avail * 100 / total)))
    if [[ $used -ge $MEM_CRIT ]]; then
        log_error "Memory: ${used}% used (critical)"
        return 2
    elif [[ $used -ge $MEM_WARN ]]; then
        log_warn "Memory: ${used}% used (warning)"
        return 1
    else
        log_ok "Memory: ${used}% used"
    fi
}

display_summary() {
    [[ "$QUIET" == true ]] && return
    echo ""
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${CYAN}Health Check Summary${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    if [[ "$OVERALL_HEALTHY" == true ]]; then
        echo -e "${GREEN}All services are healthy${NC}"
    else
        echo -e "${RED}Some services are unhealthy:${NC}"
        printf "  - %s\n" "${UNHEALTHY[@]}"
    fi
    [[ ${#WARNINGS[@]} -gt 0 ]] && echo "" && echo -e "${YELLOW}Warnings:${NC}" && printf "  - %s\n" "${WARNINGS[@]}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
}

VERBOSE=false
QUIET=false
JSON_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose) VERBOSE=true; shift ;;
        --quiet) QUIET=true; shift ;;
        --json) JSON_MODE=true; shift ;;
        *) echo "Usage: $0 [--verbose] [--quiet] [--json]"; exit 1 ;;
    esac
done

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

check_docker
check_container postgres
check_container redis
check_container n8n
check_postgres
check_redis
check_n8n_http
check_disk || true
check_memory || true

[[ "$JSON_MODE" == true ]] && echo '{"healthy":'$OVERALL_HEALTHY',"warnings":'${#WARNINGS[@]}',"errors":${#UNHEALTHY[@]}'}'
display_summary

[[ ${#UNHEALTHY[@]} -gt 0 ]] && exit 1 || exit 0
