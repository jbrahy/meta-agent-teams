# Glossary

Shared terminology used across all agents. The meta-agent must maintain consistency with these definitions when evolving agent prompts.

## System Terms

- **Cycle**: One complete loop of agent output → human feedback → meta-agent modification → auditor review → commit.
- **Advisory output**: Agent-generated suggestions intended for human review. Never executed autonomously.
- **Evolution**: A meta-agent-initiated modification to an agent's configuration or prompt.
- **Drift**: When an agent's behavior gradually diverges from intended purpose due to cumulative prompt modifications.
- **Regression**: When a modification intended to improve one capability degrades another.
- **Coherence**: The degree to which all agents' outputs are aligned and non-contradictory.

## Agent Roles

- **Meta-Agent**: Processes human feedback and modifies agent configurations. Cannot self-modify or modify the auditor.
- **Auditor**: Independently reviews meta-agent changes for drift, regression, coherence violations, and constitutional compliance.
- **intake-and-triage**: Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents.
- **account-and-opportunity-research**: Researches accounts, stakeholders, pipeline context, and opportunity signals to support commercial decisions.
- **deal-strategy-and-prioritization**: Recommends opportunity prioritization, deal strategy, next steps, and tradeoffs.
- **pipeline-and-follow-up-execution**: Supports execution by preparing follow-ups, summaries, plans, and structured next-step materials.
- **quality-and-risk-review**: Reviews outputs for completeness, correctness, quality, and risk.

## Domain Terms

<!-- Add domain-specific terminology here as agents begin using specialized language -->
