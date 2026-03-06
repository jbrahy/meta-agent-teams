# Marketing Agent Team

A supervised, iterative agent development system where a **meta-agent** manages and improves a team of marketing-focused AI agents based on structured human feedback.

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
│              Agent Team (Advisory)               │
│                                                  │
│  Campaign Orchestrator  │  Content Generation    │
│  Analytics & Insights   │  Lead Scoring          │
│  Audience & Persona     │  Creative/Multimedia   │
│  Outbound SDR           │  SEO & Content Strategy│
└─────────────────────────────────────────────────┘
```

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action. All output is suggestion-based, reviewed by a human before execution.
2. **Everything in git.** Every agent modification is a commit with documented rationale. Agent evolution is fully auditable.
3. **Feedback-driven improvement.** The meta-agent only evolves agents based on structured human feedback — never self-directed optimization.
4. **Constrained evolution.** The meta-agent operates within explicit boundaries defined in `shared/constitution.md`. The auditor enforces compliance.
5. **No single point of control.** The auditor agent independently evaluates meta-agent decisions. The human reviews audit findings.

## Workflow

1. Run an agent via Claude Code → receive advisory output
2. Evaluate the output, execute what's useful
3. Record structured feedback in `/feedback/YYYY-MM/YYYY-MM-DD.md`
4. Meta-agent processes feedback, proposes agent modifications
5. Auditor reviews proposed changes against constitution and performance history
6. Approved changes are committed with rationale in each agent's `CHANGELOG.md`
7. Evals are recorded in `/evals/` for longitudinal tracking

## Directory Structure

```
/agents/                  # Individual agent configs and prompts
  /<agent-name>/
    agent.yaml            # Model, tools, parameters
    system-prompt.md      # The agent's core prompt
    CHANGELOG.md          # History of meta-agent modifications
/meta-agent/              # The meta-agent's own config
/auditor/                 # The auditor agent's config
/feedback/                # Structured human feedback by date
/evals/                   # Performance snapshots and baselines
/shared/                  # Cross-cutting concerns
  constitution.md         # Inviolable constraints for all agents
  glossary.md             # Shared terminology and definitions
```

## Getting Started

```bash
# Run any agent via Claude Code
claude --system-prompt agents/sdr/system-prompt.md

# Provide feedback after reviewing output
# Edit feedback/YYYY-MM/YYYY-MM-DD.md

# Run the meta-agent to process feedback and propose changes
claude --system-prompt meta-agent/system-prompt.md

# Run the auditor to review proposed changes
claude --system-prompt auditor/system-prompt.md
```
