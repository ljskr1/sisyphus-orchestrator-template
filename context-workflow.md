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

### Step 4: Gemini Delegates with Full Context
```bash
bun oh-my-opencode.js run --agent Sisyphus "Execute this plan:

## Task: Fix navbar mobile layout

### Context
- Current navbar uses flexbox, breaks at 768px
- File: src/components/Navbar.tsx (lines 45-67)
- Must maintain desktop layout

### Files to Modify
- src/components/Navbar.tsx - add responsive breakpoints

### Steps
1. Add media query for 768px
2. Stack nav items vertically on mobile
3. Verify: npm run build

### Constraints
- Keep desktop layout unchanged
- Use existing Tailwind classes"
```

### Step 5: Sisyphus - ultraworker Executes
- Sisyphus - ultraworker runs on the free `opencode/mimo-v2.5-free` model (saving tokens)
- Reads the files
- Makes the changes
- Runs verification
- Returns output

### Step 6: Gemini Verifies and Continues
Gemini (the Brain) reads the modified files to:
- Confirm changes look correct
- Answer follow-up questions
- Maintain conversation context

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

### Example 1: Bug Fix
```
User: "The login button doesn't work"

Gemini:
1. Reads src/components/Login.tsx
2. Finds onClick handler is missing
3. Creates plan:
   ## Task: Fix login button handler
   
   ### Context
   - Button rendered at line 23
   - onClick={handleSubmit} missing
   
   ### Files to Modify
   - src/components/Login.tsx - add onClick handler
   
   ### Steps
   1. Add onClick={handleSubmit} to button
   2. Verify: npm run build
   
   ### Constraints
   - handleSubmit function already exists at line 45

4. Delegates to Sisyphus - ultraworker
5. Reads result, confirms fix
```

### Example 2: Feature Request
```
User: "Add a search bar to the header"

Gemini:
1. Reads src/components/Header.tsx
2. Checks existing search components
3. Creates plan with context about:
   - Current header structure
   - Available search components
   - Styling constraints

4. Delegates to Sisyphus - ultraworker
5. Verifies result
6. User asks: "Can you make it search as you type?"
7. Gemini adds context: "Search bar already added, needs debounce"
8. Delegates follow-up to Sisyphus - ultraworker
```

### Example 3: Multi-Task Context
```
User: "Refactor the auth module and add OAuth"

Gemini:
1. Reads auth module
2. Creates Plan 1: Refactor auth
3. Delegates to Sisyphus - ultraworker
4. Verifies refactor
5. Creates Plan 2: Add OAuth (with context from refactor)
6. Delegates to Sisyphus - ultraworker
7. Verifies OAuth addition
```

---

## Token Efficiency

| Approach | Tokens | Context Quality |
|----------|--------|-----------------|
| Load everything | ~5000 | High but wasteful |
| Relay only | ~50 | Low, no context |
| **Smart planning** | ~200-400 | High, efficient |

The key: Gemini reads files SELECTIVELY and passes ONLY relevant context.
