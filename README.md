# Agent Teams

An open framework for building AI agent teams that improve themselves through structured human feedback.

Instead of hand-crafting individual agents, you define a team — the roles, the rules, the relationships — and the framework gives you a complete system: specialist agents, a meta-agent that evolves them based on your feedback, an independent auditor that keeps evolution honest, and a git-backed history of every change and why it was made.

```
┌─────────────────────────────────────────────────┐
│                   Human (You)                    │
│         Execute, evaluate, provide feedback      │
└──────────┬──────────────────────┬────────────────┘
           │ feedback             │ review audits
           ▼                     ▼
┌─────────────────┐    ┌─────────────────┐
│   Meta-Agent    │◄───│  Auditor Agent  │
│  Evolves agents │    │  Checks for     │
│  based on your  │    │  drift, bias,   │
│  feedback       │    │  & regression   │
└────────┬────────┘    └─────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│              Your Agent Team                     │
│  Specialists that advise — you decide & execute  │
└─────────────────────────────────────────────────┘
```

## Why This Exists

Most AI agent setups are static. You write a prompt, it works okay, you tweak it when it doesn't, and you lose track of what you changed and why. There's no structured way to improve agents over time, no accountability for changes, and no safeguards against the agents drifting from their purpose.

This framework treats agent development as an iterative, auditable process. Agents start imperfect and get better through cycles of use, feedback, and constrained evolution. Every change is documented. Every modification has a rationale. An independent auditor prevents the system from optimizing itself into something you didn't intend.

The result is agents that earn trust through demonstrated improvement — not agents you have to trust because you can't see what they're doing.

## What's in This Repo

```
agent-teams/
├── teams/
│   └── marketing/              # Complete marketing team (8 agents)
│       ├── agents/             # SDR, content, analytics, SEO, etc.
│       ├── meta-agent/         # Feedback processor and agent evolver
│       ├── auditor/            # Independent reviewer
│       ├── shared/             # Constitution and glossary
│       ├── feedback/           # Structured feedback templates
│       └── evals/              # Performance tracking
│
├── skill/                      # Team-builder skill for Claude Code
│   ├── SKILL.md                # Main skill definition
│   └── references/             # Architecture docs, domain constitutions
│
├── prompt/
│   └── agent-team-builder.md   # Portable prompt (works with any LLM)
│
└── docs/
    ├── architecture.md         # System design philosophy
    ├── getting-started.md      # First-run walkthrough
    └── domain-guide.md         # Domain-specific patterns
```

### Three Ways to Use It

**1. Use an existing team.** Clone the repo, pick a team from `teams/`, and start running agents via Claude Code or any LLM. The marketing team is ready to go.

**2. Build a new team with the skill.** If you use Claude Code, install the team-builder skill from `skill/`. Then say "build me a DevOps team" and it generates the full repo structure, tailored to your domain.

**3. Build a new team with the prompt.** Copy the prompt from `prompt/agent-team-builder.md` and paste it into any LLM. Describe your team, and it produces the same output. Works with Claude, GPT, Gemini, Llama, or anything else that can handle a long system prompt.

## Getting Started

### Running an existing agent

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/agent-teams.git
cd agent-teams

# Run an agent (example: SDR agent from the marketing team)
# Using Claude Code:
claude --system-prompt teams/marketing/agents/sdr/system-prompt.md

# Or paste the system prompt into any LLM conversation
```

### Providing feedback

After reviewing an agent's output:

```bash
# Copy the feedback template
cp teams/marketing/feedback/template.md teams/marketing/feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md

# Edit with your feedback
# Then run the meta-agent to process it
claude --system-prompt teams/marketing/meta-agent/system-prompt.md

# Run the auditor to review proposed changes
claude --system-prompt teams/marketing/auditor/system-prompt.md

# If approved, commit the changes
git add -A && git commit -m "Cycle N: [summary of what changed and why]"
```

### Building a new team

```bash
# Option A: Using Claude Code with the skill installed
claude "Build me a customer success team for a B2B SaaS product"

