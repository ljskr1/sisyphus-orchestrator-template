# 🤖 Sisyphus Orchestrator Workspace Template

Welcome to the **Sisyphus Orchestrator Template** repository! This project serves as a standard template for setting up collaborative AI workspaces using a **Split AI architecture**:
1. **The Brain (Orchestrator AI)**: Running inside your IDE (Cursor, Copilot, VS Code) to perform high-level planning, code analysis, requirement scoping, and task delegation.
2. **The Executor (Local Worker)**: Running locally via the `oh-my-openagent` CLI, executing terminal commands, modifying files, and running local verification loops.

This template provides ready-to-use **AI system instructions**, **behavior protocols**, and **troubleshooting guides** to ensure smooth communication between the high-level brain and the local worker.

---

## 📂 Repository Structure

The template contains the following files to configure and guide your environment:

*   **[`.cursorrules`](file:///.cursorrules)**: AI system rules that direct Cursor/IDE models on how to act as a planner and delegate code editing to the local worker.
*   **`.github/`**:
    *   **[`copilot-instructions.md`](file:///.github/copilot-instructions.md)**: AI system instructions tailored for GitHub Copilot.
*   **[`delegation-guide.md`](file:///delegation-guide.md)**: Human-and-AI readable guide explaining the CLI locations, execution syntax, setup, and configurations.
*   **[`sisyphus-context.md`](file:///sisyphus-context.md)**: Deep technical context detailing Sisyphus's agent registry, tool capabilities, intent routing, and verification guidelines.
*   **[`setup.sh`](file:///setup.sh)**: A verification utility to automate local setup and fix known environment bugs.

---

## ⚡ Quick Start

### 1. Initialize the Workspace
Clone this repository as the base template for your new project:
```bash
git clone git@github.com:ljskr1/sisyphus-orchestrator-template.git your-project-name
cd your-project-name
```

### 2. Run the Setup & Verification Script
Execute the included setup script to check your local environment (Bun, CLI installations, configuration paths) and automatically patch the casing resolution bug:
```bash
chmod +x setup.sh
./setup.sh
```

### 3. How to Use
1. **Ask the Brain**: Ask your IDE/Chat AI (e.g., Cursor, Gemini, Claude) to solve a problem or implement a feature.
2. **Review the Plan**: The AI will research, analyze, write an implementation plan, and ask for your approval.
3. **Execution**: Once approved, the AI will provide/run a CLI invocation command targeting the local worker:
   ```bash
   /Users/rock/.bun/bin/bun /Users/rock/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/bin/oh-my-opencode.js run --agent Sisyphus "Your detailed prompt here"
   ```
4. **Verification**: The local worker will modify the code and verify. The orchestrator AI reads the resulting changes to confirm completion.

---

## ⚙️ Configuration Setup

Configure `oh-my-openagent` to use your preferred models. The local config is situated at:
`~/.config/opencode/oh-my-openagent.json`

For optimal cost savings, you can route Sisyphus to a local/free model:
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

---

## 🛠️ Troubleshooting

### 🐛 Agent Name Casing Bug
If running the delegation CLI output yields:
```
[session.error] Agent not found: "sisyphus". Available agents: Sisyphus - ultraworker, ...
```
This is a casing mismatch in the CLI resolver. Running `./setup.sh` automatically patches this. Alternatively, you can follow the manual patching instructions in [Section 3 of the Delegation Guide](file:///delegation-guide.md#L52).
