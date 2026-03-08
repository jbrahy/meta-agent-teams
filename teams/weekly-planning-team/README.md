# Weekly-planning-team Agent Team

This team helps manage Weekly Planning Team work with specialist agents that research, plan, review, and improve outcomes.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Human (You)                    │
│         Execute, evaluate, provide feedback      │
└──────────┬──────────────────────┬────────────────┘
           │ feedback             │ review audits
           ▼                     ▼
┌─────────────────┐    ┌─────────────────┐
│   Meta-Agent    │◄───│  Auditor Agent  │
│  Interprets     │    │  Reviews meta   │
│  feedback,      │    │  changes for    │
│  evolves agents │    │  drift, regress │
└────────┬────────┘    │  & coherence    │
         │             └─────────────────┘
         │ modifies configs, prompts, tools
         ▼
┌─────────────────────────────────────────────────┐
│              Agent Team (Advisory-only)               │
│  intake-and-triage           │  intake-and-diagnostics      │
│  planning-and-coordination   │  execution-support           │
│  quality-and-exception-review│                                  │└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

- **intake-and-triage** — Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **intake-and-diagnostics** — Assesses incoming work, diagnoses bottlenecks, and clarifies the operational problem to solve.
- **planning-and-coordination** — Creates plans, priorities, owners, and sequencing for operational execution.
- **execution-support** — Produces structured execution support, artifacts, and follow-through guidance.
- **quality-and-exception-review** — Reviews plans and outputs for process quality, exception handling, and execution risk.

## Getting Started

```bash
# Run an agent
claude --system-prompt agents/intake-and-triage/system-prompt.md

# Provide feedback
cp feedback/template.md feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md

# Process feedback with the meta-agent
claude --system-prompt meta-agent/system-prompt.md

# Audit proposed changes
claude --system-prompt auditor/system-prompt.md

# Commit approved changes
git add -A && git commit -m "Cycle N: [summary]"
```
