# Context Flow Workflow

## How Gemini and Sisyphus Stay in Sync

### The Problem
- Gemini has conversation memory
- Sisyphus starts fresh each CLI invocation
- Need to pass context between them

### The Solution
Gemini acts as the **context manager** (Brain) and passes relevant info to the local executor `Sisyphus - ultraworker` (`sisypus ulw`) via the CLI prompt, using the free model to save tokens.

---

## Workflow

### Step 1: User Asks Gemini Something
```
User: "The navbar looks broken on mobile, fix it"
```

### Step 2: Gemini Gathers Context
Gemini reads relevant files to understand:
- What's wrong
- Which files are involved
- What constraints exist

### Step 3: Gemini Creates Plan WITH Context
```markdown
## Task: Fix navbar mobile layout

### Context
- Current navbar uses flexbox, breaks at 768px
- File: src/components/Navbar.tsx (lines 45-67)
- Must maintain desktop layout

### Files to Modify
- `src/components/Navbar.tsx` - add responsive breakpoints

### Steps
1. Add media query for 768px
2. Stack nav items vertically on mobile
3. Verify: npm run build

### Constraints
- Keep desktop layout unchanged
- Use existing Tailwind classes
```

### Step 4: Gemini Delegates with Full Context (CLI or MCP)
Depending on your configuration:
* **Path A/B (CLI):** Gemini outputs a shell command (using `--json` for Path B to get structured logs):
  ```bash
  /Users/rock/.bun/bin/bun /Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js run --agent Sisyphus --json "Execute this plan: [details]"
  ```
* **Path C (MCP Bridge):** Gemini calls the native MCP tool `opencode_run` directly with the plan prompt.

### Step 5: Sisyphus/OpenCode Executes
- Runs the task locally on the free `opencode/mimo-v2.5-free` model.
- Reads/searches the codebase files and makes the required edits.
- Runs verification tests or build commands and outputs the result (including the `sessionId` / session ID).

### Step 6: Gemini Verifies and Captures Session
Gemini (the Brain) reads the modified files to:
- Confirm changes look correct.
- Extract the session ID from the output/response.
- Maintain conversation context without repeating files the session already knows by resuming (using `-s`, `--session-id`, or `opencode_session_prompt` in future turns).

---

## Rules for Context Passing

### Gemini MUST Include in Plan:
1. **What's wrong** (1 line)
2. **Which files** (with line numbers if relevant)
3. **What constraints** exist
4. **What verification** to run

### Gemini CAN Include:
- Previous attempts that failed
- User preferences mentioned
- Related code context

### Gemini SHOULD NOT Include:
- Full file contents (Sisyphus - ultraworker will read them)
- Implementation details (Sisyphus - ultraworker figures those out)
- Multiple options (pick one)

---

## Example Conversations

### Example 1: Bug Fix (Path A - Simple Task)
```
User: "Fix the typos in the index.html page"

Gemini:
1. Reads index.html
2. Finds simple spelling typos (e.g. "comming soon" -> "coming soon")
3. Brain decides this is a **Simple Task** (Path A)
4. Creates a 5-line plan and delegates to plain `opencode` with Mimo-v2.5-free:
   opencode run -m opencode/mimo-v2.5-free "Execute this plan: Fix spelling in index.html"
5. Plain OpenCode runs and completes, returning session ID "ses_simple_123"
6. Gemini reads files to verify
7. User asks follow-up: "Change 'coming soon' to 'available soon'"
8. Gemini resumes plain session:
   opencode run -s ses_simple_123 "Continue: change 'coming soon' to 'available soon'"
9. Gemini verifies and completes
```

### Example 2: Feature Request (with Session Resumption)
```
User: "Add a search bar to the header"

Gemini:
1. Reads src/components/Header.tsx
2. Checks existing search components
3. Creates plan
4. Delegates to Sisyphus with --json:
   /Users/rock/.bun/bin/bun .../oh-my-opencode.js run --agent Sisyphus --json "Execute this plan: Add search bar to header"
5. Sisyphus executes and returns JSON with sessionId "ses_123"
6. Gemini verifies changes
7. User asks: "Can you make it search as you type?"
8. Gemini resumes the session:
   /Users/rock/.bun/bin/bun .../oh-my-opencode.js run --session-id ses_123 "Continue plan: add debounce to search input"
9. Sisyphus executes inside the same session (saves tokens)
10. Gemini verifies and completes
```

### Example 3: Multi-Task Context (Sequential Resumption)
```
User: "Refactor the auth module and add OAuth"

Gemini:
1. Reads auth module
2. Creates Plan 1: Refactor auth
3. Delegates to Sisyphus with --json
4. Sisyphus executes refactor, returns sessionId "ses_456"
5. Gemini verifies refactor
6. Creates Plan 2: Add OAuth (runs on top of ses_456)
7. Delegates using --session-id ses_456 "Continue plan: Add OAuth support"
8. Sisyphus executes on the resumed session
9. Gemini verifies OAuth addition
```

### Example 4: Native MCP Bridge (Path C)
```
User: "Create a simple card component in src/components/Card.tsx"

Gemini:
1. Brain plans creation of Card.tsx
2. Brain calls MCP tool `opencode_run` with the plan prompt (using free model)
3. User approves tool execution in the IDE pop-up
4. OpenCode executes the card creation and returns a sessionId "ses_mcp_789"
5. Gemini reads files to verify
6. User asks follow-up: "Add hover scale animations to it"
7. Gemini resumes the session by calling `opencode_session_prompt` with sessionId="ses_mcp_789" and the hover prompt.
8. Gemini verifies and completes
```

---

## Token Efficiency

| Approach | Tokens | Context Quality |
|----------|--------|-----------------|
| Load everything | ~5000 | High but wasteful |
| Relay only | ~50 | Low, no context |
| **Smart Planning + CLI Session ID (Path A/B)** | ~100-200 | High, extremely efficient (0 system prompt overhead) |
| **Smart Planning + MCP Bridge (Path C)** | ~500-600 | High, efficient (adds ~420 tokens system prompt overhead) |

The key: Gemini reads files SELECTIVELY, passes ONLY relevant context in the first plan, and resumes using the session ID for subsequent turns to prevent the executor from re-analyzing the codebase.