# Option B: Using the portable prompt with any LLM
# Copy prompt/agent-team-builder.md into your LLM of choice
# Then describe the team you want
```

## Core Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval. Output is always a suggestion.

2. **Everything in git.** Every agent modification is a commit with a documented rationale. You can diff, bisect, revert, and branch agent evolution just like code.

3. **Feedback-driven improvement.** Agents only change based on structured human feedback. The meta-agent never self-directs optimization.

4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify. Changes are incremental (max 30% per cycle), require documented rationale, and must pass auditor review.

5. **No single point of control.** The auditor independently reviews the meta-agent's decisions. The human reviews audit findings. No entity in the system has unchecked authority.

## Architecture

The system has four layers:

**Specialist agents** do the domain work. They produce advisory output in their area of expertise (content writing, analytics, prospecting, etc). Each has a system prompt defining capabilities, output standards, guardrails, and evaluation criteria.

**The meta-agent** processes human feedback and proposes modifications to specialist agents. It follows a four-step pipeline: categorize feedback → diagnose root cause → propose changes → document rationale. It cannot modify itself, the auditor, or the constitution.

**The auditor** independently reviews every meta-agent proposal across six dimensions: constitutional compliance, feedback fidelity, drift detection, regression risk, cross-agent coherence, and change magnitude. It has no authority to make changes — only to approve, flag, or recommend rejection.

**The constitution** defines inviolable constraints. Every domain has ethical and regulatory boundaries that no agent should cross regardless of feedback. Only the human operator can amend the constitution.

For full architectural detail, see [docs/architecture.md](docs/architecture.md).

## Pre-Built Teams

| Team | Agents | Status | Description |
|------|--------|--------|-------------|
| [Marketing](teams/marketing/) | 8 | ✅ Complete | Campaign orchestration, content, SDR, SEO, analytics, lead scoring, audience segmentation, creative |

We welcome contributions of new teams. See [Contributing](#contributing).

## Contributing

We'd love your help making this framework better. There are several ways to contribute:

### Share a team you've built

If you've used the framework to build a team for a new domain, consider contributing it. Community-contributed teams help everyone and demonstrate the framework's versatility.

1. Fork the repo
2. Add your team to `teams/<domain-name>/`
3. Ensure it includes all required files (see the structure above)
4. Submit a PR using the team contribution template

### Improve the framework

The meta-agent architecture, auditor evaluation dimensions, constitution patterns, and feedback loop can all be improved. If you've found a better pattern through real-world use:

1. Open an issue describing what you learned and why it's better
2. Fork, implement, and submit a PR
3. Include before/after examples if possible

### Add domain-specific constitution patterns

The `skill/references/domain-constitutions.md` file contains ethical and regulatory constraint patterns for various domains. If you have domain expertise and can improve or add to these patterns, that's a high-value contribution — these constraints directly impact agent safety.

### Report issues

If you find that the framework produces poor results for a specific domain, or if an agent's guardrails are insufficient, open an issue. Safety-related issues are especially welcome.

### Contribution guidelines

- **Keep it open.** All contributions must be compatible with the AGPL-3.0 license.
- **Document your reasoning.** The framework is built on the principle that every change has a documented rationale. Contributions should follow the same principle. Explain what you changed and why in your PR.
- **Test with real use.** If contributing a team, it should have been run through at least a few feedback cycles. Untested teams are accepted as drafts if clearly labeled.
- **Respect the architecture.** The meta-agent/auditor/constitution pattern is the core of the framework. Contributions should work within this pattern, not around it. If you think the pattern itself should change, open an issue for discussion first.
- **Be thoughtful about ethics.** Constitution patterns and agent guardrails exist for a reason. PRs that weaken safety constraints need strong justification.

See [CONTRIBUTING.md](CONTRIBUTING.md) for full details.

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

This means:
- You can use, modify, and distribute this freely
- If you modify it, you must share your modifications under the same license
- If you run a modified version as a service (even over a network), you must make the source available to users of that service
- The framework will always remain open source

See [LICENSE](LICENSE) for the full text.

### Why AGPL-3.0

This project exists to make agent development more transparent, auditable, and ethical. The AGPL ensures that these values propagate through all derivatives. Anyone can use and improve this work, but no one can make it proprietary. If someone builds something better on top of this, that improvement stays available to everyone.

## Acknowledgments

Built by humans who believe AI development should be transparent, auditable, and in service of people — not the other way around.

## Roadmap

- [ ] Pre-built teams: DevOps/SRE, Customer Success, Sales, Product Management
- [ ] Automated eval runner for feedback cycle benchmarking
- [ ] Inter-team communication protocols (agents from different teams collaborating)
- [ ] Web UI for feedback submission and audit review
- [ ] Agent promotion system (advisory → semi-autonomous → autonomous based on trust score)
- [ ] Multi-model support configs (mixing different LLMs for different agent roles)
