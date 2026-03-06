#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# build-team.sh — Interactive agent team scaffolder
#
# Usage: ./build-team.sh [team-type]
#
# If team-type is provided, it's used as the starting domain. Otherwise,
# the script will ask. Either way, a Q&A session walks you through defining
# agents, dependencies, ethical constraints, and then generates the full
# team directory structure.
# ============================================================================

# --- Colors & formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Output helpers ---
header()  { echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}"; echo -e "${BOLD}${BLUE}  $1${NC}"; echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}\n"; }
section() { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}\n"; }
info()    { echo -e "${DIM}$1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
prompt()  { echo -en "${BOLD}$1${NC}"; }

# --- Input helpers ---
ask() {
    local var_name="$1" prompt_text="$2" default="${3:-}"
    if [[ -n "$default" ]]; then
        prompt "$prompt_text [${default}]: "
    else
        prompt "$prompt_text: "
    fi
    read -r input
    if [[ -z "$input" && -n "$default" ]]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

ask_yn() {
    local prompt_text="$1" default="${2:-y}"
    local hint="Y/n"
    [[ "$default" == "n" ]] && hint="y/N"
    prompt "$prompt_text [$hint]: "
    read -r input
    input="${input:-$default}"
    [[ "${input,,}" == "y" || "${input,,}" == "yes" ]]
}

ask_multiline() {
    local var_name="$1" prompt_text="$2"
    echo -e "${BOLD}$prompt_text${NC}"
    info "(Enter one item per line. Empty line to finish.)"
    local items=()
    while true; do
        prompt "  → "
        read -r line
        [[ -z "$line" ]] && break
        items+=("$line")
    done
    eval "$var_name=(\"\${items[@]}\")"
}

# --- Temperature selector ---
pick_temperature() {
    local agent_type="$1"
    case "$agent_type" in
        *analyt*|*scor*|*audit*|*compliance*|*monitor*|*detect*)
            echo "0.2" ;;
        *strateg*|*plan*|*coordinat*|*orchestrat*|*manag*)
            echo "0.4" ;;
        *research*|*synthe*|*recommend*|*assess*)
            echo "0.5" ;;
        *writ*|*content*|*copy*|*communicat*|*creative*|*design*)
            echo "0.8" ;;
        *brainstorm*|*ideat*|*generat*)
            echo "0.8" ;;
        *)
            echo "0.5" ;;
    esac
}

# --- Slug helper ---
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# ============================================================================
# MAIN
# ============================================================================

header "Meta-Agent Team Builder"
info "This script will walk you through creating a new agent team."
info "It generates the full directory structure with system prompts,"
info "configurations, a constitution, auditor, meta-agent, and evals."
echo ""

# --- Determine output root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAMS_DIR="${SCRIPT_DIR}/../teams"
mkdir -p "$TEAMS_DIR"
TEAMS_DIR="$(cd "$TEAMS_DIR" && pwd)"

# ============================================================================
# STEP 1: Team Identity
# ============================================================================

section "Step 1: Team Identity"

# Accept team type from argument or ask
if [[ -n "${1:-}" ]]; then
    TEAM_DOMAIN="$1"
    echo -e "Domain: ${GREEN}${TEAM_DOMAIN}${NC} (from argument)"
else
    ask TEAM_DOMAIN "What domain is this team for? (e.g., devops, sales, customer-success, legal)"
fi

TEAM_SLUG=$(slugify "$TEAM_DOMAIN")
TEAM_DIR="${TEAMS_DIR}/${TEAM_SLUG}"

if [[ -d "$TEAM_DIR" ]]; then
    warn "Directory teams/${TEAM_SLUG} already exists."
    if ! ask_yn "Overwrite it?" "n"; then
        echo "Aborting."
        exit 0
    fi
    rm -rf "$TEAM_DIR"
fi

ask TEAM_DESCRIPTION "Describe what this team does in one sentence"

ask TEAM_OPERATIONAL_MODE "Operational mode" "advisory-only"
info "  advisory-only = agents suggest, you execute (recommended for new teams)"
info "  semi-autonomous = some agents can take limited actions"
info "  autonomous = agents act independently (requires high trust)"

# ============================================================================
# STEP 2: Define Agents
# ============================================================================

section "Step 2: Define Your Agents"

info "Now define the specialist agents for your team."
info "Aim for 4-8 agents. Each one should have a distinct responsibility."
info "Think about: what are the key functions this team needs to perform?"
echo ""

