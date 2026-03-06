#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# new-feedback.sh — Create a new feedback file for a team
#
# Usage: ./new-feedback.sh <team-slug> [cycle-number]
#
# Creates a dated feedback file from the team's template in the correct
# monthly directory. Opens it in $EDITOR if available.
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
info()    { echo -e "${DIM}$1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
die()     { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAMS_DIR="${SCRIPT_DIR}/teams"

usage() {
    echo "Usage: $(basename "$0") <team-slug> [cycle-number]"
    echo ""
    echo "  team-slug     Name of the team directory under teams/"
    echo "  cycle-number  Optional cycle number (auto-detected from evals if omitted)"
    echo ""
    echo "Creates feedback/<YYYY-MM>/<YYYY-MM-DD>.md from the team's template."
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

# --- Determine cycle number ---
if [[ -n "${2:-}" ]]; then
    CYCLE="$2"
else
    # Auto-detect from baseline-scores.json
    if [[ -f "$TEAM_DIR/evals/baseline-scores.json" ]] && command -v python3 &>/dev/null; then
        CYCLE=$(python3 -c "
import json, sys
try:
    with open('${TEAM_DIR}/evals/baseline-scores.json') as f:
        data = json.load(f)
    print(data.get('metadata', {}).get('current_cycle', 0) + 1)
except:
    print(1)
" 2>/dev/null || echo "1")
    else
        # Count existing feedback files
        CYCLE=$(find "$TEAM_DIR/feedback" -name "*.md" ! -name "template.md" 2>/dev/null | wc -l)
        CYCLE=$((CYCLE + 1))
    fi
fi

# --- Create the feedback file ---
TODAY=$(date +%Y-%m-%d)
MONTH_DIR="$TEAM_DIR/feedback/$(date +%Y-%m)"
FEEDBACK_FILE="${MONTH_DIR}/${TODAY}.md"

mkdir -p "$MONTH_DIR"

if [[ -f "$FEEDBACK_FILE" ]]; then
    warn "Feedback file already exists: ${FEEDBACK_FILE}"
    echo -en "${BOLD}Append a new section? [Y/n]: ${NC}"
    read -r yn
    yn="${yn:-y}"
    if [[ "${yn,,}" == "y" || "${yn,,}" == "yes" ]]; then
        # Find the highest item number and add one
        last_item=$(grep -oP '### Item \K\d+' "$FEEDBACK_FILE" 2>/dev/null | sort -n | tail -1 || echo "0")
        next_item=$((last_item + 1))
        cat >> "$FEEDBACK_FILE" << EOF

---

### Item ${next_item}

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
EOF
        success "Appended Item ${next_item} to ${FEEDBACK_FILE}"
    else
        echo "No changes made."
        exit 0
    fi
else
    # --- List agents for reference ---
    AGENTS=()
    if [[ -d "$TEAM_DIR/agents" ]]; then
        for d in "$TEAM_DIR/agents"/*/; do
            [[ -d "$d" ]] && AGENTS+=("$(basename "$d")")
        done
    fi

    # Create from template with date and cycle filled in
    if [[ -f "$TEAM_DIR/feedback/template.md" ]]; then
        sed "s/YYYY-MM-DD/${TODAY}/g; s/\[N\]/${CYCLE}/" \
            "$TEAM_DIR/feedback/template.md" > "$FEEDBACK_FILE"
    else
        cat > "$FEEDBACK_FILE" << EOF
# Feedback — ${TODAY}

## Cycle: ${CYCLE}

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
EOF
    fi

    success "Created: ${FEEDBACK_FILE}"
    info "Cycle: ${CYCLE}"
    if [[ ${#AGENTS[@]} -gt 0 ]]; then
        info "Agents: ${AGENTS[*]}"
    fi
fi

echo ""

# --- Open in editor ---
if [[ -n "${EDITOR:-}" ]]; then
    info "Opening in \$EDITOR (${EDITOR})..."
    "$EDITOR" "$FEEDBACK_FILE"
elif command -v code &>/dev/null; then
    info "Opening in VS Code..."
    code "$FEEDBACK_FILE"
elif command -v vim &>/dev/null; then
    info "Opening in vim..."
    vim "$FEEDBACK_FILE"
else
    info "Edit the file at:"
    echo -e "  ${CYAN}${FEEDBACK_FILE}${NC}"
fi
