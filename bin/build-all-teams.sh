#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

header()  { echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}"; echo -e "${BOLD}${BLUE}  $1${NC}"; echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}\n"; }
info()    { echo -e "${DIM}$1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

titleize() {
    local value="$1"
    value="${value//-/ }"
    echo "$value" | awk '{
        for (i = 1; i <= NF; i++) {
            token = $i
            if (token == "ai" || token == "bi" || token == "ml" || token == "qa" || token == "pr" || token == "pmo" || token == "sre" || token == "seo" || token == "ux" || token == "crm" || token == "it" || token == "esg") {
                token = toupper(token)
            } else if (token == "fp" && i < NF && $(i+1) == "a") {
                token = "FP&A"
                i++
            } else if (token == "m" && i < NF && $(i+1) == "a") {
                token = "M&A"
                i++
            } else {
                token = toupper(substr(token,1,1)) substr(token,2)
            }
            printf "%s%s", token, (i < NF ? OFS : ORS)
        }
    }'
}

pick_operational_mode() {
    local team_slug="$1"
    case "$team_slug" in
        *compliance*|*risk*|*legal*|*security*|*clinical*|*medical*|*pharmacy*|*regulatory*|*trust-and-safety*|*incident-response*|*public-affairs*|*contracts*)
            echo "advisory-only" ;;
        *operations*|*onboarding*|*support*|*help-desk*|*devops*|*sre*|*engineering*|*qa*|*logistics*|*documentation*|*knowledge-management*|*program-management*|*project-design-team*)
            echo "semi-autonomous" ;;
        *)
            echo "advisory-only" ;;
    esac
}

pick_temperature() {
    local agent_type="$1"
    case "$agent_type" in
        *analyt*|*scor*|*audit*|*compliance*|*monitor*|*detect*|*risk*|*qa*|*quality*|*review*|*check*) echo "0.2" ;;
        *strateg*|*plan*|*coordinat*|*orchestrat*|*manag*|*priorit*|*triage*) echo "0.4" ;;
        *research*|*synthe*|*recommend*|*assess*|*insight*|*advisor*|*analysis*) echo "0.5" ;;
        *writ*|*content*|*copy*|*communicat*|*creative*|*design*|*brand*|*story*|*narrative*) echo "0.8" ;;
        *brainstorm*|*ideat*|*generat*) echo "0.8" ;;
        *) echo "0.5" ;;
    esac
}

join_by() {
    local delimiter="$1"
    shift
    local first=1
    for item in "$@"; do
        if [[ $first -eq 1 ]]; then
            printf "%s" "$item"
            first=0
        else
            printf "%s%s" "$delimiter" "$item"
        fi
    done
}

add_unique() {
    local candidate="$1"
    shift
    for existing in "$@"; do
        [[ "$existing" == "$candidate" ]] && return 1
    done
    return 0
}

team_description() {
    local team_slug="$1"
    local team_title="$2"
    case "$team_slug" in
        *engineering*|*devops*|*platform*|*sre*|*qa*|*internal-tools*|*implementation*|*architecture*|*open-source-maintenance*)
            echo "This team helps plan, review, and improve ${team_title} work through structured specialist agents."
            ;;
        *marketing*|*brand*|*content*|*seo*|*newsletter*|*social*|*thought-leadership*|*demand-generation*|*growth*)
            echo "This team helps produce, refine, and evaluate ${team_title} initiatives using coordinated specialist agents."
            ;;
        *sales*|*account*|*partner*|*partnership*|*revenue*|*pipeline*|*closing*|*objection*)
            echo "This team helps improve ${team_title} outcomes through research, strategy, execution support, and quality review."
            ;;
        *operations*|*program*|*project*|*onboarding*|*support*|*customer*|*success*|*help-desk*|*workflow*|*calendar*|*meeting*)
            echo "This team helps run ${team_title} workflows with clear planning, coordination, diagnostics, and continuous improvement."
            ;;
        *legal*|*compliance*|*risk*|*policy*|*regulatory*|*trust-and-safety*|*public-affairs*|*contracts*)
            echo "This team helps analyze ${team_title} work carefully with strong guardrails, review steps, and documentation."
            ;;
        *research*|*science*|*clinical*|*medical*|*biotech*|*pharmacy*|*academic*|*student*|*curriculum*|*learning*|*instructional*)
            echo "This team helps support ${team_title} decisions with synthesis, evaluation, planning, and quality assurance."
            ;;
        *)
            echo "This team helps manage ${team_title} work with specialist agents that research, plan, review, and improve outcomes."
            ;;
    esac
}