AGENTS=()
AGENT_DESCRIPTIONS=()
AGENT_CAPABILITIES=()
AGENT_TEMPERATURES=()
AGENT_DEPENDENCIES=()
AGENT_GUARDRAILS=()

agent_count=0
while true; do
    ((agent_count++))

    section "Agent #${agent_count}"

    ask agent_name "Agent name (e.g., 'incident-response', 'content-writer')"
    [[ -z "$agent_name" ]] && { ((agent_count--)); break; }

    agent_slug=$(slugify "$agent_name")

    ask agent_desc "What does this agent do? (one sentence)"

    echo ""
    info "List this agent's capabilities (3-6 recommended):"
    info "(Enter one capability per line. Empty line to finish.)"
    caps=()
    while true; do
        prompt "  → "
        read -r cap
        [[ -z "$cap" ]] && break
        caps+=("$cap")
    done

    # Auto-suggest temperature
    suggested_temp=$(pick_temperature "$agent_slug $agent_desc")
    ask agent_temp "Temperature (0.1=precise, 0.5=balanced, 0.8=creative)" "$suggested_temp"

    echo ""
    info "Which other agents does this one depend on?"
    info "(Enter agent names from the list above, or leave empty.)"
    deps=()
    if [[ ${#AGENTS[@]} -gt 0 ]]; then
        info "Agents defined so far: ${AGENTS[*]}"
        while true; do
            prompt "  dependency → "
            read -r dep
            [[ -z "$dep" ]] && break
            deps+=("$(slugify "$dep")")
        done
    fi

    echo ""
    info "What must this agent NEVER do? (domain-specific guardrails)"
    info "(Enter one guardrail per line. Empty line to finish.)"
    guards=()
    while true; do
        prompt "  ✗ "
        read -r guard
        [[ -z "$guard" ]] && break
        guards+=("$guard")
    done

    # Store everything
    AGENTS+=("$agent_slug")
    AGENT_DESCRIPTIONS+=("$agent_desc")
    AGENT_CAPABILITIES+=("$(IFS='|'; echo "${caps[*]}")")
    AGENT_TEMPERATURES+=("$agent_temp")
    AGENT_DEPENDENCIES+=("$(IFS='|'; echo "${deps[*]}")")
    AGENT_GUARDRAILS+=("$(IFS='|'; echo "${guards[*]}")")

    success "Agent '${agent_slug}' added."
    echo ""

    if [[ $agent_count -ge 8 ]]; then
        warn "You have 8 agents. More than 8 increases coherence overhead."
        if ! ask_yn "Add another agent?" "n"; then
            break
        fi
    elif [[ $agent_count -ge 4 ]]; then
        if ! ask_yn "Add another agent?" "y"; then
            break
        fi
    else
        info "You have ${agent_count} agent(s). Aim for at least 4."
    fi
done

if [[ ${#AGENTS[@]} -eq 0 ]]; then
    warn "No agents defined. Cannot generate team."
    exit 1
fi

# ============================================================================
# STEP 3: Constitution
# ============================================================================

section "Step 3: Constitution & Ethical Constraints"

info "The constitution defines inviolable rules that no agent — including"
info "the meta-agent — can violate. Only you (the human) can amend it."
echo ""

echo ""
info "List domain-specific ethical or regulatory constraints:"
info "(e.g., 'No medical diagnoses', 'Must comply with GDPR', 'No deceptive practices')"
info "(Enter one per line. Empty line to finish.)"
ETHICAL_CONSTRAINTS=()
while true; do
    prompt "  ⚖ "
    read -r constraint
    [[ -z "$constraint" ]] && break
    ETHICAL_CONSTRAINTS+=("$constraint")
done

echo ""
info "Any data handling constraints?"
info "(e.g., 'No PII without encryption', 'No cross-referencing customer data')"
DATA_CONSTRAINTS=()
while true; do
    prompt "  🔒 "
    read -r constraint
    [[ -z "$constraint" ]] && break
    DATA_CONSTRAINTS+=("$constraint")
done

# ============================================================================
# STEP 4: Evaluation Dimensions
# ============================================================================

section "Step 4: Evaluation Dimensions"

info "How will you judge agent output? Define 4-6 evaluation dimensions."
info "Common dimensions: relevance, accuracy, actionability, coherence, voice"
info "(Enter one per line in format: 'dimension - description'. Empty line to finish.)"

EVAL_DIMENSIONS=()
while true; do
    prompt "  📊 "
    read -r dim
    [[ -z "$dim" ]] && break
    EVAL_DIMENSIONS+=("$dim")
done

# Default dimensions if none provided
if [[ ${#EVAL_DIMENSIONS[@]} -eq 0 ]]; then
    info "Using default evaluation dimensions."
    EVAL_DIMENSIONS=(
        "relevance - Did the output address the actual need?"
        "accuracy - Was the information or recommendation correct?"
        "actionability - Could the human execute immediately?"
        "coherence - Did it align with other agents' output?"
    )
fi

# ============================================================================
# STEP 5: Summary & Confirmation
# ============================================================================

section "Summary"

echo -e "${BOLD}Team:${NC} ${TEAM_DOMAIN} (${TEAM_SLUG})"
echo -e "${BOLD}Description:${NC} ${TEAM_DESCRIPTION}"
echo -e "${BOLD}Mode:${NC} ${TEAM_OPERATIONAL_MODE}"
echo -e "${BOLD}Agents (${#AGENTS[@]}):${NC}"
for i in "${!AGENTS[@]}"; do
    echo -e "  ${GREEN}${AGENTS[$i]}${NC} — ${AGENT_DESCRIPTIONS[$i]} (temp: ${AGENT_TEMPERATURES[$i]})"
done
echo -e "${BOLD}Ethical constraints:${NC} ${#ETHICAL_CONSTRAINTS[@]}"
echo -e "${BOLD}Data constraints:${NC} ${#DATA_CONSTRAINTS[@]}"
echo -e "${BOLD}Eval dimensions:${NC} ${#EVAL_DIMENSIONS[@]}"
echo ""

if ! ask_yn "Generate this team?" "y"; then
    echo "Aborting."
    exit 0
fi

# ============================================================================
# GENERATION
# ============================================================================

header "Generating team: ${TEAM_SLUG}"

TODAY=$(date +%Y-%m-%d)

# --- Create directories ---
mkdir -p "$TEAM_DIR"/{shared,meta-agent,auditor,feedback/"$(date +%Y-%m)",evals}
for agent in "${AGENTS[@]}"; do
    mkdir -p "$TEAM_DIR/agents/$agent"
done

# ============================================================================
# README.md
# ============================================================================

# Build agent grid for ASCII diagram
agent_grid=""
col=0
for agent in "${AGENTS[@]}"; do
    if [[ $col -eq 0 ]]; then
        agent_grid+="│  "
    fi
    padded=$(printf "%-28s" "$agent")
    agent_grid+="$padded"
    ((col++))
    if [[ $col -eq 2 ]]; then
        agent_grid+="│\n"
        col=0
    else
        agent_grid+="│  "
    fi
done
if [[ $col -ne 0 ]]; then
    remaining=$((28 * (2 - col) + (2 - col) * 2 + 2))
    agent_grid+="$(printf '%*s' $remaining '')│\n"
fi

cat > "$TEAM_DIR/README.md" << READMEEOF
# ${TEAM_DOMAIN^} Agent Team

${TEAM_DESCRIPTION}

## Architecture

\`\`\`
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
│              Agent Team (${TEAM_OPERATIONAL_MODE^})               │
$(echo -e "$agent_grid")└─────────────────────────────────────────────────┘
\`\`\`

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

$(for i in "${!AGENTS[@]}"; do echo "- **${AGENTS[$i]}** — ${AGENT_DESCRIPTIONS[$i]}"; done)

## Getting Started

\`\`\`bash
# Run an agent
claude --system-prompt agents/${AGENTS[0]}/system-prompt.md

# Provide feedback
cp feedback/template.md feedback/\$(date +%Y-%m)/\$(date +%Y-%m-%d).md

# Process feedback with the meta-agent
claude --system-prompt meta-agent/system-prompt.md

# Audit proposed changes
claude --system-prompt auditor/system-prompt.md

# Commit approved changes
git add -A && git commit -m "Cycle N: [summary]"
\`\`\`
READMEEOF

success "README.md"

# ============================================================================
# Constitution
# ============================================================================

cat > "$TEAM_DIR/shared/constitution.md" << CONSTEOF
# Constitution

These constraints are **inviolable**. The meta-agent cannot modify, weaken, or circumvent them. The auditor agent monitors compliance. Only the human operator may amend this document.

---

## 1. Scope of Authority

- **Agents are ${TEAM_OPERATIONAL_MODE}.** $(if [[ "$TEAM_OPERATIONAL_MODE" == "advisory-only" ]]; then echo "No agent may take autonomous action in the real world without explicit human approval."; else echo "Agents operate within their defined autonomy level. Actions beyond advisory require explicit human approval."; fi)
- **The meta-agent may only modify:** agent system prompts, agent.yaml configuration, and tool definitions.
- **The meta-agent may NOT modify:** this constitution, the auditor's configuration or prompt, or its own system prompt.
- **The auditor operates independently.** The meta-agent has no authority over the auditor's configuration, evaluation criteria, or findings.

## 2. Ethical Boundaries

$(if [[ ${#ETHICAL_CONSTRAINTS[@]} -gt 0 ]]; then
    for constraint in "${ETHICAL_CONSTRAINTS[@]}"; do
        echo "- ${constraint}"
    done
else
    echo "- No agent may generate deceptive, misleading, or fabricated content."
    echo "- All recommendations must be honest about confidence levels and limitations."
    echo "- Agents must respect applicable regulatory requirements for this domain."
fi)

## 3. Evolution Rules

- Every agent modification must include a **written rationale** referencing specific feedback that motivated the change.
- No modification may be applied without an auditor review cycle.
- The meta-agent must preserve a **rollback path** — previous prompt versions remain in git history, and the CHANGELOG must document what was changed and why.
- The meta-agent may not optimize for a single metric at the expense of overall system coherence.
- Modifications must be **incremental**. No single commit may rewrite more than 30% of an agent's system prompt.

## 4. Data Handling

$(if [[ ${#DATA_CONSTRAINTS[@]} -gt 0 ]]; then
    for constraint in "${DATA_CONSTRAINTS[@]}"; do
        echo "- ${constraint}"
    done
else
    echo "- Agents must not process, store, or leverage personal data beyond what the human operator has explicitly authorized."
    echo "- All data sources referenced by agents must be documented in the agent's agent.yaml."
fi)

## 5. Inter-Agent Coherence

- Agent outputs must not contradict each other.
- The meta-agent is responsible for cross-agent coherence. The auditor verifies it.
- When agents have conflicting recommendations, the conflict must be surfaced to the human operator — not silently resolved by the meta-agent.

---

**Last amended:** ${TODAY}
**Amended by:** Human operator (initial version)
CONSTEOF

success "shared/constitution.md"

# ============================================================================
# Glossary
# ============================================================================

cat > "$TEAM_DIR/shared/glossary.md" << GLOSSEOF
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
$(for i in "${!AGENTS[@]}"; do echo "- **${AGENTS[$i]}**: ${AGENT_DESCRIPTIONS[$i]}"; done)

## Domain Terms

<!-- Add domain-specific terminology here as agents begin using specialized language -->
GLOSSEOF

success "shared/glossary.md"

# ============================================================================
# Meta-Agent
# ============================================================================

cat > "$TEAM_DIR/meta-agent/system-prompt.md" << 'METAEOF'
# Meta-Agent System Prompt

You are the Meta-Agent — the manager and trainer of a team of AI agents. Your sole purpose is to interpret structured human feedback and translate it into precise, incremental improvements to agent configurations and prompts.

## Your Authority

You may modify:
- Agent system prompts (`agents/<n>/system-prompt.md`)
- Agent configurations (`agents/<n>/agent.yaml`)
- Agent tool definitions

You may NOT modify:
- This system prompt
- The auditor agent's configuration or prompt
- The constitution (`shared/constitution.md`)
- The glossary (suggest changes to the human instead)

## How You Process Feedback

When given feedback from `/feedback/`, follow this process:

### 1. Categorize the Feedback
For each piece of feedback, determine:
- **Which agent(s)** it applies to
- **What type** it is: output quality, relevance, tone, accuracy, missing context, over/under-scoping, coherence with other agents
- **Severity**: minor refinement, significant correction, or fundamental misalignment

### 2. Diagnose Root Cause
Before modifying anything, articulate WHY the agent produced the output that received this feedback. Possible causes:
- Prompt is too vague in a specific area
- Prompt is over-constrained, preventing useful output
- Agent lacks context it needs (missing from config)
- Agent is optimizing for the wrong thing
- Inter-agent misalignment

### 3. Propose Modifications
For each proposed change:
- State which file you're modifying
- Quote the specific section being changed
- Provide the new version
- Write a rationale that references the specific feedback item(s)
- Assess potential side effects on other agents

### 4. Document in CHANGELOG
Append to the relevant agent's `CHANGELOG.md`:
```
## [YYYY-MM-DD] - Cycle N

### Changed
- <what changed>

### Rationale
- <why, referencing specific feedback>

### Feedback Reference
- feedback/YYYY-MM/YYYY-MM-DD.md, item N

### Risk Assessment
- <potential side effects or regressions to watch>
```

## Evolution Constraints

- **Incremental changes only.** Never rewrite more than 30% of a prompt in one cycle.
- **One variable at a time when possible.** If you change an agent's tone AND scope simultaneously, you can't attribute feedback to either change.
- **Preserve what works.** If feedback is positive on one aspect, explicitly protect that aspect when making other modifications.
- **Cross-agent coherence.** Before modifying any agent, check whether the change could create contradictions with other agents.
- **Never infer feedback that wasn't given.** Only act on what the human actually said.

## Output Format

```
# Evolution Proposal — Cycle [N]

## Feedback Summary
[Synthesize the feedback you're working from]

## Proposed Changes

### Agent: [name]
**File:** [path]
**Section:** [quote existing text]
**Proposed:** [new text]
**Rationale:** [why this change addresses the feedback]
**Side Effects:** [what to watch for]

## Cross-Agent Impact
[Any coherence considerations]

## Deferred
[Any feedback you're intentionally NOT acting on yet, and why]
```

## What You Must Never Do

- Optimize for engagement metrics at the expense of ethical constraints
- Resolve inter-agent conflicts silently — always surface them
- Apply changes without documented rationale
- Confabulate justifications — if you're uncertain why a change will help, say so
- Modify agents based on your own judgment without corresponding human feedback
METAEOF

cat > "$TEAM_DIR/meta-agent/agent.yaml" << METAYAMLEOF
name: meta-agent
description: Interprets human feedback and evolves agent configurations
model: claude-sonnet-4-20250514
temperature: 0.3

context_sources:
  - shared/constitution.md
  - shared/glossary.md
  - feedback/
  - evals/baseline-scores.json

output_format: markdown
output_target: stdout

constraints:
  max_prompt_change_pct: 30
  require_rationale: true
  require_feedback_reference: true
  require_side_effect_assessment: true
METAYAMLEOF

cat > "$TEAM_DIR/meta-agent/CHANGELOG.md" << METACLEOF
# Meta-Agent Changelog

Only the human operator may modify the meta-agent. All changes are documented here.

## [${TODAY}] - Initial Version

### Created
- System prompt with feedback processing workflow
- Evolution constraints and output format
- Agent configuration
METACLEOF

success "meta-agent/"

# ============================================================================
# Auditor
# ============================================================================

cat > "$TEAM_DIR/auditor/system-prompt.md" << 'AUDITEOF'
# Auditor Agent System Prompt

You are the Auditor — an independent reviewer of the meta-agent's decisions. Your purpose is to ensure that agent evolution stays aligned with the constitution, maintains cross-agent coherence, and genuinely improves agent quality based on human feedback.

You are NOT subordinate to the meta-agent. You report directly to the human operator.

## What You Review

After each evolution cycle, you receive:
1. The meta-agent's proposed changes
2. The human feedback that motivated those changes
3. The current state of all affected agents
4. The constitution
5. Historical eval scores

## Evaluation Dimensions

### 1. Constitutional Compliance
- Does the change comply with all constraints in the constitution?
- Does it maintain the operational mode (advisory-only, etc.)?
- Does it respect ethical boundaries?

### 2. Feedback Fidelity
- Does the change actually address the human's feedback?
- Is the meta-agent over-interpreting (changing things not mentioned)?
- Is the meta-agent under-interpreting (superficial changes)?
- Is the rationale honest or confabulated?

### 3. Drift Detection
- Is this change moving an agent away from its core purpose?
- Is the meta-agent repeatedly optimizing for one dimension at the expense of others?
- Compare against the original version — is cumulative drift significant?

### 4. Regression Risk
- Could this change degrade an uncomplained-about capability?
- Does it remove language previously added for good reason?
- Check the CHANGELOG — is this area oscillating back and forth?

### 5. Cross-Agent Coherence
- Does this change create contradictions with other agents?
- Are shared definitions still consistent?
- Are dependency relationships still valid?

### 6. Change Magnitude
- Does the change exceed the 30% modification threshold?
- Should it be staged across multiple cycles?
- Is the meta-agent making too many simultaneous changes?

## Output Format

```
# Audit Report — Cycle [N]

## Summary
[Overall assessment: approve, approve with concerns, or flag for human review]

## Constitutional Compliance: [PASS / FLAG]
## Feedback Fidelity: [PASS / OVER-INTERPRETED / UNDER-INTERPRETED]
## Drift Assessment: [STABLE / MINOR DRIFT / SIGNIFICANT DRIFT]
## Regression Risk: [LOW / MODERATE / HIGH]
## Coherence Check: [COHERENT / CONFLICT DETECTED]
## Change Magnitude: [WITHIN BOUNDS / EXCEEDS THRESHOLD]

## Recommendations
[Approve as-is, modify before applying, defer, or reject]

## Items for Human Attention
[Anything requiring human judgment]
```

## What You Must Never Do

- Approve changes that violate the constitution
- Defer to the meta-agent's judgment when you have concerns
- Suppress findings to avoid conflict
- Make modifications yourself — you audit, you do not change
AUDITEOF

cat > "$TEAM_DIR/auditor/agent.yaml" << AUDITYAMLEOF
name: auditor
description: Independent reviewer of meta-agent evolution decisions
model: claude-sonnet-4-20250514
temperature: 0.2

context_sources:
  - shared/constitution.md
  - shared/glossary.md
  - evals/baseline-scores.json

output_format: markdown
output_target: stdout

independence:
  modifiable_by: human_only
  reports_to: human_operator
  authority: review_and_recommend
AUDITYAMLEOF

cat > "$TEAM_DIR/auditor/CHANGELOG.md" << AUDITCLEOF
# Auditor Changelog

Only the human operator may modify the auditor.

## [${TODAY}] - Initial Version

### Created
- System prompt with six-dimension evaluation framework
- Agent configuration with independence constraints
AUDITCLEOF

success "auditor/"

# ============================================================================
# Specialist Agents
# ============================================================================

for i in "${!AGENTS[@]}"; do
    agent="${AGENTS[$i]}"
    desc="${AGENT_DESCRIPTIONS[$i]}"
    temp="${AGENT_TEMPERATURES[$i]}"

    # Parse capabilities
    IFS='|' read -ra caps <<< "${AGENT_CAPABILITIES[$i]}"

    # Parse dependencies
    IFS='|' read -ra deps <<< "${AGENT_DEPENDENCIES[$i]}"

    # Parse guardrails
    IFS='|' read -ra guards <<< "${AGENT_GUARDRAILS[$i]}"

    # Build capabilities section
    cap_section=""
    cap_num=1
    for cap in "${caps[@]}"; do
        [[ -n "$cap" ]] && cap_section+="${cap_num}. **${cap}**
"
        ((cap_num++))
    done

    # Build guardrails section
    guard_section=""
    for guard in "${guards[@]}"; do
        [[ -n "$guard" ]] && guard_section+="- ${guard}
"
    done
    if [[ -z "$guard_section" ]]; then
        guard_section="- Do not fabricate data, statistics, or claims
- Do not present uncertain information as definitive
- Flag when a request exceeds your capability or domain
"
    fi

    # Build dependencies for yaml
    dep_yaml=""
    dep_context=""
    for dep in "${deps[@]}"; do
        if [[ -n "$dep" ]]; then
            dep_yaml+="  - ${dep}
"
            dep_context+="  - agents/${dep}/system-prompt.md
"
        fi
    done

    # --- System Prompt ---
    cat > "$TEAM_DIR/agents/$agent/system-prompt.md" << AGENTEOF
# ${agent} — System Prompt

You are the ${agent} agent for the ${TEAM_DOMAIN} team. ${desc}

All output is advisory — the human operator reviews and decides what to execute.

## Your Capabilities

${cap_section}
## Output Standards

<!-- TODO: Define concrete, measurable output standards for this agent.
     Not generic platitudes — specific formats, lengths, structures.
     Example: "Reports must include executive summary under 100 words"
     Example: "Recommendations must include confidence level (high/medium/low)"
-->

## What You Must Never Do

${guard_section}
## Context You Need

<!-- TODO: Define what information this agent needs to produce good output.
     This guides the human on what to provide and tells the meta-agent
     what context gaps to fill. -->

## How You'll Be Evaluated

Your output will be judged on:
$(for dim in "${EVAL_DIMENSIONS[@]}"; do
    dim_name="${dim%% - *}"
    dim_desc="${dim#* - }"
    echo "- **${dim_name}**: ${dim_desc}"
done)
AGENTEOF

    # --- Agent YAML ---
    cat > "$TEAM_DIR/agents/$agent/agent.yaml" << AGENTYAMLEOF
name: ${agent}
description: ${desc}
model: claude-sonnet-4-20250514
temperature: ${temp}

context_sources:
  - shared/constitution.md
  - shared/glossary.md
${dep_context}
capabilities:
$(for cap in "${caps[@]}"; do [[ -n "$cap" ]] && echo "  - $(slugify "$cap")"; done)

dependencies:
${dep_yaml:-  [] # No dependencies}
output_format: markdown
output_target: stdout
AGENTYAMLEOF

    # --- CHANGELOG ---
    cat > "$TEAM_DIR/agents/$agent/CHANGELOG.md" << AGENTCLEOF
# ${agent} Changelog

## [${TODAY}] - Initial Version

### Created
- System prompt (v1)
- Agent configuration

### Rationale
- Initial system setup. No feedback-driven changes yet.
AGENTCLEOF

    success "agents/${agent}/"
done

# ============================================================================
# Feedback Template
# ============================================================================

cat > "$TEAM_DIR/feedback/template.md" << 'FBEOF'
# Feedback — YYYY-MM-DD

## Cycle: [N]

---

### Item 1

**Agent:** [agent name]
**Task:** [what you asked the agent to do]
**Rating:** [1-5: 1=unusable, 2=significant issues, 3=usable with edits, 4=good with minor tweaks, 5=excellent as-is]

**What worked:**
-

**What didn't work:**
-

**Root cause hypothesis:**
-

**Desired behavior:**
-

---

## Cross-Agent Observations

[Any observations about how agents interact — contradictions, misalignment, or synergy]

## System-Level Notes

[Anything about the overall workflow, process, or architecture that needs attention]
FBEOF

success "feedback/template.md"

# ============================================================================
# Baseline Scores
# ============================================================================

# Build agents JSON
agents_json=""
for agent in "${AGENTS[@]}"; do
    [[ -n "$agents_json" ]] && agents_json+=","
    agents_json+="
    \"${agent}\": {
      \"version\": \"1.0.0\",
      \"cycles_completed\": 0,
      \"scores\": [],
      \"rolling_average\": null,
      \"trend\": null
    }"
done

# Build dimensions JSON
dims_json=""
for dim in "${EVAL_DIMENSIONS[@]}"; do
    dim_name="${dim%% - *}"
    dim_desc="${dim#* - }"
    [[ -n "$dims_json" ]] && dims_json+=","
    dims_json+="
      \"${dim_name}\": \"${dim_desc}\""
done

cat > "$TEAM_DIR/evals/baseline-scores.json" << EVALEOF
{
  "metadata": {
    "created": "${TODAY}",
    "last_updated": "${TODAY}",
    "current_cycle": 0,
    "notes": "Initial baseline — no feedback cycles completed"
  },
  "agents": {${agents_json}
  },
  "score_schema": {
    "rating": "1-5 from human feedback",
    "dimensions": {${dims_json}
    }
  }
}
EVALEOF

success "evals/baseline-scores.json"

# ============================================================================
# Done
# ============================================================================

header "Team Generated Successfully"

echo -e "${BOLD}Location:${NC} ${TEAM_DIR}"
echo ""
echo -e "${BOLD}Files created:${NC}"
find "$TEAM_DIR" -type f | sort | while read -r f; do
    echo -e "  ${DIM}${f#${TEAM_DIR}/}${NC}"
done

echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. Review and customize the ${YELLOW}TODO${NC} sections in each agent's system-prompt.md"
echo -e "  2. Add domain-specific terms to ${CYAN}shared/glossary.md${NC}"
echo -e "  3. Review the constitution at ${CYAN}shared/constitution.md${NC}"
echo -e "  4. Run your first agent:"
echo -e "     ${DIM}claude --system-prompt ${TEAM_DIR}/agents/${AGENTS[0]}/system-prompt.md${NC}"
echo -e "  5. Record feedback and start the improvement cycle"
echo ""
echo -e "${GREEN}Happy building.${NC}"
