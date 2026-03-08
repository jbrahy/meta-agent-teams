# Data-science-team Agent Team

This team helps support Data Science Team decisions with synthesis, evaluation, planning, and quality assurance.

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
│  intake-and-triage           │  requirements-and-context-analysis│
│  solution-design-and-planning│  implementation-and-delivery-support│
│  quality-security-and-reliability-review│                                  │└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

- **intake-and-triage** — Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **requirements-and-context-analysis** — Clarifies requirements, constraints, system context, and technical dependencies before work begins.
- **solution-design-and-planning** — Designs implementation approaches, architecture options, sequencing, and technical tradeoffs.
- **implementation-and-delivery-support** — Turns approved plans into execution-ready tasks, deliverables, and implementation guidance.
- **quality-security-and-reliability-review** — Reviews outputs for correctness, quality, security, resilience, and operational soundness.

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
