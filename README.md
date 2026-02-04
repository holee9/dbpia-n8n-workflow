# DBpia n8n Workflow


An automated academic research assistant that retrieves, filters, and stores research papers from the DBpia Open API using self-hosted n8n workflows on Raspberry Pi.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Quick Start Guide](#quick-start-guide)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Deployment Scripts](#deployment-scripts)
- [Troubleshooting](#troubleshooting)
- [/memory Folder](#memory-folder)
- [License](#license)(#license)

---

## Project Overview

This project automates the collection and curation of academic papers from DBpia, a Korean academic database. It uses n8n workflows to fetch papers, score their relevance using AI, and store them in a PostgreSQL database for easy retrieval and analysis.

### Features

| Feature | Description |
|---------|-------------|
| **Historical Ingestion** | Bulk import of existing papers via recursive pagination with configurable batch sizes (50 papers per page) |
| **Daily Sync** | Automatic incremental updates every 24 hours with intelligent deduplication based on DOI/ArticleID |
| **AI Relevance Scoring** | LLM-powered paper evaluation with 0-100 scoring, technical summaries, and category assignment |
| **Self-Hosted** | Runs entirely on Raspberry Pi with Docker for low-cost, privacy-preserving operation |
| **REST API** | Webhook endpoints for triggering searches and querying stored papers |

### Architecture

The system consists of three main workflow tracks:

- **Track A - Historical Ingestion**: Bulk imports existing papers via recursive pagination with 50 papers per page
- **Track B - Daily Sync**: Automated daily fetching of new papers with DOI-based deduplication
- **Track C - AI Relevance Scoring**: LLM-powered evaluation scoring papers 0-100, generating summaries, and assigning categories

### Workflow Components

- **HTTP Request Node**: Fetches data from DBpia Open API with rate limiting (2000ms delays)
- **Code/Function Node**: Handles XML parsing, pagination logic, and data normalization
- **PostgreSQL Node**: Manages database operations including deduplication checks
- **LLM/AI Node**: Performs relevance scoring and generates technical summaries
- **Schedule/Cron Node**: Triggers daily sync workflows
- **Webhook Node**: Exposes REST endpoints for external integrations

---

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Device | Raspberry Pi 4 | Raspberry Pi 5 |
| RAM | 4GB | 8GB |
| Storage | 32GB SD card | 128GB SSD/NVMe |
| Network | Ethernet/WiFi | Ethernet (stable) |

### Software Requirements

- **Operating System**: Raspberry Pi OS (64-bit recommended) or any Debian-based Linux
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **Git**: For cloning this repository

### Installation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
```

---

## Quick Start Guide

### 1. Clone Repository

```bash
git clone https://github.com/holee9/dbpia-n8n-workflow.git
cd dbpia-n8n-workflow
```

### 2. Configure Environment Variables

Create a `.env` file in the project root:

```bash
cp .env.example .env
nano .env
```

Edit the following variables:

```env
# DBpia API Configuration
DBPIA_API_KEY=your_dbpia_api_key_here
DBPIA_API_BASE_URL=https://api.dbpia.co.kr/api

# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=research_papers
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=your_secure_password_here

# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_ENCRYPTION_KEY=your_random_32_char_encryption_key

# AI/LLM Configuration (optional, for relevance scoring)
LLM_PROVIDER=openai
LLM_API_KEY=your_llm_api_key_here
LLM_MODEL=gpt-4-turbo
LLM_BASE_URL=https://api.openai.com/v1
```

### 3. Start Services

```bash
# Build and start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

### 4. Access n8n Web Interface

1. Open your browser and navigate to http://localhost:5678 (or http://YOUR_PI_IP:5678 for remote access)

2. **First Time Setup**:
   - Create your admin account
   - Configure credential for DBpia API in Credentials > Add Credential > HTTP Header Auth

3. **Import Workflows** from the `workflows/` directory

### 5. Initialize Database Schema

```bash
docker compose exec postgres psql -U n8n_user -d research_papers -c "\dt"
```

---

## Project Structure

```
dbpia-n8n-workflow/
|
+-- .env.example              # Environment variables template
+-- docker-compose.yml       # Docker services configuration
+-- README.md                # This file
+-- plan-dbpia-n8n-workflow.md      # Workflow specification
+-- plan-dbpia-openclaw-skills.md   # Agent skill specifications
|
+-- workflows/               # n8n workflow definitions
+-- database/                # Database schemas and migrations
+-- n8n/                     # n8n custom nodes
+-- scripts/                 # Utility scripts
+-- docs/                    # Additional documentation
```

---

## Configuration

### Environment Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| DBPIA_API_KEY | Your DBpia Open API key | - | Yes |
| POSTGRES_HOST | PostgreSQL host | postgres | No |
| POSTGRES_PORT | PostgreSQL port | 5432 | No |
| POSTGRES_DB | Database name | research_papers | No |
| POSTGRES_USER | Database user | n8n_user | No |
| POSTGRES_PASSWORD | Database password | - | Yes |
| N8N_HOST | n8n bind address | 0.0.0.0 | No |
| N8N_PORT | n8n web UI port | 5678 | No |
| N8N_ENCRYPTION_KEY | n8n encryption key (32 chars) | - | Yes |
| LLM_PROVIDER | AI provider | openai | No |
| LLM_API_KEY | LLM API key | - | Yes* |

*Required only for AI relevance scoring

---

## Usage Examples

### Triggering Workflows

#### Via n8n Web UI

Navigate to Workflows, select the desired workflow, and click Execute Workflow

#### Via Webhook (curl)

```bash
# Trigger historical import
curl -X POST http://localhost:5678/webhook/historical-import   -H "Content-Type: application/json"   -d "{\"keyword\": \"deep learning\", \"max_pages\": 10}"

# Search stored papers
curl -X POST http://localhost:5678/webhook/search   -H "Content-Type: application/json"   -d "{\"keyword\": \"transformer\", \"min_score\": 85}"
```

---

## Troubleshooting

### Common Issues

1. **n8n Web UI Not Accessible**: Check `docker compose ps` and `docker compose logs n8n`
2. **DBpia API Rate Limiting**: Increase wait time in workflow (default: 2000ms)
3. **Database Connection Errors**: Verify postgres container is running and test with `docker compose exec postgres psql -U n8n_user -d research_papers -c "SELECT 1;"`
4. **Low Disk Space**: Run `docker system prune -a --volumes` to clean up

### Getting Help

1. n8n Community Forum: https://community.n8n.io
2. DBpia API Documentation: https://www.dbpia.co.kr/api
3. GitHub Issues: https://github.com/holee9/dbpia-n8n-workflow/issues

---

## License

MIT License - see LICENSE file for details.

---

## Contributing

Contributions are welcome\! Please feel free to submit a Pull Request.

## Acknowledgments

- [n8n](https://n8n.io) - The workflow automation platform
- [DBpia](https://www.dbpia.co.kr) - Korean academic database API
- [Raspberry Pi](https://www.raspberrypi.org) - Hardware platform

