# Contributing to Agent Teams

Thank you for wanting to make this better. This guide covers how to contribute effectively.

## Ways to Contribute

### 1. Contribute a team

The highest-impact contribution is a complete agent team for a new domain. A good team contribution:

- Has been through at least 2-3 feedback cycles with real use (or is clearly labeled as a draft)
- Includes all required files: README, constitution, glossary, meta-agent, auditor, specialist agents, feedback template, baseline scores
- Has a domain-appropriate constitution with real ethical and regulatory constraints (not copied from another team)
- Has agent prompts with concrete, measurable output standards (not generic quality platitudes)

**Structure your PR:**

```
teams/<domain-name>/
├── README.md
├── shared/
│   ├── constitution.md
│   └── glossary.md
├── meta-agent/
│   ├── system-prompt.md
│   ├── agent.yaml
│   └── CHANGELOG.md
├── auditor/
│   ├── system-prompt.md
│   ├── agent.yaml
│   └── CHANGELOG.md
├── agents/
│   └── <agent-name>/
│       ├── system-prompt.md
│       ├── agent.yaml
│       └── CHANGELOG.md
├── feedback/
│   └── template.md
└── evals/
    └── baseline-scores.json
```

### 2. Improve the framework

The architecture itself — the meta-agent pattern, auditor dimensions, evolution constraints, feedback structure — can always be refined. If you've found something that works better through real use:

- Open an issue first to discuss the change
- Explain what you tried, what happened, and why your approach is better
- Include concrete examples (before/after agent output, feedback logs, etc.)

### 3. Add or improve domain constitutions

The file `skill/references/domain-constitutions.md` contains ethical and regulatory constraint patterns by domain. If you have domain expertise:

- Add constitutions for new domains
- Improve existing patterns with more specific regulatory references
- Flag constraints that are outdated or insufficient

This is high-leverage work — constitution quality directly determines agent safety.

### 4. Improve the portable prompt

The file `prompt/agent-team-builder.md` needs to work across different LLMs. If you've tested it on a model other than Claude and found issues:

- Report what model you used and what went wrong
- Suggest prompt modifications that fix the issue without breaking other models

### 5. Report issues

Useful issue reports include:

- **What you were trying to do** (domain, team structure, specific agent)
- **What happened** (actual output)
- **What you expected** (desired output)
- **Your environment** (which LLM, Claude Code vs. direct prompt, etc.)

Safety-related issues (insufficient guardrails, agents producing harmful output, constitution gaps) are especially valued and will be prioritized.

## Contribution Standards

### Documentation

Every change needs a documented rationale. This isn't bureaucracy — it's the core principle of the framework. Your PR description should explain:

- What you changed
- Why the previous version was insufficient
- How you validated the improvement
- What side effects to watch for

### Code of Conduct

Be kind, be constructive, be honest. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

### License

All contributions must be compatible with AGPL-3.0. By submitting a PR, you agree that your contribution is licensed under the same terms.

### Review Process

1. Submit your PR with a clear description
2. Maintainers will review for architectural consistency, safety, and quality
3. Discussion happens in the PR — we'll ask questions and suggest improvements
4. Once approved, it gets merged

For team contributions, we specifically review:
- Constitution thoroughness (are the ethical constraints real and sufficient?)
- Agent prompt quality (are output standards specific and measurable?)
- Dependency graph coherence (do agent relationships make sense?)
- Auditor coverage (can the auditor actually evaluate what the meta-agent changes?)

### What We Won't Merge

- Teams with empty or generic constitutions
- Agent prompts that lack concrete output standards
- Changes that weaken safety constraints without strong justification
- Contributions that don't follow the meta-agent/auditor/constitution architecture
- Anything that violates the license

## Getting Help

If you're not sure whether your contribution idea fits, open an issue and ask. We'd rather help you shape a contribution than have you spend time on something that doesn't fit.

If you're building a team for a new domain and want early feedback on the constitution, open a draft PR — we're happy to review constitutions before you build out the full team.
