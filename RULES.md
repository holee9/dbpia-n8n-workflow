# Project Rules - DBpia n8n Workflow

This document contains rules and guidelines for preventing repeated mistakes and maintaining code quality.

## ⚠️ MANDATORY: Pre-Work Checklist

**BEFORE starting ANY task, you MUST complete this checklist:**

### 1. Memory Check (REQUIRED)

- [ ] **Read `memory/errors/`** - Check for related errors and their solutions
- [ ] **Read `memory/decisions/`** - Check for architectural decisions
- [ ] **Read `memory/learnings/`** - Check for relevant knowledge
- [ ] **Read `memory/tasks/active/`** - Check for incomplete related tasks

### 2. Task Registration (REQUIRED)

- [ ] **Create task record** in `memory/tasks/active/` using template
- [ ] **Link to related errors** - Reference any relevant error entries
- [ ] **Link to related decisions** - Reference any relevant decisions
- [ ] **Document dependencies** - List prerequisites

### 3. Prevention Review (REQUIRED)

- [ ] **Apply known solutions** - From related error entries
- [ ] **Follow architectural decisions** - From related decision entries
- [ ] **Use established patterns** - From related learning entries

### 4. Session Context

```
WHEN resuming work after interruption:
  1. Check memory/tasks/active/ for your incomplete task
  2. Review the Work Log section
  3. Continue from "Next Steps"
  4. Update status as you progress
```

### Why This Matters

| Without Memory-First | With Memory-First |
|---------------------|-------------------|
| Repeated errors | Learn from past mistakes |
| Lost context on interrupt | Resume anywhere |
| No work trail | Full audit history |
| Siloed knowledge | Shared learning |

---


## Core Principles

1. **Document First** - Create memory entries before implementing fixes
2. **Test Locally** - Validate changes before committing
3. **Review Carefully** - Check all related files before pushing
4. **Communicate** - Share learnings with the team

## Pre-Commit Checklist

Before committing any changes, verify:

### Code Quality
- [ ] Code follows existing style patterns
- [ ] No hardcoded values (use environment variables)
- [ ] Error handling is implemented
- [ ] Logging is appropriate (not too much, not too little)
- [ ] Comments explain "why", not "what"

### Testing
- [ ] Tested locally with realistic data
- [ ] Edge cases considered and handled
- [ ] API calls handle failures gracefully
- [ ] Timeouts are configured appropriately

### Documentation
- [ ] Memory entry created for any errors encountered
- [ ] Decision log updated for architectural changes
- [ ] README updated if user-facing changes

### Security
- [ ] No credentials in code
- [ ] API keys stored in environment variables
- [ ] Sensitive data not logged
- [ ] Rate limiting considered

## Error Reporting Guidelines

### When to Create an Error Entry

Create an entry in `memory/errors/` when:

1. An error takes more than **30 minutes** to resolve
2. A **production issue** occurs
3. An error is **recurring**
4. The solution involves **multiple steps** or files

### Error Entry Format

1. Use the template: `memory/errors/error-template.md`
2. Name file: `YYYY-MM-DD-short-description.md`
3. Include:
   - Exact error message
   - Root cause analysis
   - Step-by-step solution
   - Prevention measures
   - Related files

### Common Mistakes to Avoid

#### API Integration
```bash
# DON'T - Hardcode credentials
const apiKey = "sk-1234567890";

# DO - Use environment variables
const apiKey = process.env.DBPIA_API_KEY;
```

#### Error Handling
```bash
# DON'T - Silent failures
try {
  await apiCall();
} catch (e) {
  // do nothing
}

# DO - Log and handle errors
try {
  await apiCall();
} catch (e) {
  console.error('API call failed:', e.message);
  throw new Error(`Failed to fetch data: ${e.message}`);
}
```

#### Timeouts
```bash
# DON'T - No timeout on long operations
const response = await fetch(url);

# DO - Always set timeouts
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 30000);
const response = await fetch(url, { signal: controller.signal });
clearTimeout(timeout);
```

#### Rate Limiting
```bash
# DON'T - Fire requests without rate limiting
for (const item of items) {
  await api.call(item);
}

# DO - Implement rate limiting
for (const item of items) {
  await api.call(item);
  await delay(350); // Respect rate limits
}
```

## Workflow-Specific Rules

### n8n Workflows

1. **Naming**: Use kebab-case for workflow names
   - Example: `search-papers-by-keyword`, `download-paper-pdf`

2. **Webhooks**: Always include:
   - Input validation node
   - Error handling workflow
   - Response webhook URL

3. **Credentials**: Store in n8n credentials manager, never in workflow JSON

4. **Version Control**: Export workflows to `workflows/` directory after changes

### API Client

1. **Retry Logic**: Implement exponential backoff for failed requests
2. **Session Management**: Reuse sessions when possible
3. **User Agent**: Identify your application appropriately

### File Storage

1. **Naming**: Use consistent file naming (e.g., `{paper-id}.pdf`)
2. **Cleanup**: Implement periodic cleanup of temporary files
3. **Validation**: Verify file integrity after download

## Git Conventions

### Commit Messages

Follow conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `refactor` - Code refactoring
- `test` - Adding tests
- `chore` - Maintenance tasks

Examples:
```
feat(api): add retry logic with exponential backoff
fix(workflow): resolve webhook timeout issue
docs(readme): update setup instructions for n8n
```

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

## Review Process

1. **Self-Review** - Review your own changes first
2. **Memory Check** - Check if similar errors were documented before
3. **Test** - Run relevant tests
4. **Document** - Update memory entries if needed

## Emergency Procedures

### Production Issues

1. **Assess** - Determine severity and scope
2. **Communicate** - Notify stakeholders if user-facing
3. **Document** - Create error entry immediately
4. **Fix** - Implement fix following prevention measures
5. **Review** - Post-mortem to prevent recurrence

### Rollback Procedure

1. Identify last known good commit
2. Rollback n8n workflows from `workflows/` directory
3. Restore environment variables if needed
4. Verify functionality
5. Document root cause

## Learning Resources

- n8n Documentation: https://docs.n8n.io
- DBpia API: (internal documentation)
- Project Memory: `memory/learnings/`

---

**Remember**: Every mistake is an opportunity to learn and improve the system. Document it, learn from it, and prevent it from happening again.
