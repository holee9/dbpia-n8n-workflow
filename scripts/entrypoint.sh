#!/bin/bash
# =============================================================================
# n8n Entrypoint Script
# =============================================================================
# This script handles the startup of n8n with proper initialization checks.
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate required environment variables
validate_env() {
    log_info "Validating environment variables..."
    
    local required_vars=("N8N_ENCRYPTION_KEY" "DB_PASSWORD")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
    
    log_info "Environment validation complete"
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    log_info "Waiting for PostgreSQL to be ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if pg_isready -h "${DB_POSTGRESDB_HOST:-postgres}" -p 5432 -U "${DB_POSTGRESDB_USER:-n8n}" >/dev/null 2>&1; then
            log_info "PostgreSQL is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log_error "PostgreSQL did not become ready in time"
    exit 1
}

# Wait for Redis to be ready
wait_for_redis() {
    log_info "Waiting for Redis to be ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if redis-cli -h "${N8N_REDIS_REDIS_HOST:-redis}" -p 6379 ping >/dev/null 2>&1; then
            log_info "Redis is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log_warn "Redis did not become ready in time, continuing anyway"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p /home/node/.n8n/workflows
    mkdir -p /home/node/.n8n/ingest
    mkdir -p /home/node/.n8n/logs
    mkdir -p /home/node/.n8n/temp
    
    log_info "Directories created"
}

# Display startup information
display_info() {
    log_info "=========================================="
    log_info "n8n Workflow Automation"
    log_info "=========================================="
    log_info "Version: ${N8N_VERSION:-latest}"
    log_info "Environment: ${NODE_ENV:-production}"
    log_info "Host: ${N8N_HOST:-localhost}:${N8N_PORT:-5678}"
    log_info "Queue Mode: ${EXECUTIONS_MODE:-regular}"
    log_info "Timezone: ${TZ:-UTC}"
    log_info "=========================================="
}

# Main execution
main() {
    log_info "Starting n8n initialization..."
    
    validate_env
    create_directories
    
    # Wait for dependencies if in queue mode
    if [[ "${EXECUTIONS_MODE}" == "queue" ]]; then
        wait_for_postgres
        wait_for_redis
    fi
    
    display_info
    
    # Start n8n
    log_info "Starting n8n..."
    exec n8n start
}

# Run main function
main "$@"
