# Memory System

This directory contains the collective memory of the DBpia n8n workflow project, tracking errors, decisions, and learnings to prevent repeated mistakes and preserve institutional knowledge.

## Purpose

The `/memory` folder serves as:

1. **Error Tracking** - Document mistakes and their solutions to avoid recurrence
2. **Decision Log** - Record architectural and technical decisions with rationale
3. **Knowledge Base** - Capture learnings and insights for team reference

## Directory Structure

```
memory/
├── errors/          # Mistakes, failures, and how they were resolved
├── decisions/       # Architectural and technical decisions
├── learnings/       # Knowledge gained and best practices discovered
└── README.md        # This file
```

## Naming Convention

All entries should follow the format: `YYYY-MM-DD-title.md`

- **YYYY-MM-DD**: Date of creation
- **title**: Short, descriptive kebab-case title

Examples:
- `2024-02-04-api-rate-limiting-fix.md`
- `2024-02-04-postgres-vs-mongodb.md`
- `2024-02-04-n8n-webhook-patterns.md`

## Templates

Each category has a template file:

- `errors/error-template.md` - Use for documenting any error or failure
- `decisions/decision-template.md` - Use for recording technical decisions
- `learnings/learning-template.md` - Use for capturing new knowledge

## How to Use

### Creating a New Entry

1. Copy the appropriate template to a new file with proper naming
2. Fill in all relevant sections
3. Use tags at the bottom for easy searching
4. Commit the file with a descriptive message

### When to Document

**Errors:**
- Any bug that took more than 30 minutes to resolve
- Production incidents
- Recurring issues
- Configuration problems

**Decisions:**
- Architecture changes
- Technology selections
- API design choices
- Data modeling decisions

**Learnings:**
- New patterns discovered
- Best practices identified
- Tool or framework insights
- Performance optimizations

## Review Process

1. **Weekly Review** - Scan new entries during team sync
2. **Monthly Cleanup** - Archive outdated entries
3. **Quarterly Summary** - Create summary documents of key learnings

## Search Tags

Common tags to use:

**Errors:**
- `#error` `#api` `#database` `#deployment` `#auth` `#n8n` `#integration`

**Decisions:**
- `#decision` `#architecture` `#database` `#api` `#security` `#performance`

**Learnings:**
- `#learning` `#pattern` `#best-practice` `#n8n` `#workflow` `#automation`

## Related Files

- `../RULES.md` - Project rules and pre-commit checklist
- `.claude/CLAUDE.md` - Project-specific AI assistant context
