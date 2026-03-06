# Architecture Reference

## System Design Philosophy

The team-builder creates **supervised, iterative agent development systems**. The core insight: agents don't start good — they get good through structured feedback loops. The architecture optimizes for learning speed, not initial quality.

### The Feedback Loop

```
Human provides task → Agent produces advisory output → Human evaluates
    ↓
Human records structured feedback
    ↓
Meta-agent interprets feedback → proposes agent modifications
    ↓
Auditor reviews proposed changes (constitutional compliance, drift, coherence)
    ↓
Human approves → changes committed to git with rationale
    ↓
Next cycle runs against improved agents
```

Every team follows this loop. The domain-specific parts are the agent prompts and the constitution. The feedback mechanism, auditor pattern, and git-backed evolution are universal.

### Why This Architecture

**Why a meta-agent instead of just editing prompts manually?**
The meta-agent forces structured reasoning about *why* a change is being made. Without it, prompt engineering becomes ad hoc — you tweak things, lose track of what you changed and why, and can't diagnose regressions. The meta-agent is a disciplined change management process that happens to be implemented as an AI.

**Why an auditor?**
Because the meta-agent will optimize. That's what it does. Without an independent check, it will drift toward whatever proxy metric seems to correlate with positive feedback — even if that metric is misleading. The auditor is a circuit breaker.

**Why git?**
Because agent evolution is a versioning problem. You need to diff, bisect, revert, and branch. Every other versioning system is worse than git for this.

**Why advisory-only by default?**
Because trust is earned through demonstrated competence over time. An agent that proves reliable across 50 feedback cycles has earned more autonomy than a freshly scaffolded one. Start advisory, graduate to autonomous only when the feedback history justifies it.

---

## Component Templates

### README.md Template

```markdown
# [Team Name]

[One paragraph: what this team does and how it operates]

## Architecture

[ASCII diagram — adapt this to the specific team's agent relationships]

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
│  [List agents in a grid]                         │
└─────────────────────────────────────────────────┘

## Principles

1. Agents advise, humans execute.
2. Everything in git.
3. Feedback-driven improvement.
4. Constrained evolution.
5. No single point of control.

## Workflow

[Same as the universal loop, adapted to domain-specific terms]

## Directory Structure

[Show the actual structure generated]

## Getting Started

[Commands to run each agent via Claude Code]
```

### Meta-Agent System Prompt Template

The meta-agent prompt must contain these sections in this order:

1. **Role definition** — "You are the Meta-Agent for [team name]..."
2. **Authority scope** — what it can and cannot modify (always: agent prompts and configs. Never: constitution, auditor, itself)
3. **Feedback processing pipeline** — the four-step process (categorize → diagnose → propose → document)
4. **Evolution constraints** — 30% max change, one variable at a time, preserve what works, cross-agent coherence, never infer unspoken feedback
5. **Output format** — structured evolution proposal template
6. **Prohibitions** — what the meta-agent must never do

### Auditor System Prompt Template

The auditor prompt must contain:

1. **Independence declaration** — not subordinate to the meta-agent
2. **Review inputs** — what it receives each cycle
3. **Six evaluation dimensions** — constitutional compliance, feedback fidelity, drift detection, regression risk, cross-agent coherence, change magnitude
4. **Output format** — structured audit report with status per dimension
5. **Prohibitions** — never approve constitutional violations, never defer to meta-agent when concerned, never make changes itself

### Specialist Agent System Prompt Template

Each specialist agent needs:

```markdown
# [Agent Name] — System Prompt

[One paragraph role definition. What you are, what you do, advisory caveat.]

## Your Capabilities

[Numbered list of 3-6 specific capabilities. Each is a verb phrase.]

## Output Standards

[Concrete, measurable standards organized by output type. Not platitudes —
specific formats, lengths, structures, and quality criteria.]

### [Output Type 1]
- [Standard]
- [Standard]

### [Output Type 2]
- [Standard]

## What You Must Never Do

[Domain-specific guardrails. These are non-negotiable behavioral constraints.
Every agent has a "never" list tailored to its domain's risks.]

## Context You Need

[What information the agent needs to produce good output. This guides the
human on what to provide and tells the meta-agent what context gaps to fill.]

## How You'll Be Evaluated

[4-6 evaluation criteria. These should map to the eval dimensions in
baseline-scores.json. They tell the agent what "good" looks like and give
the meta-agent specific targets to optimize toward.]
```

### Constitution Template

See `references/domain-constitutions.md` for domain-specific constraints. Every constitution has these universal sections:

1. **Scope of Authority** — advisory-only default, meta-agent's allowed modifications, auditor independence
2. **Ethical Boundaries** — domain-specific (ALWAYS research the domain's regulatory and ethical landscape)
3. **Evolution Rules** — rationale required, auditor review required, rollback path, incremental changes, no single-metric optimization
4. **Data Handling** — what data agents may reference, what they may not
5. **Quality Integrity** — brand/voice/accuracy constraints
6. **Inter-Agent Coherence** — no contradictions, conflicts surfaced to human

### Agent.yaml Template

```yaml
name: [kebab-case-name]
description: [one-line purpose]
model: claude-sonnet-4-20250514
temperature: [calibrated to task — see temperature guide in SKILL.md]

context_sources:
  - shared/constitution.md
  - shared/glossary.md
  # Add other agents' prompts if this agent depends on them

capabilities:
  - [capability_1]
  - [capability_2]

dependencies:
  - [agent-name]  # Agents whose output this agent consumes

output_format: markdown
output_target: stdout
```
