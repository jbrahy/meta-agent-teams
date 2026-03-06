---
name: team-builder
description: Generates complete AI agent team repositories from a team description. Use this skill whenever the user wants to create an agent team, build a group of AI agents, scaffold an agent system, design a multi-agent architecture, or mentions "meta-agent", "agent team", "agent factory", or asks to create agents that work together. Also triggers when the user says things like "build me a [domain] team", "I need agents for [task]", "create an AI team that handles [function]", or wants to set up a supervised agent training loop. Even if they just describe a workflow with multiple specialized roles, this skill applies.
---

# Team Builder Skill

Generates a complete, production-ready agent team repository from a team description. The output is a self-contained system with a meta-agent (manager/trainer), an auditor (independent reviewer), specialized agents, a constitution, feedback loop, and eval tracking — all backed by git.

## When you receive a team-building request

Read `references/architecture.md` first to understand the system design philosophy. Then follow the generation workflow below.

## Required input

You need at minimum a **team description** — what domain, what the team does, and ideally a list of agent roles. If the user provides only a domain (e.g., "build me a DevOps team"), interview briefly to clarify:

1. What specific problems should this team advise on?
2. Are any specific agent roles already in mind, or should you propose them?
3. What's the operational model — advisory only, or will some agents take actions?
4. Are there domain-specific ethical or regulatory constraints?

Don't over-interview. If the user gives you enough to work with, start generating. You can always refine.

## Generation Workflow

### Step 1: Analyze the team description

Before generating anything, think through:

- **Which roles are genuinely agentic** (observe → decide → act loops) vs. which are **pipelines** (input → transform → output)? Label them honestly. Both are valid, but they need different architectures. Agents get full system prompts with decision frameworks. Pipelines get structured prompt templates.
- **What are the dependency relationships?** Which agents consume another agent's output? Draw this graph mentally — it determines context_sources in each agent.yaml.
- **What are the domain-specific ethical constraints?** Every domain has them. Medical teams can't diagnose. Legal teams can't give advice as attorneys. Financial teams need disclosure language. These go in the constitution.
- **What's the feedback signal?** How will the human know if an agent's output is good? This determines the eval dimensions.

### Step 2: Generate the repository

Create the following structure. Every file is mandatory unless marked optional.

```
<team-name>/
├── README.md                          # Architecture diagram, principles, workflow, getting started
├── shared/
│   ├── constitution.md                # Inviolable constraints — only human can modify
│   └── glossary.md                    # Shared terminology for the domain
├── meta-agent/
│   ├── system-prompt.md               # Feedback processing, evolution proposal workflow
│   ├── agent.yaml                     # Config: model, temperature, context sources
│   └── CHANGELOG.md                   # History of modifications (starts empty)
├── auditor/
│   ├── system-prompt.md               # Independent review framework
│   ├── agent.yaml                     # Config with independence constraints
│   └── CHANGELOG.md
├── agents/
│   └── <agent-name>/                  # One directory per specialist agent
│       ├── system-prompt.md           # Core prompt with capabilities, standards, guardrails
│       ├── agent.yaml                 # Config: model, temperature, dependencies, capabilities
│       └── CHANGELOG.md
├── feedback/
│   └── template.md                    # Structured feedback form
└── evals/
    └── baseline-scores.json           # Performance tracking structure
```

### Step 3: Write each component

Follow the templates and guidelines in `references/architecture.md` for each component. Key principles per component:

**README.md** — Include an ASCII architecture diagram showing the human → meta-agent → agents flow with the auditor as an independent check. List principles, workflow steps, directory structure, and getting started commands.

**Constitution** — This is the most important document. It defines what NO agent (including the meta-agent) can violate. Structure it as:
1. Scope of authority (advisory only unless explicitly configured otherwise)
2. Domain-specific ethical boundaries (research these — every domain has regulatory and ethical constraints)
3. Evolution rules (incremental changes, documented rationale, rollback path)
4. Data handling constraints
5. Quality/voice/brand integrity
6. Inter-agent coherence requirements

The constitution must be written so that the meta-agent cannot weaken it, the auditor enforces it, and only the human operator can amend it.

