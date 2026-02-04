# PROMPT: Build n8n Workflow for DBpia Automation

## 1. System Requirements
- **Goal:** Create an n8n workflow to automate the retrieval, filtering, and storage of academic papers from the DBpia Open API.
- **Environment:** Self-hosted n8n instance (Docker).
- **Database:** PostgreSQL (Schema: `research_papers`).
- **External API:** DBpia Open API (Search & New Arrivals).

## 2. Workflow Logic Architecture

### Track A: Historical Data Ingestion (Bulk)
- **Mechanism:** Recursive Pagination Loop.
- **Process:**
  1. **Start:** Input specific keywords (e.g., via `Set` node).
  2. **API Call:** Fetch XML/JSON data with `page` and `count=50` parameters.
  3. **Code Node (Logic):** - Check `total_count` vs `current_count`.
     - Return `next_page` index if data remains.
     - Stop execution if complete.
  4. **Data Standardizing:** Convert XML to standardized JSON array.

### Track B: Incremental Updates (Daily Sync)
- **Trigger:** `Cron/Schedule` Node (Every 24h).
- **Logic:** Fetch newly arrived papers based on date sorting.
- **Deduplication:** - Compare fetched `DOI` or `ArticleID` against the PostgreSQL database.
  - **Filter:** Discard items that return `TRUE` on `SELECT exists(...)`.

### Track C: AI Relevance Scoring
- **Input:** Title + Abstract of non-duplicate items.
- **AI Processing (LLM Node):**
  - **Role:** Academic Curator.
  - **Task:** 1. Score relevance (0-100) based on input keywords.
    2. Generate a 1-sentence technical summary.
    3. Output format: JSON `{ "score": number, "summary": "string", "category": "string" }`.
- **Filtering:** Use `If` node to discard items with Score < 80.

## 3. Implementation Details for Generation
Please generate the JSON code for the n8n workflow or detailed JavaScript for the Function Nodes focusing on:
1. **Handling XML Responses:** Parsing logic for DBpia's specific XML structure.
2. **Rate Limiting:** Implementing a `Wait` function (2000ms) to prevent API bans.
3. **Database Schema:** SQL for creating the `research_papers` table including columns for `doi`, `title`, `abstract`, `relevance_score`, `published_date`, and `url`.