build_team_constraints() {
    local team_slug="$1"
    ETHICAL_CONSTRAINTS=()
    DATA_CONSTRAINTS=()
    EVAL_DIMENSIONS=()

    ETHICAL_CONSTRAINTS+=("Do not fabricate facts, metrics, citations, or stakeholder positions.")
    ETHICAL_CONSTRAINTS+=("Escalate material ambiguity, conflicts, and high-risk recommendations to the human operator.")

    DATA_CONSTRAINTS+=("Do not store or expose secrets, credentials, or private data outside approved files and workflows.")
    DATA_CONSTRAINTS+=("Use least-privilege access assumptions when describing actions, tools, or data handling.")

    EVAL_DIMENSIONS+=("relevance - Did the output address the actual need for this team?")
    EVAL_DIMENSIONS+=("accuracy - Was the analysis or recommendation correct and well-supported?")
    EVAL_DIMENSIONS+=("actionability - Could the human operator use the output immediately?")
    EVAL_DIMENSIONS+=("coherence - Did the output align with the rest of the team?")

    case "$team_slug" in
        *legal*|*compliance*|*risk*|*security*|*trust-and-safety*|*policy*|*regulatory*|*contracts*|*public-affairs*)
            ETHICAL_CONSTRAINTS+=("Do not present legal, regulatory, security, or policy conclusions as final approval without human review.")
            DATA_CONSTRAINTS+=("Do not disclose regulated, privileged, or sensitive case data to unauthorized parties.")
            EVAL_DIMENSIONS+=("risk-awareness - Did the output identify important risk, compliance, or policy concerns?")
            ;;
        *medical*|*clinical*|*pharmacy*|*care*|*scientific*|*biotech*)
            ETHICAL_CONSTRAINTS+=("Do not provide diagnosis, treatment instructions, or patient-specific medical decisions without qualified human review.")
            DATA_CONSTRAINTS+=("Do not expose patient, participant, or health-related data without explicit authorization and appropriate safeguards.")
            EVAL_DIMENSIONS+=("safety - Did the output remain appropriately cautious for health-related work?")
            ;;
        *engineering*|*devops*|*platform*|*sre*|*qa*|*architecture*|*internal-tools*|*implementation*|*mobile*|*front-end*|*back-end*|*full-stack*|*ml-engineering*|*data-engineering*)
            ETHICAL_CONSTRAINTS+=("Do not recommend destructive production changes without rollback, observability, and human approval.")
            DATA_CONSTRAINTS+=("Do not expose infrastructure details, keys, tokens, or security-sensitive implementation details in outputs.")
            EVAL_DIMENSIONS+=("technical-soundness - Were the technical recommendations feasible and appropriately scoped?")
            ;;
        *marketing*|*content*|*brand*|*newsletter*|*social*|*thought-leadership*|*seo*|*pr-and-communications*|*voice-consistency*|*narrative*)
            ETHICAL_CONSTRAINTS+=("Do not use deceptive persuasion, fake testimonials, or unsupported claims.")
            EVAL_DIMENSIONS+=("audience-fit - Did the output match audience needs, positioning, and tone?")
            ;;
        *sales*|*account*|*revenue*|*customer*|*partner*|*partnership*|*pipeline*|*closing*|*objection*|*retention*|*renewals*)
            ETHICAL_CONSTRAINTS+=("Do not misrepresent pricing, capabilities, customer commitments, or business outcomes.")
            EVAL_DIMENSIONS+=("commercial-value - Did the output improve likely business outcomes without overpromising?")
            ;;
        *operations*|*program*|*project*|*logistics*|*procurement*|*manufacturing*|*supply-chain*|*restaurant-operations*|*property-management*)
            ETHICAL_CONSTRAINTS+=("Do not recommend operational shortcuts that hide risk, quality issues, or missing approvals.")
            EVAL_DIMENSIONS+=("operational-clarity - Did the output reduce confusion and improve execution clarity?")
            ;;
    esac
}

