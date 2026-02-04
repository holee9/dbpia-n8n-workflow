#!/bin/bash
#
#==============================================================================
# DBpia n8n Workflow - Backup Script
#
# Usage: ./backup.sh [options]
# Options: --db-only, --data-only, --full, --output DIR, --retention N, --quiet
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
BACKUP_DIR="${OUTPUT_DIR:-$PROJECT_DIR/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION=7

DB_USER="${DB_USER:-n8n}"
DB_NAME="${DB_NAME:-n8n}"

BACKUP_FILES=()

log_info() { [[ "$QUIET" != true ]] && echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { [[ "$QUIET" != true ]] && echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_step() { [[ "$QUIET" != true ]] && echo -e "${CYAN}[STEP]${NC} $1"; }

preflight_check() {
    log_step "Running pre-flight checks..."
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 2
    fi
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR" 2>/dev/null || true
    log_success "Pre-flight checks passed"
}

backup_database() {
    log_step "Backing up PostgreSQL database..."
    local backup_file="$BACKUP_DIR/db_${DB_NAME}_${TIMESTAMP}.sql.gz"
    local temp_file="$BACKUP_DIR/.db_temp_${TIMESTAMP}.sql"
    
    cd "$PROJECT_DIR"
    if ! docker compose ps -q postgres &>/dev/null; then
        log_warn "PostgreSQL is not running. Skipping database backup."
        return 1
    fi
    
    if docker compose exec -T postgres pg_dump -U "$DB_USER" -d "$DB_NAME" \
        --no-owner --no-acl --format=plain > "$temp_file" 2>/dev/null; then
        if command -v gzip &> /dev/null; then
            gzip -c "$temp_file" > "$backup_file"
            rm -f "$temp_file"
        else
            mv "$temp_file" "$backup_file"
        fi
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Database backed up: $(basename "$backup_file") ($size)"
        BACKUP_FILES+=("$backup_file")
        return 0
    fi
    log_error "Database backup failed"
    rm -f "$temp_file"
    return 1
}

backup_n8n_data() {
    log_step "Backing up n8n data..."
    local backup_file="$BACKUP_DIR/n8n_data_${TIMESTAMP}.tar.gz"
    
    cd "$PROJECT_DIR"
    local volume_name="dbpia-n8n-workflow_n8n_data"
    
    if ! docker volume ls -q | grep -q "$volume_name"; then
        volume_name="n8n_data"
    fi
    
    if docker run --rm -v "${volume_name}:/data:ro" -v "$BACKUP_DIR:/backup" \
        alpine tar -czf "/backup/$(basename "$backup_file")" -C /data . 2>/dev/null; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "n8n data backed up: $(basename "$backup_file") ($size)"
        BACKUP_FILES+=("$backup_file")
        return 0
    fi
    log_warn "n8n data backup skipped"
    return 1
}

backup_workflows() {
    log_step "Backing up workflow definitions..."
    local backup_file="$BACKUP_DIR/workflows_${TIMESTAMP}.tar.gz"
    local workflows_dir="$PROJECT_DIR/workflows"
    
    if [[ ! -d "$workflows_dir" ]]; then
        log_warn "Workflows directory not found. Skipping."
        return 1
    fi
    
    if tar -czf "$backup_file" -C "$PROJECT_DIR" workflows/ 2>/dev/null; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Workflows backed up: $(basename "$backup_file") ($size)"
        BACKUP_FILES+=("$backup_file")
        return 0
    fi
    log_warn "Workflows backup failed"
    return 1
}

backup_environment() {
    log_step "Backing up environment configuration..."
    local backup_file="$BACKUP_DIR/env_${TIMESTAMP}.txt"
    
    if [[ -f "$ENV_FILE" ]]; then
        grep -v "PASSWORD\|KEY\|SECRET\|TOKEN" "$ENV_FILE" > "$backup_file" 2>/dev/null || true
        echo "# Sensitive values redacted. Original: $ENV_FILE" >> "$backup_file"
        log_success "Environment backed up (sensitive values redacted)"
        BACKUP_FILES+=("$backup_file")
        return 0
    fi
    log_warn "Environment file not found. Skipping."
    return 1
}

cleanup_old_backups() {
    [[ "$NO_CLEANUP" == true ]] && return
    
    log_step "Cleaning up old backups (keeping last $RETENTION)..."
    cd "$BACKUP_DIR"
    
    local db_count=$(ls -t db_${DB_NAME}_*.sql.gz 2>/dev/null | wc -l)
    local full_count=$(ls -t full_backup_*.tar.gz 2>/dev/null | wc -l)
    
    if [[ $db_count -gt $RETENTION ]]; then
        ls -t db_${DB_NAME}_*.sql.gz | tail -n +$((RETENTION + 1)) | xargs -r rm -f
        log_info "Removed $((db_count - RETENTION)) old database backups"
    fi
    
    if [[ $full_count -gt $RETENTION ]]; then
        ls -t full_backup_*.tar.gz | tail -n +$((RETENTION + 1)) | xargs -r rm -f
        log_info "Removed $((full_count - RETENTION)) old full backups"
    fi
    
    log_success "Cleanup completed"
}

display_summary() {
    if [[ "$QUIET" == true ]]; then
        printf "%s\n" "${BACKUP_FILES[@]}"
        return
    fi
    
    echo ""
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${CYAN}Backup Summary${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    
    if [[ ${#BACKUP_FILES[@]} -gt 0 ]]; then
        echo -e "${GREEN}Backup completed successfully${NC}"
        echo ""
        echo "Backup files created:"
        for file in "${BACKUP_FILES[@]}"; do
            local size=$(du -h "$file" | cut -f1)
            echo "  $(basename "$file") ($size)"
        done
    else
        echo -e "${RED}No backup files were created${NC}"
    fi
    
    echo ""
    echo "Backup directory: $BACKUP_DIR"
    echo -e "${BOLD}${CYAN}============================================${NC}"
}

show_restore_help() {
    [[ "$QUIET" == true ]] && return
    echo ""
    echo -e "${CYAN}Restore Instructions:${NC}"
    echo ""
    echo "  1. Database restore:"
    echo "     gunzip -c db_${TIMESTAMP}.sql.gz | docker compose exec -T postgres psql -U $DB_USER $DB_NAME"
    echo ""
    echo "  2. n8n data restore:"
    echo "     docker run --rm -v n8n_data:/data -v \$PWD/backups:/backup alpine tar -xzf /backup/n8n_data_${TIMESTAMP}.tar.gz -C /data"
    echo ""
}

# Parse arguments
MODE="full"
while [[ $# -gt 0 ]]; do
    case $1 in
        --db-only) MODE="db"; shift ;;
        --data-only) MODE="data"; shift ;;
        --full) MODE="full"; shift ;;
        --output) OUTPUT_DIR="$2"; BACKUP_DIR="$2"; shift 2 ;;
        --retention) RETENTION="$2"; shift 2 ;;
        --quiet) QUIET=true; shift ;;
        --no-cleanup) NO_CLEANUP=true; shift ;;
        *) echo "Usage: $0 [--db-only] [--data-only] [--full] [--output DIR] [--retention N] [--quiet] [--no-cleanup]"; exit 1 ;;
    esac
done

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

echo -e "${BOLD}${CYAN}============================================${NC}"
echo -e "${BOLD}${CYAN}DBpia n8n - Backup${NC}"
echo -e "${BOLD}${CYAN}============================================${NC}"
echo ""

preflight_check

case "$MODE" in
    db)
        backup_database
        ;;
    data)
        backup_n8n_data
        backup_workflows
        ;;
    full)
        backup_database
        backup_n8n_data
        backup_workflows
        backup_environment
        ;;
esac

cleanup_old_backups
display_summary
show_restore_help
