# Pharmacy Agent Team

This team helps support Pharmacy decisions with synthesis, evaluation, planning, and quality assurance.

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
│  intake-and-triage           │  evidence-and-context-review │
│  planning-and-recommendation-support│  documentation-and-coordination-support│
│  quality-safety-and-compliance-review│                                  │└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

- **intake-and-triage** — Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **evidence-and-context-review** — Reviews source material, evidence, and domain context to ground the team's work.
- **planning-and-recommendation-support** — Builds structured options, plans, and recommendations from the available evidence and constraints.
- **documentation-and-coordination-support** — Prepares structured writeups, coordination artifacts, and handoffs to support domain workflows.
- **quality-safety-and-compliance-review** — Reviews work for quality, safety, procedural adherence, and domain-specific compliance concerns.

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
