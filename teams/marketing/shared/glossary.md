# Glossary

Shared terminology used across all agents. The meta-agent must maintain consistency with these definitions when evolving agent prompts.

## System Terms

- **Cycle**: One complete loop of agent output → human feedback → meta-agent modification → auditor review → commit.
- **Advisory output**: Agent-generated suggestions intended for human review. Never executed autonomously.
- **Evolution**: A meta-agent-initiated modification to an agent's configuration or prompt.
- **Drift**: When an agent's behavior gradually diverges from intended purpose, often due to cumulative prompt modifications optimizing for a proxy metric.
- **Regression**: When a modification intended to improve one capability degrades another.
- **Coherence**: The degree to which all agents' outputs are aligned and non-contradictory.

## Marketing Terms

- **ICP (Ideal Customer Profile)**: The firmographic and behavioral description of the target account.
- **Persona**: A specific buyer role within an ICP account, defined by job function, seniority, pain points, and decision authority.
- **Intent signal**: Observable behavior indicating a prospect is actively researching or evaluating solutions (site visits, content downloads, search behavior).
- **MQL (Marketing Qualified Lead)**: A lead that meets predefined behavioral and firmographic thresholds.
- **TOFU/MOFU/BOFU**: Top/Middle/Bottom of funnel — stages of buyer awareness and intent.
- **CTA (Call to Action)**: The specific action a piece of content asks the reader to take.
- **Cadence**: The timing sequence of outbound touches in a prospecting campaign.

## Agent Roles

- **Meta-Agent**: Processes human feedback and modifies agent configurations. Cannot self-modify or modify the auditor.
- **Auditor**: Independently reviews meta-agent changes for drift, regression, coherence violations, and constitutional compliance.
- **Campaign Orchestrator**: Coordinates cross-channel campaign timing, sequencing, and asset requirements.
- **Content Generation**: Produces marketing copy adapted to channel, persona, and funnel stage.
- **Analytics & Insights**: Interprets performance data, surfaces anomalies, provides predictive analysis.
- **Lead Scoring**: Evaluates prospect signals to prioritize follow-up.
- **Audience & Persona**: Segments audiences and adapts messaging to behavioral patterns.
- **Creative/Multimedia**: Produces visual and video content concepts and specifications.
- **Outbound SDR**: Generates prospecting sequences, email copy, and follow-up strategies.
- **SEO & Content Strategy**: Researches keywords, analyzes competitive landscape, produces content briefs.
