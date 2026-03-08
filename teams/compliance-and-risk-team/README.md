# Compliance-and-risk-team Agent Team

This team helps analyze Compliance And Risk Team work carefully with strong guardrails, review steps, and documentation.

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
│  intake-and-triage           │  facts-and-context-analysis  │
│  policy-and-decision-support │  documentation-and-communication-support│
│  risk-and-compliance-review  │                                  │└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

- **intake-and-triage** — Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **facts-and-context-analysis** — Collects, organizes, and analyzes the relevant facts, context, documents, and constraints for careful review.
- **policy-and-decision-support** — Translates the available facts into structured options, tradeoffs, and cautious recommendation support.
- **documentation-and-communication-support** — Prepares summaries, documentation, and careful communication support based on approved direction.
- **risk-and-compliance-review** — Reviews work for risk exposure, policy alignment, consistency, and compliance concerns.

## Getting Started

```bash
# Run an agent (uses provider from .agent-teams.env or AGENT_PROVIDER env var)
../../bin/run-agent.sh compliance-and-risk-team documentation-and-communication-support

# Or paste the system prompt into any LLM:
# agents/documentation-and-communication-support/system-prompt.md

# Provide feedback
cp feedback/template.md feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md

# Run the full feedback cycle (meta-agent → auditor → approve → commit)
../../bin/run-cycle.sh compliance-and-risk-team
```