**Meta-agent system prompt** — Structure it as a feedback processing pipeline:
1. Categorize feedback (which agent, what type, severity)
2. Diagnose root cause (why did the agent produce that output?)
3. Propose modifications (with specific diffs, rationale, side effects)
4. Document in CHANGELOG

Include explicit constraints: max 30% prompt change per cycle, one variable at a time, preserve what works, cross-agent coherence check, never infer feedback that wasn't given.

**Auditor system prompt** — Six evaluation dimensions:
1. Constitutional compliance
2. Feedback fidelity (did the meta-agent actually address the feedback?)
3. Drift detection (is the agent moving away from its purpose?)
4. Regression risk (could this change break something that works?)
5. Cross-agent coherence (are agents still aligned?)
6. Change magnitude (within the 30% threshold?)

The auditor must be explicitly independent — the meta-agent has no authority over it.

**Specialist agent system prompts** — Each agent needs:
- Clear role definition and capabilities list
- Output standards specific to the domain (not generic quality platitudes — concrete, measurable standards)
- An explicit "What you must never do" section with domain-specific guardrails
- Context requirements (what information the agent needs to do its job)
- Evaluation criteria (how the human will judge output quality)
- Dependency declarations (which other agents' output it needs)

**Agent.yaml configs** — Each config must include:
- `name`: identifier
- `description`: one-line purpose
- `model`: default to `claude-sonnet-4-20250514`
- `temperature`: calibrated to the task (0.2 for analytical/precision work, 0.4-0.5 for strategic/planning, 0.7-0.8 for creative/generative work)
- `context_sources`: list of files the agent needs (always includes constitution and glossary)
- `capabilities`: enumerated list of what this agent does
- `dependencies`: list of other agents whose output this agent consumes
- `output_format`: markdown (default) or other
- `output_target`: stdout (default for advisory mode)

**Feedback template** — Structured form with:
- Cycle number
- Per-item: agent name, task description, rating (1-5), what worked, what didn't, root cause hypothesis, desired behavior
- Cross-agent observations section
- System-level notes section

**Baseline scores** — JSON tracking structure with:
- Metadata (created date, current cycle, notes)
- Per-agent: version, cycles completed, scores array, rolling average, trend
- Score schema with domain-appropriate evaluation dimensions

### Step 4: Validate coherence

Before finalizing, check:
- Every agent referenced as a dependency by another agent actually exists
- Constitution constraints are enforceable by the auditor's evaluation framework
- No two agents have overlapping responsibilities without explicit coordination rules
- The meta-agent's authority scope matches what the constitution allows
- Temperature settings make sense for each agent's task type
- Glossary covers all domain-specific terms used in agent prompts

### Step 5: Package and deliver

Zip the entire directory structure and present it to the user. Summarize what was generated and suggest which agent to run first.

## Calibrating agent count

Users often propose too many agents. Push back gently using these guidelines:

- **If roles overlap significantly**, merge them into one agent with multiple capabilities. Flag what you merged and why.
- **If a "role" is really a single function** (e.g., "email formatter"), it's a capability within another agent, not its own agent.
- **The sweet spot is 4-8 specialist agents.** Below 4 and you probably don't need the meta-agent architecture. Above 8 and the coherence overhead starts to dominate.
- **If the user insists on more**, build them — but document in the README that some agents may be candidates for consolidation after initial feedback cycles.

## Temperature calibration guide

| Task Type | Temperature | Reasoning |
|-----------|-------------|-----------|
| Data analysis, scoring, compliance, auditing | 0.1-0.2 | Precision critical, minimal hallucination risk |
| Strategy, planning, coordination | 0.3-0.5 | Structured thinking with some flexibility |
| Research, synthesis, recommendations | 0.4-0.6 | Balance between accuracy and insight |
| Writing, creative, communication | 0.7-0.8 | Needs originality and voice variation |
| Brainstorming, ideation | 0.8-0.9 | Maximum creative range |

## Domain-specific constitution patterns

Read `references/domain-constitutions.md` for ethical and regulatory constraints by domain. These are starting points — always research domain-specific regulations and adapt.
