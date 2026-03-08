# Revenue-cycle-management-team Agent Team

This team helps improve Revenue Cycle Management Team outcomes through research, strategy, execution support, and quality review.

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
│  intake-and-triage           │  account-and-opportunity-research│
│  deal-strategy-and-prioritization│  pipeline-and-follow-up-execution│
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
- **account-and-opportunity-research** — Researches accounts, stakeholders, pipeline context, and opportunity signals to support commercial decisions.
- **deal-strategy-and-prioritization** — Recommends opportunity prioritization, deal strategy, next steps, and tradeoffs.
- **pipeline-and-follow-up-execution** — Supports execution by preparing follow-ups, summaries, plans, and structured next-step materials.
- **quality-and-risk-review** — Reviews outputs for completeness, correctness, quality, and risk.

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
