# Memory System

This directory contains the collective memory of the DBpia n8n workflow project, tracking errors, decisions, tasks, and learnings to prevent repeated mistakes and preserve institutional knowledge.

## Purpose

The `/memory` folder serves as:

1. **Error Tracking** - Document mistakes and their solutions to avoid recurrence
2. **Decision Log** - Record architectural and technical decisions with rationale
3. **Task Management** - Track active tasks for session recovery
4. **Knowledge Base** - Capture learnings and insights for team reference

## ⚠️ MANDATORY: Memory-First Workflow

**BEFORE starting ANY work:**

```
1. CHECK memory/errors/    → Look for related errors and solutions
2. CHECK memory/decisions/ → Look for architectural decisions
3. CHECK memory/learnings/ → Look for relevant knowledge
4. CHECK memory/tasks/active/ → Look for incomplete tasks
5. CREATE task record     → Register your work in memory/tasks/active/
6. APPLY prevention       → Use known solutions before starting
```

This workflow ensures:
- Work can be resumed after session interruption
- Errors are not repeated
- Knowledge accumulates over time

## Directory Structure

```
memory/
├── errors/              # Mistakes, failures, and how they were resolved
│   ├── error-template.md
│   └── YYYY-MM-DD-title.md
├── decisions/           # Architectural and technical decisions
│   ├── decision-template.md
│   └── YYYY-MM-DD-title.md
├── tasks/               # Active and completed task records
│   ├── active/          # Currently in-progress tasks
│   ├── completed/       # Finished tasks
│   └── template.md      # Task record template
├── learnings/           # Knowledge gained and best practices
│   ├── learning-template.md
│   └── YYYY-MM-DD-title.md
└── README.md            # This file
```

## Naming Convention

All entries should follow the format: `YYYY-MM-DD-title.md`

- **YYYY-MM-DD**: Date of creation
- **title**: Short, descriptive kebab-case title

Examples:
- `2026-02-04-hook-file-missing.md`
- `2026-02-04-workflow-resume.md`
- `2026-02-04-shebang-escape-sequence.md`

## Templates

Each category has a template file:

- `errors/error-template.md` - Use for documenting any error or failure
- `decisions/decision-template.md` - Use for recording technical decisions
- `tasks/template.md` - **REQUIRED** - Use for ALL task registration
- `learnings/learning-template.md` - Use for capturing new knowledge

## How to Use

### Creating a Task (REQUIRED Before Work)

1. Copy `tasks/template.md` to `tasks/active/TASK-YYYY-MM-DD-title.md`
2. Fill in the task description and dependencies
3. Link to related errors, decisions, and learnings
4. Update the status as you progress
5. Move to `tasks/completed/` when done

### Documenting an Error

1. Copy `errors/error-template.md` to `errors/YYYY-MM-DD-title.md`
2. Include exact error message and root cause
3. Document step-by-step solution
4. Add prevention measures

### Recording a Decision

1. Copy `decisions/decision-template.md` to `decisions/YYYY-MM-DD-title.md`
2. Describe context and options considered
3. Document the decision and rationale
4. Note consequences

### Capturing a Learning

1. Copy `learnings/learning-template.md` to `learnings/YYYY-MM-DD-title.md`
2. Describe what was learned
3. Explain how to apply it
4. Link to related resources

## Session Recovery

If your session is interrupted:

```bash
# 1. Check active tasks
ls memory/tasks/active/

# 2. Read your task record
cat memory/tasks/active/TASK-YYYY-MM-DD-title.md

# 3. Review "Next Steps" section
# 4. Continue from where you left off
# 5. Update "Work Log" as you progress
```

## When to Document

**Errors:**
- Any bug that took more than 30 minutes to resolve
- Production incidents
- Recurring issues
- Configuration problems
- Hook failures, file operation errors

**Decisions:**
- Architecture changes
- Technology selections
- API design choices
- Data modeling decisions
- Workflow process changes

**Tasks:**
- ALL work tasks (REQUIRED)
- Multi-step implementations
- Feature development
- Bug fixes
- Documentation updates

**Learnings:**
- New patterns discovered
- Best practices identified
- Tool or framework insights
- Performance optimizations

## Review Process

1. **Pre-Work** - Check memory before starting any task
2. **During Work** - Update task record as you progress
3. **On Error** - Document immediately in errors/
4. **On Completion** - Move task to completed/, update if needed

## Search Tags

Common tags to use:

**Errors:**
- `#error` `#api` `#database` `#deployment` `#auth` `#n8n` `#integration` `#hook` `#file`

**Decisions:**
- `#decision` `#architecture` `#database` `#api` `#security` `#performance` `#workflow`

**Tasks:**
- `#task` `#feature` `#fix` `#docs` `#refactor` `#in-progress`

**Learnings:**
- `#learning` `#pattern` `#best-practice` `#n8n` `#workflow` `#automation`

## Related Files

- `../RULES.md` - Project rules and MANDATORY pre-work checklist
- `../docs/BRIEFING.md` - Project briefing and status
