# Getting Started

This guide walks you through your first feedback cycle with an existing team.

## Prerequisites

You need **one** LLM backend. Pick the option that fits your setup — you don't need more than one.

| Option | Best for | Install |
|--------|----------|---------|
| **Claude Code CLI** | Anthropic API users | `npm install -g @anthropic-ai/claude-code` |
| **Ollama** | Local/private, no API key | [https://ollama.ai](https://ollama.ai) then `ollama pull llama3.2` |
| **llm tool** | Multi-provider via plugins | `pip install llm` |
| **Any LLM (manual)** | No tooling — just paste | Copy system prompts into ChatGPT, Claude.ai, etc. |

Once you've installed your backend, tell the framework which one to use:

```bash
cp .agent-teams.env.example .agent-teams.env
# Edit to set AGENT_PROVIDER (and AGENT_MODEL if needed)
```

If no config is present, the scripts fall back to the `claude` CLI.

## Step 1: Pick an Agent

Start with one agent, not the whole team. Choose the one whose output you can evaluate most easily.

For the marketing team, the **SDR agent** is a good starting point — it produces email sequences you can immediately judge for quality.

```bash
# Run via the bin/ runner (respects your configured provider)
./bin/run-agent.sh marketing sdr

# Or open the file and paste its contents into any LLM
# teams/marketing/agents/sdr/system-prompt.md
```

## Step 2: Give It a Real Task

Don't test with hypotheticals. Give it a real task you need done.

Example for the SDR agent:
> "I'm selling a developer productivity tool to engineering managers at mid-market SaaS companies (200-2000 employees). Our main value prop is reducing context-switching by 40%. Write a 3-email outbound sequence targeting VP Engineering personas."

## Step 3: Evaluate the Output

Read the output critically. Ask yourself:

- Would I actually send this? Why or why not?
- What's good about it?
- What's wrong with it?
- Why do I think it produced this particular output? (This is the root cause hypothesis — it's the most valuable part of your feedback.)

## Step 4: Record Feedback

```bash
./bin/new-feedback.sh marketing
# Opens a dated feedback file from the template
```

Or manually:
```bash
mkdir -p teams/marketing/feedback/$(date +%Y-%m)
cp teams/marketing/feedback/template.md teams/marketing/feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md
```

Fill in the template honestly. Be specific. "The emails are too generic" is less useful than "The opening lines don't reference anything specific about the prospect's company — they could be sent to anyone."

The **root cause hypothesis** matters most. "I think the prompt doesn't emphasize personalization enough in the output standards section" gives the meta-agent something concrete to work with.

## Step 5: Run the Full Cycle

The easiest way is to run the cycle script, which handles meta-agent, auditor, and commit in one flow:

```bash
./bin/run-cycle.sh marketing
```

This will:
1. Send your feedback to the meta-agent → produce an evolution proposal
2. Send the proposal to the auditor → produce an audit report
3. Show you a pass/flag dashboard
4. Ask for your approval before committing

### Running steps individually

```bash
# Meta-agent processes feedback and proposes changes
./bin/run-agent.sh marketing meta-agent

# Auditor reviews the proposal
./bin/run-agent.sh marketing auditor
```

## Step 6: Apply and Commit

If the auditor approves (and you agree), apply the changes to the agent's system prompt and commit:

```bash
git add -A
git commit -m "Cycle 1: Improved SDR personalization based on feedback re: generic opening lines"
```

`run-cycle.sh` offers to do this for you automatically after approval.

## Step 7: Repeat

Run the improved agent on a new task. Evaluate again. The second cycle is where you start to see whether the feedback loop is working.

After 3-5 cycles, you'll have a meaningfully better agent with a documented history of exactly how it got there.

## Tips

- **Start with one agent.** Don't try to improve the whole team at once. Get one agent good, then expand.
- **Be specific in feedback.** "Bad" is useless. "The subject lines use clickbait urgency that doesn't match our brand voice" is actionable.
- **Trust the auditor.** If it flags drift or regression risk, pay attention. It's catching things you might miss.
- **Review the CHANGELOGs.** After a few cycles, read through the changelog. It's a compressed history of what your agent has learned. This is also useful for onboarding anyone else who works with the agents.
- **Amend the constitution when needed.** If you discover a constraint that should be universal but isn't in the constitution, add it. The constitution is a living document — but only you can change it.
