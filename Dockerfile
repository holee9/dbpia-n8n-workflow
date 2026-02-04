# =============================================================================
# DBpia n8n Workflow - Custom Dockerfile for Raspberry Pi ARM64
# =============================================================================
# This Dockerfile extends the official n8n image with custom dependencies
# and optimizations for Raspberry Pi 5 (ARM64 architecture).
# =============================================================================

FROM n8nio/n8n:latest

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="DBpia n8n workflow automation for Raspberry Pi"
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies for ARM64
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Python for custom scripts
        python3 \
        python3-pip \
        python3-venv \
        # Additional utilities
        curl \
        wget \
        jq \
        git \
        # Image processing utilities
        imagemagick \
        # Text processing
        poppler-utils \
        tesseract-ocr \
        tesseract-ocr-kor \
        # Network debugging
        iputils-ping \
        netcat-openbsd \
        # Cleanup
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean

# Create directories for custom workflows and data
RUN mkdir -p /home/node/.n8n/workflows \
             /home/node/.n8n/ingest \
             /home/node/.n8n/logs \
             /home/node/.n8n/custom \
             /home/node/.n8n/temp

# Install Python packages for custom n8n nodes
RUN pip3 install --no-cache-dir --upgrade \
        requests \
        beautifulsoup4 \
        lxml \
        pyyaml \
        python-dotenv \
        pandas \
        openpyxl

# Set up working directory
WORKDIR /home/node

# Copy custom n8n nodes (if any)
# COPY custom/nodes /home/node/.n8n/custom

# Copy startup script
COPY scripts/entrypoint.sh /usr/local/bin/n8n-entrypoint.sh
RUN chmod +x /usr/local/bin/n8n-entrypoint.sh

# Switch to non-root user
USER node

# Expose n8n port
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD wget --spider -q http://localhost:5678/healthz || exit 1

# Set entrypoint
ENTRYPOINT ["n8n-entrypoint.sh"]