build_agent_catalog() {
    local team_slug="$1"
    AGENTS=()
    AGENT_DESCRIPTIONS=()
    AGENT_CAPABILITIES=()
    AGENT_TEMPERATURES=()
    AGENT_DEPENDENCIES=()
    AGENT_GUARDRAILS=()

    local specialist_one="research-and-context"
    local specialist_two="strategy-and-planning"
    local specialist_three="execution-support"
    local specialist_four="quality-and-risk-review"

    case "$team_slug" in
        *marketing*|*content*|*brand*|*newsletter*|*social*|*seo*|*thought-leadership*|*editorial*|*voice-consistency*|*narrative*|*creative-design*|*content-design*)
            specialist_one="audience-and-insight-research"
            specialist_two="strategy-and-positioning"
            specialist_three="content-and-campaign-production"
            specialist_four="quality-and-brand-review"
            ;;
        *sales*|*account*|*revenue*|*partner*|*partnership*|*pipeline*|*closing*|*objection*|*retention*|*renewals*|*channel-sales*)
            specialist_one="account-and-opportunity-research"
            specialist_two="deal-strategy-and-prioritization"
            specialist_three="pipeline-and-follow-up-execution"
            specialist_four="quality-and-risk-review"
            ;;
        *engineering*|*devops*|*platform*|*sre*|*qa*|*architecture*|*internal-tools*|*implementation*|*mobile*|*front-end*|*back-end*|*full-stack*|*ml-engineering*|*data-engineering*|*data-science*|*open-source-maintenance*)
            specialist_one="requirements-and-context-analysis"
            specialist_two="solution-design-and-planning"
            specialist_three="implementation-and-delivery-support"
            specialist_four="quality-security-and-reliability-review"
            ;;
        *operations*|*program*|*project*|*workflow*|*logistics*|*procurement*|*manufacturing*|*supply-chain*|*restaurant-operations*|*property-management*|*calendar*|*meeting*|*weekly-planning*|*daily-priorities*|*task-triage*)
            specialist_one="intake-and-diagnostics"
            specialist_two="planning-and-coordination"
            specialist_three="execution-support"
            specialist_four="quality-and-exception-review"
            ;;
        *legal*|*compliance*|*risk*|*security*|*trust-and-safety*|*policy*|*regulatory*|*contracts*|*public-affairs*)
            specialist_one="facts-and-context-analysis"
            specialist_two="policy-and-decision-support"
            specialist_three="documentation-and-communication-support"
            specialist_four="risk-and-compliance-review"
            ;;
        *medical*|*clinical*|*pharmacy*|*care*|*scientific*|*biotech*|*research*|*academic*|*student*|*curriculum*|*learning*|*instructional*)
            specialist_one="evidence-and-context-review"
            specialist_two="planning-and-recommendation-support"
            specialist_three="documentation-and-coordination-support"
            specialist_four="quality-safety-and-compliance-review"
            ;;
    esac

    local names=("intake-and-triage" "$specialist_one" "$specialist_two" "$specialist_three" "$specialist_four")
    local name
    for name in "${names[@]}"; do
        local desc temp deps caps guards
        case "$name" in
            intake-and-triage)
                desc="Clarifies incoming requests, identifies missing context, scopes the work, and routes tasks to the right specialist agents."
                caps=("Summarize the request and desired outcome" "Identify missing information, assumptions, and constraints" "Break work into discrete subproblems" "Route work to the right specialists in a sensible order")
                deps=()
                guards=("Do not invent missing requirements when they have not been provided" "Do not hide ambiguity, blockers, or tradeoffs from the human operator")
                ;;
            audience-and-insight-research)
                desc="Researches audience needs, market signals, competitive context, and supporting inputs for messaging decisions."
                caps=("Identify audience segments, intents, and pain points" "Summarize market, competitor, and customer signals" "Extract reusable insights and message opportunities" "Highlight evidence gaps and research caveats")
                deps=("intake-and-triage")
                guards=("Do not fabricate audience evidence or competitive claims" "Do not overgeneralize weak signals into certainty")
                ;;
            strategy-and-positioning)
                desc="Turns research into messaging strategy, prioritization, positioning, and campaign direction."
                caps=("Recommend positioning and narrative direction" "Translate findings into priorities and tradeoffs" "Outline campaign or content strategy options" "Show why a recommendation fits the audience and business goal")
                deps=("intake-and-triage" "audience-and-insight-research")
                guards=("Do not recommend deceptive messaging or unsupported product claims" "Do not ignore brand, audience, or channel constraints")
                ;;
            content-and-campaign-production)
                desc="Produces structured deliverables, drafts, outlines, and execution support for campaigns and content workflows."
                caps=("Draft campaign or content assets in the requested format" "Turn strategy into execution-ready deliverables" "Adapt materials for specific channels or audiences" "Surface open questions that block final production")
                deps=("intake-and-triage" "strategy-and-positioning")
                guards=("Do not claim unverified facts or performance outcomes" "Do not produce final deliverables that ignore the approved strategy")
                ;;
            quality-and-brand-review)
                desc="Reviews outputs for clarity, consistency, accuracy, tone, and fit with brand or content standards."
                caps=("Review outputs for clarity and consistency" "Check for unsupported claims, awkward phrasing, or tone issues" "Flag mismatches with strategy, audience, or brand guidelines" "Recommend focused revisions")
                deps=("intake-and-triage" "strategy-and-positioning" "content-and-campaign-production")
                guards=("Do not approve misleading or inconsistent messaging" "Do not silently rewrite core strategy decisions without surfacing them")
                ;;
            account-and-opportunity-research)
                desc="Researches accounts, stakeholders, pipeline context, and opportunity signals to support commercial decisions."
                caps=("Summarize account context and stakeholder needs" "Identify opportunity signals, blockers, and risks" "Spot expansion, retention, or follow-up opportunities" "Distill actionable commercial context")
                deps=("intake-and-triage")
                guards=("Do not fabricate account intelligence or stakeholder intent" "Do not present weak signals as firm commitments")
                ;;
            deal-strategy-and-prioritization)
                desc="Recommends opportunity prioritization, deal strategy, next steps, and tradeoffs."
                caps=("Prioritize deals or accounts based on context" "Recommend next steps, sequencing, and tradeoffs" "Outline deal risks, dependencies, and decision points" "Translate account context into strategy")
                deps=("intake-and-triage" "account-and-opportunity-research")
                guards=("Do not recommend misleading pricing, positioning, or commitments" "Do not ignore material risks to close probability or customer trust")
                ;;
            pipeline-and-follow-up-execution)
                desc="Supports execution by preparing follow-ups, summaries, plans, and structured next-step materials."
                caps=("Draft follow-up materials and action plans" "Convert strategy into execution-ready tasks" "Track dependencies, owners, and deadlines" "Surface stalled motion or missing inputs")
                deps=("intake-and-triage" "deal-strategy-and-prioritization")
                guards=("Do not send or imply commitments that were not approved" "Do not hide overdue, blocked, or risky next steps")
                ;;
            requirements-and-context-analysis)
                desc="Clarifies requirements, constraints, system context, and technical dependencies before work begins."
                caps=("Summarize requirements, assumptions, and constraints" "Identify architecture, dependency, or integration considerations" "Call out missing technical context and edge cases" "Break technical requests into manageable workstreams")
                deps=("intake-and-triage")
                guards=("Do not assume hidden requirements are true without evidence" "Do not ignore operational, security, or reliability constraints")
                ;;
            solution-design-and-planning)
                desc="Designs implementation approaches, architecture options, sequencing, and technical tradeoffs."
                caps=("Recommend implementation approaches and tradeoffs" "Outline architecture or workflow decisions" "Sequence work into practical milestones" "Explain why a design fits the stated constraints")
                deps=("intake-and-triage" "requirements-and-context-analysis")
                guards=("Do not recommend unsafe, destructive, or unreviewed production actions" "Do not optimize one technical dimension while ignoring the others")
                ;;
            implementation-and-delivery-support)
                desc="Turns approved plans into execution-ready tasks, deliverables, and implementation guidance."
                caps=("Translate plans into concrete implementation steps" "Draft code-adjacent, process, or delivery guidance" "Track blockers, dependencies, and rollout concerns" "Prepare handoff notes and execution checklists")
                deps=("intake-and-triage" "solution-design-and-planning")
                guards=("Do not present untested implementation details as production-safe" "Do not omit rollback, validation, or observability considerations when relevant")
                ;;
            quality-security-and-reliability-review)
                desc="Reviews outputs for correctness, quality, security, resilience, and operational soundness."
                caps=("Review for correctness, reliability, and maintainability" "Flag security, data handling, and failure-mode concerns" "Check rollout, testing, and rollback readiness" "Recommend targeted risk-reducing revisions")
                deps=("intake-and-triage" "solution-design-and-planning" "implementation-and-delivery-support")
                guards=("Do not approve changes with material safety, security, or reliability gaps" "Do not hide unresolved technical risk")
                ;;
            intake-and-diagnostics)
                desc="Assesses incoming work, diagnoses bottlenecks, and clarifies the operational problem to solve."
                caps=("Classify the request and the desired operational outcome" "Identify blockers, failure points, and missing inputs" "Map dependencies, stakeholders, and timing constraints" "Prepare a clear problem statement for the team")
                deps=("intake-and-triage")
                guards=("Do not mask ambiguity, exceptions, or operational risk" "Do not assume process details that were not provided")
                ;;
            planning-and-coordination)
                desc="Creates plans, priorities, owners, and sequencing for operational execution."
                caps=("Create plans, milestones, and ownership suggestions" "Prioritize tasks, timelines, and dependencies" "Recommend coordination patterns and escalation paths" "Clarify tradeoffs between speed, quality, and risk")
                deps=("intake-and-triage" "intake-and-diagnostics")
                guards=("Do not assign certainty to timelines that depend on unknown inputs" "Do not recommend skipping critical control points to save time")
                ;;
            quality-and-exception-review)
                desc="Reviews plans and outputs for process quality, exception handling, and execution risk."
                caps=("Check process clarity and exception coverage" "Identify brittle steps, bottlenecks, or failure risks" "Review outputs for completeness and operational readiness" "Recommend focused improvements")
                deps=("intake-and-triage" "planning-and-coordination" "execution-support")
                guards=("Do not approve workflows that ignore important exceptions or controls" "Do not suppress operational risk signals")
                ;;
            facts-and-context-analysis)
                desc="Collects, organizes, and analyzes the relevant facts, context, documents, and constraints for careful review."
                caps=("Summarize relevant facts, documents, and stakeholders" "Distinguish confirmed facts from assumptions" "Highlight key constraints, precedents, and decision context" "Surface gaps that require human judgment")
                deps=("intake-and-triage")
                guards=("Do not state uncertain facts as settled" "Do not conceal ambiguity or missing source support")
                ;;
            policy-and-decision-support)
                desc="Translates the available facts into structured options, tradeoffs, and cautious recommendation support."
                caps=("Outline decision options and their tradeoffs" "Map facts to policy, risk, or review considerations" "Identify escalation points and approval needs" "Recommend careful next steps for human review")
                deps=("intake-and-triage" "facts-and-context-analysis")
                guards=("Do not present analysis as final legal, policy, or compliance approval" "Do not downplay risk or uncertainty")
                ;;
            documentation-and-communication-support)
                desc="Prepares summaries, documentation, and careful communication support based on approved direction."
                caps=("Draft summaries and structured documentation" "Prepare communication frameworks or response outlines" "Maintain clear reasoning and decision traceability" "Surface unresolved questions before finalization")
                deps=("intake-and-triage" "policy-and-decision-support")
                guards=("Do not imply final approval where human signoff is required" "Do not omit material caveats or dependencies")
                ;;
            risk-and-compliance-review)
                desc="Reviews work for risk exposure, policy alignment, consistency, and compliance concerns."
                caps=("Identify policy, compliance, and governance issues" "Check consistency across recommendations and documentation" "Flag escalation items and sensitive edge cases" "Recommend mitigations and review steps")
                deps=("intake-and-triage" "policy-and-decision-support" "documentation-and-communication-support")
                guards=("Do not approve outputs with unresolved material risk" "Do not soften findings to make a recommendation easier to accept")
                ;;
            evidence-and-context-review)
                desc="Reviews source material, evidence, and domain context to ground the team's work."
                caps=("Summarize relevant evidence and background context" "Differentiate evidence strength and uncertainty" "Highlight missing inputs or questionable assumptions" "Translate source material into practical context")
                deps=("intake-and-triage")
                guards=("Do not fabricate evidence or overstate confidence" "Do not confuse preliminary information with validated conclusions")
                ;;
            planning-and-recommendation-support)
                desc="Builds structured options, plans, and recommendations from the available evidence and constraints."
                caps=("Develop options, priorities, and recommendation frameworks" "Connect evidence to practical decisions and next steps" "Document tradeoffs, cautions, and dependencies" "Support decision readiness without overstating certainty")
                deps=("intake-and-triage" "evidence-and-context-review")
                guards=("Do not provide diagnosis, treatment, or regulated advice as final instruction without qualified review" "Do not hide uncertainty or gaps in evidence")
                ;;
            documentation-and-coordination-support)
                desc="Prepares structured writeups, coordination artifacts, and handoffs to support domain workflows."
                caps=("Draft summaries, plans, and handoff materials" "Organize approvals, tasks, and follow-up items" "Support communication between stakeholders" "Keep records clear, structured, and traceable")
                deps=("intake-and-triage" "planning-and-recommendation-support")
                guards=("Do not omit required cautions, exceptions, or follow-up needs" "Do not present draft material as final human-approved guidance")
                ;;
            quality-safety-and-compliance-review)
                desc="Reviews work for quality, safety, procedural adherence, and domain-specific compliance concerns."
                caps=("Check outputs for quality, safety, and consistency" "Flag evidence, documentation, or process gaps" "Review whether recommendations fit applicable constraints" "Recommend revisions before use")
                deps=("intake-and-triage" "planning-and-recommendation-support" "documentation-and-coordination-support")
                guards=("Do not approve outputs that create safety or compliance risk" "Do not hide unresolved concerns that require expert review")
                ;;
            research-and-context)
                desc="Researches relevant context, inputs, and supporting information for the team."
                caps=("Gather and summarize relevant context" "Identify assumptions, dependencies, and missing inputs" "Organize information for downstream specialists" "Highlight uncertainty and evidence gaps")
                deps=("intake-and-triage")
                guards=("Do not fabricate context or supporting details" "Do not hide important uncertainty")
                ;;
            strategy-and-planning)
                desc="Turns context into recommended priorities, plans, and decision support."
                caps=("Recommend priorities and next steps" "Translate context into an execution plan" "Identify tradeoffs and sequencing" "Make reasoning explicit")
                deps=("intake-and-triage" "research-and-context")
                guards=("Do not recommend high-impact actions without stating the tradeoffs" "Do not collapse uncertainty into false precision")
                ;;
            execution-support)
                desc="Produces structured execution support, artifacts, and follow-through guidance."
                caps=("Draft execution-ready outputs" "Convert plans into concrete work items" "Track blockers and dependencies" "Prepare handoffs and summaries")
                deps=("intake-and-triage" "strategy-and-planning")
                guards=("Do not imply unapproved actions are already decided" "Do not omit critical dependencies or blockers")
                ;;
            quality-and-risk-review)
                desc="Reviews outputs for completeness, correctness, quality, and risk."
                caps=("Check outputs for errors, gaps, and contradictions" "Review alignment with plan and constraints" "Flag risky assumptions or missing safeguards" "Recommend focused revisions")
                deps=("intake-and-triage" "strategy-and-planning" "execution-support")
                guards=("Do not approve outputs with material unresolved risk" "Do not silently rewrite decisions that need human review")
                ;;
        esac

        AGENTS+=("$name")
        AGENT_DESCRIPTIONS+=("$desc")
        AGENT_CAPABILITIES+=("$(join_by '|' "${caps[@]}")")
        AGENT_TEMPERATURES+=("$(pick_temperature "$name $desc")")
        AGENT_DEPENDENCIES+=("$(join_by '|' "${deps[@]}")")
        AGENT_GUARDRAILS+=("$(join_by '|' "${guards[@]}")")
    done
}

