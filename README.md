# Sisyphus Orchestrator Template (Gemini Planner + Sisyphus Executor)

## Architecture

```
You ←→ Gemini (Memory + Context) ←→ Sisyphus (Executor) ←→ Your Code
```

- **Gemini (Brain)**: Remembers conversation, reads files, creates plans with context, orchestrates the workflow.
- **Sisyphus - ultraworker (sisypus ulw)**: Stateless local executor, runs locally on the free `opencode/mimo-v2.5-free` model to maximize token savings. Required for all code modification steps.

## How Context Flows

```
┌─────────────────────────────────────────────────────────┐
│  Gemini (Antigravity IDE)                               │
│  - Has FULL conversation memory                         │
│  - Can read any file in workspace                       │
│  - Remembers what you asked, what Sisyphus did          │
│  - Passes context to Sisyphus via plan                  │
└──────────────────────┬──────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │  Context flows via:         │
        │  1. Plan's Context section  │
        │  2. Gemini reads files      │
        │  3. Follow-up questions     │
        └──────────────┬──────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Sisyphus - ultraworker (CLI)                           │
│  - Fresh session each time                              │
│  - Gets context ONLY from plan                          │
│  - Executes on the free model (saves tokens)            │
└─────────────────────────────────────────────────────────┘
```

## Setup

1. Copy `.cursorrules` to your project root
2. Ensure oh-my-openagent is installed (run `setup.sh` to verify)
3. Use Gemini Flash 3.5 as your IDE model

## How It Works

1. You tell Gemini what you want
2. Gemini reads relevant files to understand context
3. Gemini creates a SHORT plan (10 lines max) WITH context section
4. Gemini runs: `bun oh-my-opencode.js run --agent Sisyphus "Execute this plan: [plan]"` (resolving to `Sisyphus - ultraworker`)
5. Sisyphus - ultraworker executes the plan locally using the free model `opencode/mimo-v2.5-free` (maximizing token savings)
6. Gemini reads modified files to verify
7. You can ask follow-up questions (Gemini remembers everything)

## Token Usage

| Approach | Tokens per Task |
|----------|-----------------|
| Full analysis (old) | ~2000-5000 |
| Relay only | ~50-100 |
| **Planner with context** | ~150-250 |

## Plan Format (with Context)

```markdown
## Task: [one line description]

### Context
- [what's wrong or what needs to happen]
- [relevant line numbers or file state]
- [previous attempts if any]

### Files to Modify
- `path/to/file.ts` - [what change]

### Steps
1. [action] in [file]
2. Verify: [command]

### Constraints
- [key constraint]
```

**Key**: MAX 12 lines. Include context section. No code snippets.

## Files

- `.cursorrules` - Planning rules with context passing
- `gemini.md` - Rules for the Gemini planner to enforce ultraworker delegation and save tokens
- `planning-template.md` - Quick reference for plan format
- `context-workflow.md` - Detailed context flow explanation
- `setup.sh` - Environment verification (optional)

## Example Conversation

```
You: "The navbar looks broken on mobile"

Gemini:
1. Reads src/components/Navbar.tsx
2. Finds flexbox breaks at 768px
3. Creates plan with context:
   ## Task: Fix navbar mobile layout
   ### Context
   - flexbox breaks at 768px (line 45)
   - must keep desktop layout
   ### Files to Modify
   - src/components/Navbar.tsx - add responsive breakpoints
   ### Steps
   1. Add media query for 768px
   2. Verify: npm run build
   ### Constraints
   - Keep desktop layout unchanged

4. Delegates to Sisyphus
5. Verifies result

You: "Can you make it slide in from the left?"

Gemini:
1. Remembers previous fix
2. Creates new plan with context about the change
3. Delegates to Sisyphus
```

**Key insight**: You talk to Gemini naturally. Gemini handles context. Sisyphus just executes.
