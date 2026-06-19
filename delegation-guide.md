# AI-to-AI Delegation Guide (Antigravity ⇄ Sisyphus)

This document explains the architecture, CLI commands, and setup required to use **Antigravity (or any high-level AI assistant)** as the orchestrator/brain and **Sisyphus (via `oh-my-openagent` CLI)** as the local worker/executor.

---

## 1. Architecture: The Brain & The Executor

To maximize speed, reliability, and token savings, the development workflow is split:

* **The Brain (Orchestrator AI):** High-level planning, requirement analysis, edge-case detection, and task decomposition. Does not edit files directly.
* **The Executor (Local Sisyphus - ultraworker / sisypus ulw):** Executes edits, runs local CLI commands, validates compile/build errors, checks tests, and runs LSP tools. Runs locally via the free `opencode/mimo-v2.5-free` model. To save tokens and run efficiently, the Brain (Gemini) MUST delegate execution steps to Sisyphus - ultraworker. Since there are **no rate limits** for opencode and Sisyphus, if a task needs to loop overnight, you must continue running and iterating until it is successfully completed.

```
┌─────────────────────────────────┐
│     Orchestrator AI (Brain)     │
│  (Gemini/Claude in Chat/IDE)   │
└────────────────┬────────────────┘
                 │
           plans & prompts
                 │
                 ▼
┌─────────────────────────────────┐
│     oh-my-openagent CLI         │
│  (Runs Sisyphus local worker)   │
└────────────────┬────────────────┘
                 │
          executes coding
                 │
                 ▼
┌─────────────────────────────────┐
│        Workspace Files          │
│   (index.html, src/, etc.)      │
└─────────────────────────────────┘
```

---

## 2. CLI Location and Invocation

The local execution environment supports two main delegation paths:

### PATH A: Simple Tasks (formatting, comments, docs, or simple single-line edits)
* **First run** (runs task on default OpenCode with the free model):
  ```bash
  opencode run -m opencode/mimo-v2.5-free "Your detailed prompt here"
  ```
* **Follow-up runs** (resumes the same session; plain `opencode` uses `-s` for session):
  ```bash
  opencode run -s <session_id> "Your follow-up prompt here"
  ```

### PATH B: Complex Tasks (multi-file logic, refactoring, algorithms, or test-heavy edits)
* **First run** (runs Sisyphus - ultraworker with `--json` to capture `sessionId`):
  ```bash
  /Users/rock/.bun/bin/bun /Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js run --agent Sisyphus --json "Your detailed prompt here"
  ```
* **Follow-up runs** (resumes the same Sisyphus session using `--session-id`):
  ```bash
  /Users/rock/.bun/bin/bun /Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js run --session-id ses_abc123 "Your follow-up prompt here"
  ```

---

## 3. The Casing & Agent-Name Resolution Bug (CRITICAL)

### The Issue
By default, the `oh-my-openagent` CLI lowercases the requested agent name (e.g., `--agent Sisyphus` gets resolved to `"sisyphus"`). However, the `opencode` server registry uses case-sensitive display names (e.g., `"Sisyphus - ultraworker"`). This mismatch triggers the following error:
```
[session.error] Agent not found: "sisyphus". Available agents: Sisyphus - ultraworker, Hephaestus - Deep Agent, ...
```

### The Fix
To fix this, the CLI's normalization function in `dist/cli/index.js` must be patched to return the actual registered display name instead of the lowercase configuration key.

**File to patch:**
`/Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/dist/cli/index.js`

**Find:**
```javascript
var normalizeAgentName = (agent) => {
  if (!agent)
    return;
  const trimmed = agent.trim();
  if (trimmed.length === 0)
    return;
  const configKey = getAgentConfigKey(trimmed);
  const displayName = getAgentDisplayName(configKey);
  const isKnownAgent = displayName !== configKey;
  return {
    configKey,
    resolvedName: isKnownAgent ? configKey : trimmed // <--- THIS LINE
  };
};
```

**Replace with:**
```javascript
var normalizeAgentName = (agent) => {
  if (!agent)
    return;
  const trimmed = agent.trim();
  if (trimmed.length === 0)
    return;
  const configKey = getAgentConfigKey(trimmed);
  const displayName = getAgentDisplayName(configKey);
  const isKnownAgent = displayName !== configKey;
  return {
    configKey,
    resolvedName: isKnownAgent ? displayName : trimmed // <--- RESOLVES DISPLAY NAME (e.g. Sisyphus - ultraworker)
  };
};
```

---

## 4. Configuration Settings

The global configuration file is located at [oh-my-openagent.json](file:///Users/rock/.config/opencode/oh-my-openagent.json). 

To configure Sisyphus or other agents to use the free model, the configuration is mapped as follows:
```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "opencode/mimo-v2.5-free",
      "fallback_models": []
    }
  }
}
```

*Note: If you need to save tokens/rate limits on other agents, you can configure `"thinking": { "type": "disabled" }` or set a lower `"maxTokens"` limit for them in this JSON file.*

---

## 5. How to Delegate a Task (For the Orchestrator AI)

When the user asks you to implement a feature, fix a bug, or perform coding work, do **NOT** modify files directly. Instead, follow these steps:

1. **Write an Implementation Plan:** Map out what files need to change, what the widget/logic should do, and list the step-by-step goals.
2. **Obtain Approval:** Get user confirmation on the plan.
3. **Classify and Delegate:** Choose the correct path based on complexity:
   * **For Path A (Simple Tasks):**
     * First run:
       ```bash
       opencode run -m opencode/mimo-v2.5-free "YOUR_PROMPT"
       ```
     * Follow-up run:
       ```bash
       opencode run -s <session_id> "YOUR_FOLLOW_UP_PROMPT"
       ```
   * **For Path B (Complex Tasks):**
     * First run:
       ```bash
       /Users/rock/.bun/bin/bun /Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js run --agent Sisyphus --json "YOUR_DETAILED_PROMPT"
       ```
     * Follow-up run:
       ```bash
       /Users/rock/.bun/bin/bun /Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js run --session-id <session_id> "YOUR_FOLLOW_UP_PROMPT"
       ```
4. **Verify:** Check the output, view the modified files to confirm, extract/save the session ID from the output for future turns, and mark tasks as complete.

By routing the execution through Sisyphus - ultraworker running on `opencode/mimo-v2.5-free` and resuming sessions, we ensure massive token savings for the high-level Brain.

---

## 6. Edge Cases & Troubleshooting

### 6.1 Casing Bug (Agent Not Found)
If Sisyphus fails to launch with an `Agent not found: "sisyphus"` error, apply the index.js display name patch detailed in Section 3.

### 6.2 Session ID Invalidation
If a continuation command fails with `Session not found` or `invalid session ID`:
- **For Path A:** Rerun the command without `-s`, e.g.: `opencode run -m opencode/mimo-v2.5-free "Execute: [plan]"`
- **For Path B:** Rerun the command without `--session-id`, e.g.: `bun oh-my-opencode.js run --agent Sisyphus --json "Execute: [plan]"`
Capture the new session ID returned and use it for subsequent turns.

### 6.3 Task Scope Escalation (Path A -> Path B)
If a Path A (Simple Task) grows and requires multi-file logic, cancel the Path A session and start a new Path B Sisyphus session containing the full plan.

### 6.4 Command Hangs or Terminals Freezing
If a background execution command does not return, use the `manage_task` tool with action `kill` in the IDE, inspect git status via terminal, restore clean state, and retry the delegation.
