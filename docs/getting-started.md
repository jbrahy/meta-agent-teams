# Getting Started

This guide walks you through your first feedback cycle with an existing team.

## Prerequisites

You need access to a capable LLM. The framework is designed for Claude Code but works with any LLM that can accept a system prompt.

**Option A: Claude Code (recommended)**
```bash
# Install Claude Code if you haven't
npm install -g @anthropic-ai/claude-code
```

**Option B: Any LLM**
Copy-paste agent system prompts as the first message or system prompt in your LLM of choice.

## Step 1: Pick an Agent

Start with one agent, not the whole team. Choose the one whose output you can evaluate most easily.

For the marketing team, the **SDR agent** is a good starting point — it produces email sequences you can immediately judge for quality.

```bash
# Claude Code
claude --system-prompt teams/marketing/agents/sdr/system-prompt.md

# Or open the file and paste its contents into your LLM
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
# Create today's feedback file
mkdir -p teams/marketing/feedback/$(date +%Y-%m)
cp teams/marketing/feedback/template.md teams/marketing/feedback/$(date +%Y-%m)/$(date +%Y-%m-%d).md
```

Fill in the template honestly. Be specific. "The emails are too generic" is less useful than "The opening lines don't reference anything specific about the prospect's company — they could be sent to anyone."

The **root cause hypothesis** matters most. "I think the prompt doesn't emphasize personalization enough in the output standards section" gives the meta-agent something concrete to work with.

## Step 5: Run the Meta-Agent

Feed the meta-agent your feedback along with the current state of the agent you're improving:

```bash
claude --system-prompt teams/marketing/meta-agent/system-prompt.md
```

Provide it with:
1. Your feedback file
2. The current agent system prompt
3. The constitution

The meta-agent will propose specific modifications with rationale.

## Step 6: Run the Auditor

Before applying changes, run the auditor:

```bash
claude --system-prompt teams/marketing/auditor/system-prompt.md
```

Provide it with:
1. The meta-agent's proposed changes
2. Your original feedback
3. The current agent state
4. The constitution

The auditor will assess the proposal across six dimensions and recommend approve, modify, or reject.

## Step 7: Apply and Commit

If the auditor approves (and you agree), apply the changes to the agent's system prompt and commit:

```bash
git add -A
git commit -m "Cycle 1: Improved SDR personalization based on feedback re: generic opening lines"
```

## Step 8: Repeat

Run the improved agent on a new task. Evaluate again. The second cycle is where you start to see whether the feedback loop is working.

After 3-5 cycles, you'll have a meaningfully better agent with a documented history of exactly how it got there.

## Tips

- **Start with one agent.** Don't try to improve the whole team at once. Get one agent good, then expand.
- **Be specific in feedback.** "Bad" is useless. "The subject lines use clickbait urgency that doesn't match our brand voice" is actionable.
- **Trust the auditor.** If it flags drift or regression risk, pay attention. It's catching things you might miss.
- **Review the CHANGELOGs.** After a few cycles, read through the changelog. It's a compressed history of what your agent has learned. This is also useful for onboarding anyone else who works with the agents.
- **Amend the constitution when needed.** If you discover a constraint that should be universal but isn't in the constitution, add it. The constitution is a living document — but only you can change it.