write_team_files() {
    local team_slug="$1"
    local team_title="$2"
    local team_description="$3"
    local team_operational_mode="$4"
    local team_dir="$5"
    local today
    today="$(date +%Y-%m-%d)"
    local feedback_month
    feedback_month="$(date +%Y-%m)"

    mkdir -p "$team_dir"/shared "$team_dir"/meta-agent "$team_dir"/auditor "$team_dir"/feedback/"$feedback_month" "$team_dir"/evals
    mkdir -p "$team_dir"/agents

    local agent_grid=""
    local column=0
    local agent_name
    for agent_name in "${AGENTS[@]}"; do
        if [[ $column -eq 0 ]]; then
            agent_grid+="│  "
        fi
        agent_grid+="$(printf '%-28s' "$agent_name")"
        column=$((column + 1))
        if [[ $column -eq 2 ]]; then
            agent_grid+="│\n"
            column=0
        else
            agent_grid+="│  "
        fi
    done
    if [[ $column -ne 0 ]]; then
        agent_grid+="$(printf '%*s' 30 '')│\n"
    fi

    cat > "$team_dir/README.md" <<EOF
# ${team_title} Agent Team

${team_description}

## Architecture

\
\
\

auto-generated team scaffold

\
\
\

auto-generated grid

\
\
\

auto-generated


auto-generated

\
\
\

auto-generated

\
\
\


auto-generated

\
\
\


auto-generated

\
\
\

auto-generated


auto-generated

\
\
\

auto-generated

\
\
\

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
│              Agent Team (${team_operational_mode})              │
$(printf "%b" "$agent_grid")└─────────────────────────────────────────────────┘
\`\`\`

## Principles

1. **Agents advise, humans execute.** No agent takes autonomous action without explicit human approval.
2. **Everything in git.** Every agent modification is a commit with documented rationale.
3. **Feedback-driven improvement.** Agents only change based on structured human feedback.
4. **Constrained evolution.** The meta-agent operates within a constitution it cannot modify.
5. **No single point of control.** The auditor independently reviews the meta-agent's decisions.

## Agents

EOF

    local index
    for index in "${!AGENTS[@]}"; do
        printf -- '- **%s** — %s\n' "${AGENTS[$index]}" "${AGENT_DESCRIPTIONS[$index]}" >> "$team_dir/README.md"
    done

    cat >> "$team_dir/README.md" <<EOF

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
\`\`\`
EOF

    cat > "$team_dir/shared/constitution.md" <<EOF
# Constitution

These constraints are **inviolable**. The meta-agent cannot modify, weaken, or circumvent them. The auditor agent monitors compliance. Only the human operator may amend this document.

---

## 1. Scope of Authority

- **Agents are ${team_operational_mode}.** No agent may take autonomous action in the real world without explicit human approval unless the human explicitly defines a narrower approved automation path.
- **The meta-agent may only modify:** agent system prompts, agent.yaml configuration, and tool definitions.
- **The meta-agent may NOT modify:** this constitution, the auditor's configuration or prompt, or its own system prompt.
- **The auditor operates independently.** The meta-agent has no authority over the auditor's configuration, evaluation criteria, or findings.

## 2. Ethical Boundaries
EOF

    for constraint in "${ETHICAL_CONSTRAINTS[@]}"; do
        printf -- '- %s\n' "$constraint" >> "$team_dir/shared/constitution.md"
    done

    cat >> "$team_dir/shared/constitution.md" <<EOF

## 3. Evolution Rules

- Every agent modification must include a **written rationale** referencing specific feedback that motivated the change.
- No modification may be applied without an auditor review cycle.
- The meta-agent must preserve a **rollback path** in version control and keep CHANGELOG files current.
- The meta-agent may not optimize for a single metric at the expense of overall system coherence.
- Modifications must be **incremental**. No single commit may rewrite more than 30% of an agent's system prompt.

## 4. Data Handling
EOF

    for constraint in "${DATA_CONSTRAINTS[@]}"; do
        printf -- '- %s\n' "$constraint" >> "$team_dir/shared/constitution.md"
    done

    cat >> "$team_dir/shared/constitution.md" <<EOF

## 5. Inter-Agent Coherence

- Agent outputs must not contradict each other.
- The meta-agent is responsible for cross-agent coherence. The auditor verifies it.
- When agents have conflicting recommendations, the conflict must be surfaced to the human operator.

---

**Last amended:** ${today}
**Amended by:** Human operator (initial version)
EOF

    cat > "$team_dir/shared/glossary.md" <<EOF
# Glossary

Shared terminology used across all agents. The meta-agent must maintain consistency with these definitions when evolving agent prompts.

## System Terms

- **Cycle**: One complete loop of agent output → human feedback → meta-agent modification → auditor review.
- **Advisory output**: Agent-generated suggestions intended for human review. Never executed autonomously.
- **Evolution**: A meta-agent-initiated modification to an agent's configuration or prompt.
- **Drift**: When an agent's behavior gradually diverges from intended purpose due to cumulative prompt modifications.
- **Regression**: When a modification intended to improve one capability degrades another.
- **Coherence**: The degree to which all agents' outputs are aligned and non-contradictory.

## Agent Roles

- **Meta-Agent**: Processes human feedback and modifies agent configurations. Cannot self-modify or modify the auditor.
- **Auditor**: Independently reviews meta-agent changes for drift, regression, coherence violations, and constitutional compliance.
EOF

    for index in "${!AGENTS[@]}"; do
        printf -- '- **%s**: %s\n' "${AGENTS[$index]}" "${AGENT_DESCRIPTIONS[$index]}" >> "$team_dir/shared/glossary.md"
    done

    cat > "$team_dir/meta-agent/system-prompt.md" <<'EOF'
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

1. Categorize feedback by agent, feedback type, and severity.
2. Diagnose the likely root cause before proposing any change.
3. Propose small, explicit edits with rationale and side-effect assessment.
4. Update the relevant CHANGELOG with references to the feedback used.

## Evolution Constraints

- Incremental changes only.
- Preserve what works.
- Check for cross-agent coherence before changing anything.
- Never infer feedback that was not given.
EOF

    cat > "$team_dir/meta-agent/agent.yaml" <<EOF
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
EOF

    cat > "$team_dir/meta-agent/CHANGELOG.md" <<EOF
# Meta-Agent Changelog

Only the human operator may modify the meta-agent. All changes are documented here.

## [${today}] - Initial Version

### Created
- System prompt with feedback processing workflow
- Evolution constraints and output format
- Agent configuration
EOF

    cat > "$team_dir/auditor/system-prompt.md" <<'EOF'
# Auditor Agent System Prompt

You are the Auditor — an independent reviewer of the meta-agent's decisions. Your purpose is to ensure that agent evolution stays aligned with the constitution, maintains cross-agent coherence, and genuinely improves agent quality based on human feedback.

You are NOT subordinate to the meta-agent. You report directly to the human operator.

## What You Review

- Constitutional compliance
- Feedback fidelity
- Drift detection
- Regression risk
- Cross-agent coherence
- Change magnitude

## Output Format

Provide a clear approval recommendation, flags, concerns, and any items requiring human attention.
EOF

    cat > "$team_dir/auditor/agent.yaml" <<EOF
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
EOF

    cat > "$team_dir/auditor/CHANGELOG.md" <<EOF
# Auditor Changelog

Only the human operator may modify the auditor.

## [${today}] - Initial Version

### Created
- System prompt with independent review responsibilities
- Agent configuration with independence constraints
EOF

    for index in "${!AGENTS[@]}"; do
        local agent desc temp capabilities_text dependencies_text guardrails_text
        agent="${AGENTS[$index]}"
        desc="${AGENT_DESCRIPTIONS[$index]}"
        temp="${AGENT_TEMPERATURES[$index]}"

        mkdir -p "$team_dir/agents/$agent"

        IFS='|' read -r -a caps <<< "${AGENT_CAPABILITIES[$index]}"
        IFS='|' read -r -a deps <<< "${AGENT_DEPENDENCIES[$index]}"
        IFS='|' read -r -a guards <<< "${AGENT_GUARDRAILS[$index]}"

        capabilities_text=""
        local capability_counter=1
        local cap
        for cap in "${caps[@]}"; do
            [[ -z "$cap" ]] && continue
            capabilities_text+="${capability_counter}. **${cap}**\n"
            capability_counter=$((capability_counter + 1))
        done

        guardrails_text=""
        local guard
        for guard in "${guards[@]}"; do
            [[ -z "$guard" ]] && continue
            guardrails_text+="- ${guard}\n"
        done

        dependencies_text=""
        local dep
        for dep in "${deps[@]}"; do
            [[ -z "$dep" ]] && continue
            dependencies_text+="  - agents/${dep}/system-prompt.md\n"
        done

        cat > "$team_dir/agents/$agent/system-prompt.md" <<EOF
# ${agent} — System Prompt

You are the ${agent} agent for the ${team_title} team. ${desc}

All output is advisory — the human operator reviews and decides what to execute.

## Your Capabilities

$(printf "%b" "$capabilities_text")
## Output Standards

- Start with a concise summary of the task and intended outcome.
- Make assumptions explicit.
- Use structured sections and practical recommendations.
- Surface blockers, risks, and open questions instead of hiding them.

## What You Must Never Do

$(printf "%b" "$guardrails_text")
## Context You Need

- The user's goal and success criteria
- Relevant constraints, timelines, and dependencies
- Source material, historical context, or existing drafts when available
- Any decisions already made by the human operator or peer agents

## How You'll Be Evaluated

EOF
        local dim
        for dim in "${EVAL_DIMENSIONS[@]}"; do
            local dim_name dim_desc
            dim_name="${dim%% - *}"
            dim_desc="${dim#* - }"
            printf -- '- **%s**: %s\n' "$dim_name" "$dim_desc" >> "$team_dir/agents/$agent/system-prompt.md"
        done

        cat > "$team_dir/agents/$agent/agent.yaml" <<EOF
name: ${agent}
description: ${desc}
model: claude-sonnet-4-20250514
temperature: ${temp}

context_sources:
  - shared/constitution.md
  - shared/glossary.md
$(printf "%b" "$dependencies_text")capabilities:
EOF
        for cap in "${caps[@]}"; do
            [[ -z "$cap" ]] && continue
            printf '  - %s\n' "$(slugify "$cap")" >> "$team_dir/agents/$agent/agent.yaml"
        done
        cat >> "$team_dir/agents/$agent/agent.yaml" <<EOF

dependencies:
EOF
        if [[ ${#deps[@]} -eq 0 || -z "${deps[*]}" ]]; then
            echo '  [] # No dependencies' >> "$team_dir/agents/$agent/agent.yaml"
        else
            for dep in "${deps[@]}"; do
                [[ -z "$dep" ]] && continue
                printf '  - %s\n' "$dep" >> "$team_dir/agents/$agent/agent.yaml"
            done
        fi
        cat >> "$team_dir/agents/$agent/agent.yaml" <<EOF
output_format: markdown
output_target: stdout
EOF

        cat > "$team_dir/agents/$agent/CHANGELOG.md" <<EOF
# ${agent} Changelog

## [${today}] - Initial Version

### Created
- System prompt (v1)
- Agent configuration

### Rationale
- Initial auto-generated system setup.
EOF
    done

    cat > "$team_dir/feedback/template.md" <<'EOF'
# Feedback — YYYY-MM-DD

## Cycle: [N]

---

### Item 1

**Agent:** [agent name]
**Task:** [what you asked the agent to do]
**Rating:** [1-5]

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

[Any contradictions, misalignment, or synergy]

## System-Level Notes

[Any workflow or architecture notes]
EOF

    cat > "$team_dir/evals/baseline-scores.json" <<EOF
{
  "metadata": {
    "created": "${today}",
    "last_updated": "${today}",
    "current_cycle": 0,
    "notes": "Initial baseline — no feedback cycles completed"
  },
  "agents": {
EOF
    local first_agent=1
    for agent_name in "${AGENTS[@]}"; do
        if [[ $first_agent -eq 0 ]]; then
            echo ',' >> "$team_dir/evals/baseline-scores.json"
        fi
        cat >> "$team_dir/evals/baseline-scores.json" <<EOF
    "${agent_name}": {
      "version": "1.0.0",
      "cycles_completed": 0,
      "scores": [],
      "rolling_average": null,
      "trend": null
    }
EOF
        first_agent=0
    done
    cat >> "$team_dir/evals/baseline-scores.json" <<EOF
  },
  "score_schema": {
    "rating": "1-5 from human feedback",
    "dimensions": {
EOF
    local first_dim=1
    for dim in "${EVAL_DIMENSIONS[@]}"; do
        local dim_name dim_desc
        dim_name="${dim%% - *}"
        dim_desc="${dim#* - }"
        if [[ $first_dim -eq 0 ]]; then
            echo ',' >> "$team_dir/evals/baseline-scores.json"
        fi
        printf '      "%s": "%s"' "$dim_name" "$dim_desc" >> "$team_dir/evals/baseline-scores.json"
        first_dim=0
    done
    cat >> "$team_dir/evals/baseline-scores.json" <<EOF

    }
  }
}
EOF
}


emit_team_answers() {
    local team_description_text="$1"
    local team_operational_mode="$2"
    local index
    local agent_name

    printf '%s\n' "$team_description_text"
    printf '%s\n' "$team_operational_mode"

    for index in "${!AGENTS[@]}"; do
        agent_name="${AGENTS[$index]}"
        printf '%s\n' "$agent_name"
        printf '%s\n' "${AGENT_DESCRIPTIONS[$index]}"

        IFS='|' read -r -a caps <<< "${AGENT_CAPABILITIES[$index]}"
        for cap in "${caps[@]}"; do
            [[ -z "$cap" ]] && continue
            printf '%s\n' "$cap"
        done
        printf '\n'

        printf '%s\n' "${AGENT_TEMPERATURES[$index]}"

        if [[ $index -gt 0 ]]; then
            IFS='|' read -r -a deps <<< "${AGENT_DEPENDENCIES[$index]}"
            for dep in "${deps[@]}"; do
                [[ -z "$dep" ]] && continue
                printf '%s\n' "$dep"
            done
            printf '\n'
        fi

        IFS='|' read -r -a guards <<< "${AGENT_GUARDRAILS[$index]}"
        for guard in "${guards[@]}"; do
            [[ -z "$guard" ]] && continue
            printf '%s\n' "$guard"
        done
        printf '\n'

        if [[ $index -ge 3 ]]; then
            if [[ $index -lt $((${#AGENTS[@]} - 1)) ]]; then
                printf 'y\n'
            else
                printf 'n\n'
            fi
        fi
    done

    for constraint in "${ETHICAL_CONSTRAINTS[@]}"; do
        printf '%s\n' "$constraint"
    done
    printf '\n'

    for constraint in "${DATA_CONSTRAINTS[@]}"; do
        printf '%s\n' "$constraint"
    done
    printf '\n'

    for dimension in "${EVAL_DIMENSIONS[@]}"; do
        printf '%s\n' "$dimension"
    done
    printf '\n'

    printf 'y\n'
}

run_template_for_team() {
    local template_path="$1"
    local output_dir="$2"
    local team_slug="$3"
    local team_summary="$4"
    local team_mode="$5"
    local run_root="$6"
    local log_path="$7"

    local script_dir="$run_root/bin"
    local teams_dir="$run_root/teams"
    local local_template="$script_dir/build-team-template.sh"

    rm -rf "$run_root"
    mkdir -p "$script_dir" "$teams_dir"
    cp "$template_path" "$local_template"
    python3 - "$local_template" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
text = text.replace('    ((agent_count++))', '    agent_count=$((agent_count + 1))')
text = text.replace('    [[ -z "$agent_name" ]] && { ((agent_count--)); break; }', '    [[ -z "$agent_name" ]] && { agent_count=$((agent_count - 1)); break; }')
text = text.replace('    ((col++))', '    col=$((col + 1))')
text = text.replace('        ((cap_num++))', '        cap_num=$((cap_num + 1))')
path.write_text(text)
PY
    chmod +x "$local_template"

    emit_team_answers "$team_summary" "$team_mode" | bash "$local_template" "$team_slug" > "$log_path" 2>&1

    if [[ ! -d "$teams_dir/$team_slug" ]]; then
        echo "Expected generated team directory was not created: $teams_dir/$team_slug" >&2
        return 1
    fi

    rm -rf "$output_dir/$team_slug"
    mv "$teams_dir/$team_slug" "$output_dir/$team_slug"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --template PATH     Path to the original interactive script
  --list PATH         Path to the team list file
  --output-dir PATH   Directory where teams should be created
  --force             Overwrite existing team directories
  --team NAME         Generate only one team slug from the list or custom input
  --dry-run           Show what would be created without writing files
  -h, --help          Show this help message
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TEMPLATE="${SCRIPT_DIR}/build-team-template.sh"
DEFAULT_LIST="${SCRIPT_DIR}/suggested-agents.txt"
DEFAULT_OUTPUT_DIR="${SCRIPT_DIR}/generated-teams"
TEMPLATE_PATH="$DEFAULT_TEMPLATE"
LIST_PATH="$DEFAULT_LIST"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
FORCE_OVERWRITE="false"
DRY_RUN="false"
SINGLE_TEAM=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --template)
            TEMPLATE_PATH="$2"
            shift 2
            ;;
        --list)
            LIST_PATH="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --force)
            FORCE_OVERWRITE="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --team)
            SINGLE_TEAM="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            warn "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

[[ -f "$TEMPLATE_PATH" ]] || { echo "Template not found: $TEMPLATE_PATH"; exit 1; }
[[ -f "$LIST_PATH" ]] || { echo "Team list not found: $LIST_PATH"; exit 1; }
mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/.logs"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

header "Bulk Agent Team Builder"
info "Template source: $TEMPLATE_PATH"
info "Team list source: $LIST_PATH"
info "Output directory: $OUTPUT_DIR"

mapfile -t TEAM_LINES < <(grep -v '^[[:space:]]*$' "$LIST_PATH")

if [[ -n "$SINGLE_TEAM" ]]; then
    TEAM_LINES=("$SINGLE_TEAM")
fi

created_count=0
skipped_count=0

for raw_team in "${TEAM_LINES[@]}"; do
    team_slug="$(slugify "$raw_team")"
    team_title="$(titleize "$team_slug")"
    team_dir="$OUTPUT_DIR/$team_slug"
    team_mode="$(pick_operational_mode "$team_slug")"
    team_summary="$(team_description "$team_slug" "$team_title")"

    build_team_constraints "$team_slug"
    build_agent_catalog "$team_slug"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] would generate: $team_dir"
        echo "           title: $team_title"
        echo "           mode:  $team_mode"
        echo "           agents: ${AGENTS[*]}"
        continue
    fi

    if [[ -d "$team_dir" && "$FORCE_OVERWRITE" != "true" ]]; then
        warn "Skipping existing team directory: $team_dir"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    if run_template_for_team "$TEMPLATE_PATH" "$OUTPUT_DIR" "$team_slug" "$team_summary" "$team_mode" "$OUTPUT_DIR/.tmp-${team_slug}" "$OUTPUT_DIR/.logs/${team_slug}.log"; then
        success "Generated $team_slug via interactive template"
        created_count=$((created_count + 1))
    else
        warn "Failed to generate $team_slug. See $OUTPUT_DIR/.logs/${team_slug}.log"
    fi
done

header "Done"
echo "Created: $created_count"
echo "Skipped: $skipped_count"
echo "Output:  $OUTPUT_DIR"
