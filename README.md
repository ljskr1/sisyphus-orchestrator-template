# Sisyphus Orchestrator Template (Gemini Planner + Sisyphus/OpenCode Executor)

## Architecture

```
You ←→ Gemini (Memory/Context Planner) ←→ Plain OpenCode (Path A) or Sisyphus (Path B) or Native MCP Bridge (Path C) ←→ Your Code
```

- **Gemini (Brain)**: Remembers conversation, reads files, creates plans, and dynamically routes tasks based on complexity.
- **Plain OpenCode (Path A)**: Handles formatting, comments, docs, or simple single-line edits using the free model `opencode/mimo-v2.5-free`.
- **Sisyphus - ultraworker (Path B)**: Stateless local executor, handles complex tasks (multi-file logic, refactoring, algorithms) on the free model.
- **Native MCP Bridge (Path C)**: IDE-integrated execution via native MCP tools (`opencode_run`, `opencode_session_create`, `opencode_session_prompt`), handles mid-complexity tasks directly in the IDE.

## How Context Flows

```
┌─────────────────────────────────────────────────────────┐
│  Gemini (Antigravity IDE)                               │
│  - Has FULL conversation memory                         │
│  - Can read any file in workspace                       │
│  - Decides on Path A (OpenCode) vs Path B (Sisyphus)    │
│  - Passes context via plan                              │
└──────────────────────┬──────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │  Context flows via:         │
        │  1. Plan's Context section  │
        │  2. Session resumption (-s/--session-id)        │
        └──────────────┬──────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Local Executor (Plain OpenCode or Sisyphus)             │
│  - Resumes session using session ID to save tokens       │
│  - Executes on the free model (saves tokens)            │
└─────────────────────────────────────────────────────────┘
```

## Setup

1. Copy `.cursorrules` to your project root (or run `omo-init` in your terminal).
2. Ensure oh-my-openagent is installed (run `setup.sh` to verify).
3. Use Gemini Flash 3.5 as your IDE model.

## How It Works

1. You tell Gemini what you want.
2. Gemini reads relevant files to understand context.
3. Gemini creates a SHORT plan (10 lines max) WITH context.
4. Gemini decides on the path:
   * **Path A (Simple):** Invokes plain `opencode run -m opencode/mimo-v2.5-free`. Resumes using `opencode run -s <session_id>`.
   * **Path B (Complex):** Invokes `oh-my-opencode.js run --agent Sisyphus --json`. Resumes using `--session-id <session_id>`.
   * **Path C (MCP Bridge):** Invokes `opencode_run` or `opencode_session_create` MCP tools with `model: "opencode/mimo-v2.5-free"`. Resumes using `opencode_session_prompt` with `session_id`.
5. The executor runs the plan locally using the free model (maximizing token savings).
6. Gemini reads modified files to verify.
7. You can ask follow-up questions (Gemini resumes the session ID to save tokens).

## Token Usage

| Approach | Tokens per Task | Notes |
|----------|-----------------|-------|
| Full analysis (old) | ~2000-5000 | Brain analyzes everything |
| Relay only | ~50-100 | Minimal delegation |
| **Path A/B (CLI)** | ~100-200 | Most token-efficient; CLI runs directly without IDE tool definitions |
| **Path C (MCP Bridge)** | ~500-600 | IDE tool definitions overhead (~420 tokens) adds to each task |

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
- `uninstall.sh` - Removes components installed by setup-antigravity-opencode.sh
- `mcp-bridge-config.json` - MCP Bridge configuration for Path C
- `setup-mcp-bridge.sh` - Automates bridge installation, config copying, and daemon startup

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
