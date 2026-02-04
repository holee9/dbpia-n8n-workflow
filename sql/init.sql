-- ============================================================================
-- DBpia Database Initialization Script
-- PostgreSQL 15
-- ============================================================================

-- Exit on error (when using psql -v ON_ERROR_STOP=1)
-- Usage: psql -v ON_ERROR_STOP=1 -U postgres -d postgres -f init.sql

-- ============================================================================
-- Database Creation
-- ============================================================================
DO $$
BEGIN
    -- Create database if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dbpia') THEN
        CREATE DATABASE dbpia
            WITH
            OWNER = postgres
            ENCODING = 'UTF8'
            LC_COLLATE = 'en_US.UTF-8'
            LC_CTYPE = 'en_US.UTF-8'
            TABLESPACE = pg_default
            CONNECTION LIMIT = -1;
        RAISE NOTICE 'Database "dbpia" created successfully.';
    ELSE
        RAISE NOTICE 'Database "dbpia" already exists.';
    END IF;
END
$$;

-- ============================================================================
-- User Creation and Permissions
-- ============================================================================
DO $$
BEGIN
    -- Create application user if it doesn't exist
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'dbpia_user') THEN
        CREATE USER dbpia_user WITH
            ENCRYPTED PASSWORD 'CHANGE_ME_SECURE_PASSWORD'
            LOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE;
        RAISE NOTICE 'User "dbpia_user" created successfully. Please change the default password!';
    ELSE
        RAISE NOTICE 'User "dbpia_user" already exists.';
    END IF;
END
$$;

-- ============================================================================
-- Connect to dbpia database and grant permissions
-- \c dbpia

-- ============================================================================
-- Grant Schema Permissions
-- ============================================================================
GRANT USAGE ON SCHEMA public TO dbpia_user;
GRANT CREATE ON SCHEMA public TO dbpia_user;

-- ============================================================================
-- Grant permissions on existing and future tables
-- ============================================================================
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dbpia_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO dbpia_user;

-- ============================================================================
-- Grant function execution permissions
-- %%
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO dbpia_user;

-- ============================================================================
-- Extension Installation
-- ============================================================================
-- Required extensions for JSON operations and full-text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- For trigram-based text search
CREATE EXTENSION IF NOT EXISTS btree_gin;  -- For GIN indexes on scalar types

-- ============================================================================
-- Import Schema
-- ============================================================================
-- Run the schema.sql file to create tables and indexes
\ir schema.sql

-- ============================================================================
-- Final Permissions Grant on research_papers table
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.research_papers TO dbpia_user;
GRANT USAGE, SELECT ON SEQUENCE public.research_papers_id_seq TO dbpia_user;
GRANT EXECUTE ON FUNCTION public.upsert_research_paper TO dbpia_user;
GRANT EXECUTE ON FUNCTION public.update_updated_at_column TO dbpia_user;

-- ============================================================================
-- Configuration Summary
-- ============================================================================
SELECT
    'Database Initialization Complete' AS status,
    current_database() AS database_name,
    current_user AS current_user,
    version() AS postgresql_version;

-- ============================================================================
-- Setup Instructions
-- ============================================================================
/*
POST-INSTALLATION STEPS:

1. CHANGE DEFAULT PASSWORD:
   ALTER USER dbpia_user WITH ENCRYPTED PASSWORD 'your_secure_password';

2. CREATE READ-ONLY USER (optional):
   CREATE USER dbpia_readonly WITH ENCRYPTED PASSWORD 'readonly_password';
   GRANT CONNECT ON DATABASE dbpia TO dbpia_readonly;
   GRANT USAGE ON SCHEMA public TO dbpia_readonly;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO dbpia_readonly;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dbpia_readonly;

3. BACKUP STRATEGY:
   - Daily backups: pg_dump -U postgres dbpia > backup_$(date +%Y%m%d).sql
   - Automated via cron: 0 2 * * * pg_dump -U postgres dbpia > /backups/dbpia_$(date +\%Y\%m\%d).sql

4. CONNECTION STRING FOR n8n:
   postgresql://dbpia_user:password@localhost:5432/dbpia?sslmode=prefer

5. VERIFY SETUP:
   SELECT COUNT(*) FROM research_papers;  -- Should return 0
   SELECT * FROM pg_tables WHERE schemaname = 'public';  -- List all tables
*/
