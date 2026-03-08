# Sre-team Agent Team

This team helps plan, review, and improve SRE Team work through structured specialist agents.

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
│              Agent Team (Semi-autonomous)               │
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
# Run an agent (uses provider from .agent-teams.env or AGENT_PROVIDER env var)
../../bin/run-agent.sh sre-team implementation-and-delivery-support

# Or paste the system prompt into any LLM:
# agents/implementation-and-delivery-support/system-prompt.md

# Provide feedback
cp feedback/template.md feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md

# Run the full feedback cycle (meta-agent → auditor → approve → commit)
../../bin/run-cycle.sh sre-team
```
