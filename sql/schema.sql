-- ============================================================================
-- DBpia Research Papers Database Schema
-- PostgreSQL 15
-- ============================================================================

-- Drop existing table if exists (for clean re-deployment)
DROP TABLE IF EXISTS public.research_papers CASCADE;

-- ============================================================================
-- Research Papers Table
-- ============================================================================
CREATE TABLE public.research_papers (
    -- Primary Key
    id SERIAL PRIMARY KEY,

    -- Core identifiers
    doi VARCHAR(255) UNIQUE,
    url TEXT,

    -- Paper metadata
    title TEXT NOT NULL,
    abstract TEXT,
    authors JSONB DEFAULT '[]'::jsonb,

    -- Publication info
    published_date DATE,

    -- Relevance and AI analysis
    relevance_score INTEGER CHECK (relevance_score >= 0 AND relevance_score <= 100),
    ai_summary TEXT,
    category VARCHAR(100),

    -- Keywords array
    keywords TEXT[] DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- Indexes for Performance Optimization
-- ============================================================================

-- Unique index on DOI (already enforced by UNIQUE constraint, explicit index for query planning)
CREATE UNIQUE INDEX idx_research_papers_doi ON public.research_papers(doi) WHERE doi IS NOT NULL;

-- GIN index on title for full-text search
CREATE INDEX idx_research_papers_title_gin ON public.research_papers USING GIN (to_tsvector('english', title));

-- GIN index on authors for JSONB queries
CREATE INDEX idx_research_papers_authors_gin ON public.research_papers USING GIN (authors);

-- Index on relevance_score for filtering high-relevance papers
CREATE INDEX idx_research_papers_relevance_score ON public.research_papers(relevance_score) WHERE relevance_score >= 80;

-- Index on published_date for chronological queries
CREATE INDEX idx_research_papers_published_date ON public.research_papers(published_date DESC);

-- GIN index on keywords array for array containment queries
CREATE INDEX idx_research_papers_keywords_gin ON public.research_papers USING GIN (keywords);

-- Composite index for category and relevance_score (common query pattern)
CREATE INDEX idx_research_papers_category_relevance ON public.research_papers(category, relevance_score DESC);

-- ============================================================================
-- Update Timestamp Trigger Function
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Trigger: Auto-update updated_at on row modification
-- ============================================================================
CREATE TRIGGER trg_research_papers_updated_at
    BEFORE UPDATE ON public.research_papers
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- Comments for Documentation
-- ============================================================================
COMMENT ON TABLE public.research_papers IS 'Stores research paper metadata from DBpia with AI relevance scoring';
COMMENT ON COLUMN public.research_papers.id IS 'Auto-incrementing primary key';
COMMENT ON COLUMN public.research_papers.doi IS 'Digital Object Identifier - unique paper identifier';
COMMENT ON COLUMN public.research_papers.title IS 'Paper title (required)';
COMMENT ON COLUMN public.research_papers.abstract IS 'Paper abstract text';
COMMENT ON COLUMN public.research_papers.authors IS 'Authors stored as JSONB array of objects with name, affiliation, etc.';
COMMENT ON COLUMN public.research_papers.published_date IS 'Publication date';
COMMENT ON COLUMN public.research_papers.relevance_score IS 'AI-calculated relevance score (0-100)';
COMMENT ON COLUMN public.research_papers.ai_summary IS 'AI-generated one-sentence summary';
COMMENT ON COLUMN public.research_papers.category IS 'Paper category assigned by AI (e.g., ML, NLP, CV, etc.)';
COMMENT ON COLUMN public.research_papers.url IS 'Full URL to the paper on DBpia';
COMMENT ON COLUMN public.research_papers.keywords IS 'Array of keyword tags';
COMMENT ON COLUMN public.research_papers.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.research_papers.updated_at IS 'Last update timestamp (auto-updated)';

-- ============================================================================
-- Sample Upsert Function for n8n Integration
-- ============================================================================
CREATE OR REPLACE FUNCTION public.upsert_research_paper(
    p_doi VARCHAR(255),
    p_title TEXT,
    p_abstract TEXT DEFAULT NULL,
    p_authors JSONB DEFAULT '[]'::jsonb,
    p_published_date DATE DEFAULT NULL,
    p_relevance_score INTEGER DEFAULT NULL,
    p_ai_summary TEXT DEFAULT NULL,
    p_category VARCHAR(100) DEFAULT NULL,
    p_url TEXT DEFAULT NULL,
    p_keywords TEXT[] DEFAULT '{}'
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO public.research_papers (
        doi, title, abstract, authors, published_date,
        relevance_score, ai_summary, category, url, keywords
    )
    VALUES (
        p_doi, p_title, p_abstract, p_authors, p_published_date,
        p_relevance_score, p_ai_summary, p_category, p_url, p_keywords
    )
    ON CONFLICT (doi) DO UPDATE SET
        title = EXCLUDED.title,
        abstract = COALESCE(EXCLUDED.abstract, research_papers.abstract),
        authors = COALESCE(EXCLUDED.authors, research_papers.authors),
        published_date = COALESCE(EXCLUDED.published_date, research_papers.published_date),
        relevance_score = COALESCE(EXCLUDED.relevance_score, research_papers.relevance_score),
        ai_summary = COALESCE(EXCLUDED.ai_summary, research_papers.ai_summary),
        category = COALESCE(EXCLUDED.category, research_papers.category),
        url = COALESCE(EXCLUDED.url, research_papers.url),
        keywords = COALESCE(EXCLUDED.keywords, research_papers.keywords),
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.upsert_research_paper IS 'Upsert function for research papers - inserts new or updates existing based on DOI';
