#\!/bin/bash
#
==============================================================================
# DBpia n8n Workflow - Stop Services Script
#
Usage: ./stop.sh [--backup] [--force]
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_SCRIPT="$PROJECT_DIR/scripts/backup.sh"
TIMEOUT=30
DO_BACKUP=false
FORCE_STOP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup) DO_BACKUP=true; shift ;;
        --force) FORCE_STOP=true; shift ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        *) echo "Usage: $0 [--backup] [--force] [--timeout SEC]"; exit 1 ;;
    esac
done

echo -e "${BOLD}${CYAN}============================================${NC}"
echo -e "${BOLD}${CYAN}DBpia n8n - Stop Services${NC}"
echo -e "${BOLD}${CYAN}============================================${NC}"
echo ""

log_step "Checking service status..."
cd "$PROJECT_DIR"
if \! docker compose ps | grep -q "Up"; then
    log_warn "No services are currently running."
    exit 0
fi

if [[ "$DO_BACKUP" == true ]]; then
    log_step "Creating backup before stopping..."
    if [[ -f "$BACKUP_SCRIPT" && -x "$BACKUP_SCRIPT" ]]; then
        "$BACKUP_SCRIPT" --quiet
    else
        local backup_dir="$PROJECT_DIR/backups"
        local timestamp=$(date +%Y%m%d_%H%M%S)
        mkdir -p "$backup_dir"
        if docker compose ps -q postgres &>/dev/null; then
            log_info "Backing up PostgreSQL..."
            docker compose exec -T postgres pg_dump -U "${DB_USER:-n8n}" "${DB_NAME:-n8n}" > "$backup_dir/db_pre_stop_$timestamp.sql" 2>/dev/null || true
            log_success "Backup: db_pre_stop_$timestamp.sql"
        fi
    fi
fi

log_step "Stopping services..."
if [[ "$FORCE_STOP" \!= true ]]; then
    log_info "Attempting graceful shutdown (timeout: ${TIMEOUT}s)..."
    timeout "$TIMEOUT" docker compose stop || {
        log_warn "Graceful shutdown timed out. Forcing stop..."
        docker compose kill
    }
else
    log_info "Forcing service shutdown..."
    docker compose kill
fi

log_success "Services stopped"
echo ""
log_step "Service Status:"
if [[ $(docker compose ps -q | wc -l) -eq 0 ]]; then
    log_success "All services stopped"
    read -p "Remove volumes as well? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "This will DELETE ALL DATA\! Confirm? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Removing volumes..."
            docker compose down -v
            log_success "Volumes removed"
        fi
    fi
else
    log_warn "Some services may still be running"
    docker compose ps
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Services stopped successfully\!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
log_info "To start services again, run: ./scripts/start.sh"
