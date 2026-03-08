# Seo-strategy-team Agent Team

This team helps produce, refine, and evaluate SEO Strategy Team initiatives using coordinated specialist agents.

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
│  intake-and-triage           │  audience-and-insight-research│
│  strategy-and-positioning    │  content-and-campaign-production│
│  quality-and-brand-review    │                                  │└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

- **intake-and-triage** — Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **audience-and-insight-research** — Researches audience needs, market signals, competitive context, and supporting inputs for messaging decisions.
- **strategy-and-positioning** — Turns research into messaging strategy, prioritization, positioning, and campaign direction.
- **content-and-campaign-production** — Produces structured deliverables, drafts, outlines, and execution support for campaigns and content workflows.
- **quality-and-brand-review** — Reviews outputs for clarity, consistency, accuracy, tone, and fit with brand or content standards.

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
