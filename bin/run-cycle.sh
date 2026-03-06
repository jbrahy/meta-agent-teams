#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# run-cycle.sh — Orchestrate a full feedback→evolve→audit→commit cycle
#
# Usage: ./run-cycle.sh <team-slug> [feedback-file]
#
# Steps:
#   1. Identifies the latest feedback (or uses the one specified)
#   2. Runs the meta-agent to produce an evolution proposal
#   3. Runs the auditor to review the proposal
#   4. Presents both to you for approval
#   5. On approval: applies changes, updates cycle count, commits
# ============================================================================

# --- Colors & formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

header()  { echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}"; echo -e "${BOLD}${BLUE}  $1${NC}"; echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════${NC}\n"; }
section() { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}\n"; }
info()    { echo -e "${DIM}$1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
die()     { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }
prompt()  { echo -en "${BOLD}$1${NC}"; }

ask_yn() {
    local prompt_text="$1" default="${2:-y}"
    local hint="Y/n"
    [[ "$default" == "n" ]] && hint="y/N"
    prompt "$prompt_text [$hint]: "
    read -r input
    input="${input:-$default}"
    [[ "${input,,}" == "y" || "${input,,}" == "yes" ]]
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAMS_DIR="${SCRIPT_DIR}/teams"

usage() {
    echo "Usage: $(basename "$0") <team-slug> [feedback-file]"
    echo ""
    echo "  team-slug      Name of the team directory under teams/"
    echo "  feedback-file   Path to specific feedback file (default: most recent)"
    echo ""
    echo "Runs the full evolution cycle:"
    echo "  1. Meta-agent processes feedback → evolution proposal"
    echo "  2. Auditor reviews the proposal"
    echo "  3. You approve, modify, or reject"
    echo "  4. Changes are committed to git"
    echo ""
    echo "Available teams:"
    if [[ -d "$TEAMS_DIR" ]]; then
        for d in "$TEAMS_DIR"/*/; do
            [[ -d "$d" ]] && echo "  $(basename "$d")"
        done
    else
        echo "  (none)"
    fi
    exit 1
}

[[ $# -lt 1 ]] && usage

TEAM_SLUG="$1"
TEAM_DIR="${TEAMS_DIR}/${TEAM_SLUG}"
[[ -d "$TEAM_DIR" ]] || die "Team '${TEAM_SLUG}' not found at ${TEAM_DIR}"

# --- Check for claude CLI ---
command -v claude &>/dev/null || die "claude CLI not found. Install: npm install -g @anthropic-ai/claude-code"

# --- Find feedback file ---
if [[ -n "${2:-}" ]]; then
    FEEDBACK_FILE="$2"
    [[ -f "$FEEDBACK_FILE" ]] || die "Feedback file not found: ${FEEDBACK_FILE}"
else
    # Find most recent feedback file (not template)
    FEEDBACK_FILE=$(find "$TEAM_DIR/feedback" -name "*.md" ! -name "template.md" -type f 2>/dev/null | sort -r | head -1)
    [[ -n "$FEEDBACK_FILE" ]] || die "No feedback files found. Run new-feedback.sh first."
fi

# --- Determine cycle number ---
if [[ -f "$TEAM_DIR/evals/baseline-scores.json" ]] && command -v python3 &>/dev/null; then
    CYCLE=$(python3 -c "
import json
with open('${TEAM_DIR}/evals/baseline-scores.json') as f:
    data = json.load(f)
print(data.get('metadata', {}).get('current_cycle', 0) + 1)
" 2>/dev/null || echo "1")
else
    CYCLE="1"
fi

# --- Create output directory for this cycle ---
CYCLE_DIR="${TEAM_DIR}/evals/cycle-${CYCLE}"
mkdir -p "$CYCLE_DIR"

header "Evolution Cycle ${CYCLE}: ${TEAM_SLUG}"
info "Feedback: ${FEEDBACK_FILE#${TEAM_DIR}/}"
echo ""

# ============================================================================
# STEP 1: Meta-Agent — Generate Evolution Proposal
# ============================================================================

section "Step 1: Meta-Agent Processing Feedback"

# Build meta-agent context: system prompt + constitution + glossary + all agent prompts + feedback
META_PROMPT=$(mktemp /tmp/meta-prompt-XXXXXX.md)
trap "rm -f '$META_PROMPT' /tmp/audit-prompt-*.md" EXIT

cat "$TEAM_DIR/meta-agent/system-prompt.md" > "$META_PROMPT"

cat >> "$META_PROMPT" << CTXEOF

---

# Context

## Constitution

$(cat "$TEAM_DIR/shared/constitution.md")

## Glossary

$(cat "$TEAM_DIR/shared/glossary.md")

## Current Agent Configurations

CTXEOF

# Add all agent prompts and configs
for agent_dir in "$TEAM_DIR/agents"/*/; do
    [[ -d "$agent_dir" ]] || continue
    agent_name=$(basename "$agent_dir")
    cat >> "$META_PROMPT" << AGENTCTX

### Agent: ${agent_name}

#### System Prompt
$(cat "$agent_dir/system-prompt.md")

#### Configuration
$(cat "$agent_dir/agent.yaml" 2>/dev/null || echo "(no agent.yaml)")

#### Changelog
$(cat "$agent_dir/CHANGELOG.md" 2>/dev/null || echo "(no changelog)")

AGENTCTX
done

# Add eval scores if they exist
if [[ -f "$TEAM_DIR/evals/baseline-scores.json" ]]; then
    cat >> "$META_PROMPT" << EVALCTX

## Evaluation Scores

\`\`\`json
$(cat "$TEAM_DIR/evals/baseline-scores.json")
\`\`\`

EVALCTX
fi

# The feedback itself becomes the user prompt
FEEDBACK_CONTENT=$(cat "$FEEDBACK_FILE")

info "Sending feedback to meta-agent..."
echo ""

EVOLUTION_PROPOSAL="${CYCLE_DIR}/evolution-proposal.md"

claude --system-prompt "$META_PROMPT" \
    --prompt "Process this feedback for Cycle ${CYCLE}. Follow your output format exactly.

${FEEDBACK_CONTENT}" \
    --output-file "$EVOLUTION_PROPOSAL" 2>/dev/null \
    || claude --system-prompt "$META_PROMPT" \
        -p "Process this feedback for Cycle ${CYCLE}. Follow your output format exactly.

${FEEDBACK_CONTENT}" > "$EVOLUTION_PROPOSAL"

if [[ ! -s "$EVOLUTION_PROPOSAL" ]]; then
    die "Meta-agent produced no output. Check your claude CLI configuration."
fi

success "Evolution proposal saved: ${EVOLUTION_PROPOSAL#${TEAM_DIR}/}"

# ============================================================================
# STEP 2: Auditor — Review the Proposal
# ============================================================================

section "Step 2: Auditor Reviewing Proposal"

AUDIT_PROMPT=$(mktemp /tmp/audit-prompt-XXXXXX.md)

cat "$TEAM_DIR/auditor/system-prompt.md" > "$AUDIT_PROMPT"

cat >> "$AUDIT_PROMPT" << AUDITCTX

---

# Context

## Constitution

$(cat "$TEAM_DIR/shared/constitution.md")

## Evaluation Scores

\`\`\`json
$(cat "$TEAM_DIR/evals/baseline-scores.json" 2>/dev/null || echo "{}")
\`\`\`

## Current Agent States

AUDITCTX

# Add current agent prompts for comparison
for agent_dir in "$TEAM_DIR/agents"/*/; do
    [[ -d "$agent_dir" ]] || continue
    agent_name=$(basename "$agent_dir")
    cat >> "$AUDIT_PROMPT" << AUCTX

### ${agent_name}
$(cat "$agent_dir/system-prompt.md")

AUCTX
done

AUDIT_REPORT="${CYCLE_DIR}/audit-report.md"

info "Sending proposal to auditor..."
echo ""

claude --system-prompt "$AUDIT_PROMPT" \
    --prompt "Review this evolution proposal for Cycle ${CYCLE}. The original feedback and the meta-agent's proposed changes are below. Follow your output format exactly.

## Original Feedback

${FEEDBACK_CONTENT}

## Meta-Agent Evolution Proposal

$(cat "$EVOLUTION_PROPOSAL")" \
    --output-file "$AUDIT_REPORT" 2>/dev/null \
    || claude --system-prompt "$AUDIT_PROMPT" \
        -p "Review this evolution proposal for Cycle ${CYCLE}. The original feedback and the meta-agent's proposed changes are below. Follow your output format exactly.

## Original Feedback

${FEEDBACK_CONTENT}

## Meta-Agent Evolution Proposal

$(cat "$EVOLUTION_PROPOSAL")" > "$AUDIT_REPORT"

if [[ ! -s "$AUDIT_REPORT" ]]; then
    warn "Auditor produced no output. Proceeding with proposal review only."
fi

success "Audit report saved: ${AUDIT_REPORT#${TEAM_DIR}/}"

# ============================================================================
# STEP 3: Human Review
# ============================================================================

section "Step 3: Your Review"

echo -e "${BOLD}Evolution Proposal:${NC} ${EVOLUTION_PROPOSAL}"
echo -e "${BOLD}Audit Report:${NC}      ${AUDIT_REPORT}"
echo ""

# Show summary if audit report exists
if [[ -s "$AUDIT_REPORT" ]]; then
    # Extract the summary line
    summary=$(grep -A1 "^## Summary" "$AUDIT_REPORT" 2>/dev/null | tail -1 || echo "")
    if [[ -n "$summary" ]]; then
        echo -e "${BOLD}Auditor Summary:${NC} ${summary}"
        echo ""
    fi

    # Show pass/flag status lines
    grep -E "^## (Constitutional|Feedback|Drift|Regression|Coherence|Change)" "$AUDIT_REPORT" 2>/dev/null | while read -r line; do
        if [[ "$line" == *"PASS"* || "$line" == *"LOW"* || "$line" == *"STABLE"* || "$line" == *"COHERENT"* || "$line" == *"WITHIN"* ]]; then
            echo -e "  ${GREEN}${line#\#\# }${NC}"
        elif [[ "$line" == *"FLAG"* || "$line" == *"HIGH"* || "$line" == *"SIGNIFICANT"* || "$line" == *"EXCEEDS"* || "$line" == *"CONFLICT"* ]]; then
            echo -e "  ${RED}${line#\#\# }${NC}"
        else
            echo -e "  ${YELLOW}${line#\#\# }${NC}"
        fi
    done
    echo ""
fi

echo -e "${BOLD}Options:${NC}"
echo -e "  ${GREEN}a${NC} — Approve and apply changes (you'll edit the actual files)"
echo -e "  ${YELLOW}e${NC} — Open both files for detailed review first"
echo -e "  ${RED}r${NC} — Reject this cycle (saves proposal and report for reference)"
echo ""
prompt "Your decision [a/e/r]: "
read -r decision

case "${decision,,}" in
    a|approve)
        section "Applying Changes"
        info "The evolution proposal describes what to change."
        info "You'll need to apply the changes to agent files manually or with the meta-agent."
        echo ""
        info "Recommended approach:"
        echo -e "  1. Read ${CYAN}${EVOLUTION_PROPOSAL#${TEAM_DIR}/}${NC}"
        echo -e "  2. Apply changes to the relevant agent files"
        echo -e "  3. Run: ${DIM}$(basename "$0" .sh)/../update-scores.sh ${TEAM_SLUG} ${CYCLE}${NC}"
        echo ""

        # Update cycle count in baseline-scores.json
        if [[ -f "$TEAM_DIR/evals/baseline-scores.json" ]] && command -v python3 &>/dev/null; then
            python3 << PYEOF
import json
scores_path = "${TEAM_DIR}/evals/baseline-scores.json"
with open(scores_path) as f:
    data = json.load(f)
data["metadata"]["current_cycle"] = ${CYCLE}
data["metadata"]["last_updated"] = "$(date +%Y-%m-%d)"
with open(scores_path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
            success "Updated cycle count to ${CYCLE}"
        fi

        # Git commit if in a repo
        if git -C "$TEAM_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
            if ask_yn "Commit cycle ${CYCLE} to git?" "y"; then
                prompt "Commit message [Cycle ${CYCLE}: evolution applied]: "
                read -r commit_msg
                commit_msg="${commit_msg:-Cycle ${CYCLE}: evolution applied}"
                git -C "$TEAM_DIR" add -A
                git -C "$TEAM_DIR" commit -m "$commit_msg"
                success "Committed: ${commit_msg}"
            fi
        fi
        ;;
    e|edit|review)
        info "Opening files for review..."
        if [[ -n "${EDITOR:-}" ]]; then
            "$EDITOR" "$EVOLUTION_PROPOSAL" "$AUDIT_REPORT"
        elif command -v code &>/dev/null; then
            code "$EVOLUTION_PROPOSAL" "$AUDIT_REPORT"
        elif command -v vim &>/dev/null; then
            vim -O "$EVOLUTION_PROPOSAL" "$AUDIT_REPORT"
        else
            echo -e "  Proposal: ${CYAN}${EVOLUTION_PROPOSAL}${NC}"
            echo -e "  Audit:    ${CYAN}${AUDIT_REPORT}${NC}"
        fi
        echo ""
        info "Re-run this script when ready to approve or reject."
        ;;
    r|reject)
        section "Cycle Rejected"
        info "Proposal and audit report preserved at:"
        echo -e "  ${CYAN}${CYCLE_DIR#${TEAM_DIR}/}/${NC}"
        info "No changes applied. Feedback remains for the next cycle."

        # Mark as rejected
        echo "REJECTED — $(date +%Y-%m-%d)" > "${CYCLE_DIR}/REJECTED"
        ;;
    *)
        warn "Unknown option. No changes applied."
        ;;
esac

echo ""
success "Cycle ${CYCLE} complete."
