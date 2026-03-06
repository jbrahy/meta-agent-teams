# bin/ — Meta-Agent Team Tools

Command-line tools for building and operating agent teams. All scripts run from this directory and operate on teams stored in `teams/<team-slug>/` at the repo root.

## Prerequisites

- **Bash 4+** (macOS users: `brew install bash`)
- **Claude Code CLI** (`npm install -g @anthropic-ai/claude-code`)
- **Python 3** (for JSON manipulation in scoring and cycle management)
- **Git** (optional, for versioned evolution tracking)

## Scripts

### `build-team-template.sh [team-type]`

Interactive scaffolder that generates a complete agent team directory. Walks you through defining agents, capabilities, dependencies, guardrails, ethical constraints, and evaluation dimensions. Produces the full structure: system prompts, agent configs, constitution, meta-agent, auditor, glossary, feedback template, and baseline scores.

```bash
./build-team-template.sh              # interactive
./build-team-template.sh devops       # pre-fill domain
```

### `run-agent.sh <team-slug> <agent-name> [prompt]`

Runs any agent with automatic context loading. Parses `agent.yaml` to find `context_sources`, assembles the system prompt with all referenced files (constitution, glossary, dependent agent prompts), and invokes Claude. Works for specialist agents, the meta-agent, and the auditor.

```bash
./run-agent.sh marketing sdr                                    # interactive session
./run-agent.sh marketing sdr "Draft a cold outreach email..."   # one-shot
./run-agent.sh marketing meta-agent                             # run the meta-agent
./run-agent.sh marketing auditor                                # run the auditor
```

### `new-feedback.sh <team-slug> [cycle-number]`

Creates a dated feedback file from the team's template. Auto-detects the current cycle number from `baseline-scores.json`. If a file already exists for today, offers to append a new item. Opens the file in `$EDITOR`, VS Code, or vim.

```bash
./new-feedback.sh marketing        # auto-detect cycle
./new-feedback.sh marketing 3      # explicit cycle number
```

### `run-cycle.sh <team-slug> [feedback-file]`

Orchestrates the full evolution cycle:

1. Finds the most recent feedback file (or uses the one you specify)
2. Sends it to the **meta-agent** → produces an evolution proposal
3. Sends the proposal to the **auditor** → produces an audit report
4. Shows you a color-coded pass/flag dashboard
5. You **approve**, **review**, or **reject**
6. On approval: updates cycle count and optionally commits to git

All artifacts are saved under `evals/cycle-N/`.

```bash
./run-cycle.sh marketing                                                        # uses latest feedback
./run-cycle.sh marketing ../teams/marketing/feedback/2026-03/2026-03-06.md      # specific file
```

### `update-scores.sh <team-slug> [cycle-number]`

Interactive scoring after a cycle. Walks through each agent asking for a 1–5 overall rating and optional per-dimension scores. Calculates rolling averages (last 5 cycles) and trend direction (improving/stable/declining). Updates `evals/baseline-scores.json`.

```bash
./update-scores.sh marketing       # auto-detect cycle
./update-scores.sh marketing 3     # explicit cycle
```

### `team-status.sh [team-slug]`

Dashboard view. Without arguments, lists all teams. With a team slug, shows:

- Cycle count, last updated, operational mode
- Agent score table with trends and rolling averages
- Recent feedback files
- Cycle history with completion status
- Drift warnings (agents with many modifications)
- Quick-reference commands

```bash
./team-status.sh              # list all teams
./team-status.sh marketing    # full dashboard
```

## Typical Workflow

```
1. Scaffold        ./build-team-template.sh marketing
2. Run agents      ./run-agent.sh marketing sdr "Draft a cold outreach email"
3. Record feedback ./new-feedback.sh marketing
4. Evolve          ./run-cycle.sh marketing
5. Score           ./update-scores.sh marketing
6. Review          ./team-status.sh marketing
7. Repeat from 2
```

## Directory Structure

```
meta-agent-teams/
├── bin/
│   ├── build-team-template.sh
│   ├── run-agent.sh
│   ├── new-feedback.sh
│   ├── run-cycle.sh
│   ├── update-scores.sh
│   ├── team-status.sh
│   └── README.md              ← you are here
├── docs/
│   ├── architecture.md
│   ├── getting-started.md
│   └── domain-guide.md
├── prompt/
│   └── agent-team-builder.md
├── skill/
│   ├── SKILL.md
│   └── references/
└── teams/
    └── marketing/             ← example team (ships with repo)
        ├── README.md
        ├── shared/
        │   ├── constitution.md
        │   └── glossary.md
        ├── meta-agent/
        │   ├── system-prompt.md
        │   ├── agent.yaml
        │   └── CHANGELOG.md
        ├── auditor/
        │   ├── system-prompt.md
        │   ├── agent.yaml
        │   └── CHANGELOG.md
        ├── agents/
        │   └── <agent-name>/
        │       ├── system-prompt.md
        │       ├── agent.yaml
        │       └── CHANGELOG.md
        ├── feedback/
        │   ├── template.md
        │   └── YYYY-MM/
        │       └── YYYY-MM-DD.md
        └── evals/
            ├── baseline-scores.json
            └── cycle-N/
                ├── evolution-proposal.md
                └── audit-report.md
```

## Notes

- **Claude CLI flags**: `run-cycle.sh` uses `--system-prompt`, `--prompt`, and `--output-file`. If your Claude Code version uses different flags, adjust the invocations in that script.
- **Multiple teams**: All scripts support multiple teams side by side under `teams/`. Use `team-status.sh` with no arguments to see them all.
- **Git integration**: `run-cycle.sh` and `update-scores.sh` will offer to commit if they detect a git repo. Every cycle becomes a commit with a traceable rationale chain.
- **Constitution is sacred**: Only `build-team-template.sh` creates it. No script modifies it. Only you do, by hand.
