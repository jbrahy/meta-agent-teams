# Simplicity-team Agent Team

This team helps manage Simplicity Team work with specialist agents that research, plan, review, and improve outcomes.

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
│  intake-and-triage           │  research-and-context        │
│  strategy-and-planning       │  execution-support           │
│  quality-and-risk-review     │                                  │└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

- **intake-and-triage** — Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **research-and-context** — Researches relevant context, inputs, and supporting information for the team.
- **strategy-and-planning** — Turns context into recommended priorities, plans, and decision support.
- **execution-support** — Produces structured execution support, artifacts, and follow-through guidance.
- **quality-and-risk-review** — Reviews outputs for completeness, correctness, quality, and risk.

## Getting Started

```bash
# Run an agent (uses provider from .agent-teams.env or AGENT_PROVIDER env var)
../../bin/run-agent.sh simplicity-team execution-support

# Or paste the system prompt into any LLM:
# agents/execution-support/system-prompt.md

# Provide feedback
cp feedback/template.md feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md

# Run the full feedback cycle (meta-agent → auditor → approve → commit)
../../bin/run-cycle.sh simplicity-team
```
