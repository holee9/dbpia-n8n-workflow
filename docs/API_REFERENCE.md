# DBpia API Reference

This document provides reference information for integrating with the DBpia API in n8n workflows.

## Base URL

```
https://api.dbpia.co.kr
```

## Authentication

Include your API key in the request header:

```http
Authorization: Bearer YOUR_API_KEY
```

## Endpoints

### Search Articles

**Endpoint:** `GET /search`

**Query Parameters:**
- query: Search keywords (required)
- field: Search field - title, author, journal, all (optional)
- page: Page number (default: 1)
- size: Results per page (default: 20, max: 100)
- sort: Sort order - date, relevance, citation (optional)
- year_from: Filter by publication year from (optional)
- year_to: Filter by publication year to (optional)

**Example:**
```bash
curl -H "Authorization: Bearer YOUR_KEY" \
  "https://api.dbpia.co.kr/search?query=machine+learning&page=1&size=20"
```

### Get Article Details

**Endpoint:** `GET /article/{article_id}`

Returns detailed information about a specific article including abstract, references, and citation count.

## Rate Limits

| Plan | Requests/Hour | Requests/Day |
|------|---------------|--------------|
| Free | 100 | 1,000 |
| Basic | 500 | 5,000 |
| Pro | 2,000 | 20,000 |

## n8n Integration

### HTTP Request Node

```json
{
  "method": "GET",
  "url": "https://api.dbpia.co.kr/search",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "queryParameters": {
    "query": "={{ $json.search_term }}",
    "page": "={{ $json.page || 1 }}",
    "size": "20"
  }
}
```

### Processing Results

Function node to transform API response:

```javascript
const articles = $input.all().map(item => ({
  json: {
    article_id: item.json.id,
    title: item.json.title,
    authors: item.json.authors.join(', '),
    year: item.json.year,
    journal: item.json.journal,
    doi: item.json.doi
  }
}));
return articles;
```
