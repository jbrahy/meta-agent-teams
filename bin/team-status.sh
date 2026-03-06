#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# team-status.sh — Dashboard view of team health
#
# Usage: ./team-status.sh <team-slug>
#
# Shows: cycle count, agent scores, trends, recent feedback, constitution
# health, and any drift warnings.
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
die()     { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAMS_DIR="${SCRIPT_DIR}/teams"

# --- List all teams if no argument ---
if [[ $# -lt 1 ]]; then
    header "Available Teams"
    if [[ -d "$TEAMS_DIR" ]]; then
        for d in "$TEAMS_DIR"/*/; do
            [[ -d "$d" ]] || continue
            slug=$(basename "$d")
            desc=""
            if [[ -f "$d/evals/baseline-scores.json" ]] && command -v python3 &>/dev/null; then
                cycle=$(python3 -c "
import json
with open('$d/evals/baseline-scores.json') as f:
    print(json.load(f).get('metadata',{}).get('current_cycle',0))
" 2>/dev/null || echo "?")
            else
                cycle="?"
            fi
            agent_count=$(find "$d/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
            echo -e "  ${GREEN}${slug}${NC}  —  ${agent_count} agents, cycle ${cycle}"
        done
    else
        echo "  (none — run build-team-template.sh first)"
    fi
    echo ""
    echo "Usage: $(basename "$0") <team-slug>"
    exit 0
fi

TEAM_SLUG="$1"
TEAM_DIR="${TEAMS_DIR}/${TEAM_SLUG}"
[[ -d "$TEAM_DIR" ]] || die "Team '${TEAM_SLUG}' not found at ${TEAM_DIR}"

SCORES_FILE="${TEAM_DIR}/evals/baseline-scores.json"

# ============================================================================
# Header
# ============================================================================

# Get team description from README
TEAM_DESC=""
if [[ -f "$TEAM_DIR/README.md" ]]; then
    # Second non-empty line (first is the title)
    TEAM_DESC=$(awk 'NF && !/^#/{print; exit}' "$TEAM_DIR/README.md")
fi

header "${TEAM_SLUG} — Team Status"
[[ -n "$TEAM_DESC" ]] && info "$TEAM_DESC"

# ============================================================================
# Overview
# ============================================================================

section "Overview"

# Cycle count
if [[ -f "$SCORES_FILE" ]] && command -v python3 &>/dev/null; then
    CYCLE=$(python3 -c "
import json
with open('${SCORES_FILE}') as f:
    data = json.load(f)
print(data.get('metadata',{}).get('current_cycle',0))
" 2>/dev/null || echo "0")
    LAST_UPDATED=$(python3 -c "
import json
with open('${SCORES_FILE}') as f:
    data = json.load(f)
print(data.get('metadata',{}).get('last_updated','unknown'))
" 2>/dev/null || echo "unknown")
else
    CYCLE="0"
    LAST_UPDATED="unknown"
fi

# Count agents
AGENT_COUNT=$(find "$TEAM_DIR/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)

# Count feedback files
FEEDBACK_COUNT=$(find "$TEAM_DIR/feedback" -name "*.md" ! -name "template.md" 2>/dev/null | wc -l)

# Operational mode from constitution
OP_MODE="unknown"
if [[ -f "$TEAM_DIR/shared/constitution.md" ]]; then
    OP_MODE=$(grep -oP 'Agents are \K[^.*]+' "$TEAM_DIR/shared/constitution.md" 2>/dev/null | head -1 || echo "unknown")
fi

echo -e "  ${BOLD}Cycles completed:${NC}  ${CYCLE}"
echo -e "  ${BOLD}Last updated:${NC}      ${LAST_UPDATED}"
echo -e "  ${BOLD}Agents:${NC}            ${AGENT_COUNT}"
echo -e "  ${BOLD}Feedback files:${NC}    ${FEEDBACK_COUNT}"
echo -e "  ${BOLD}Operational mode:${NC}  ${OP_MODE}"

# Git status
if git -C "$TEAM_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    dirty=$(git -C "$TEAM_DIR" status --porcelain 2>/dev/null | wc -l)
    if [[ "$dirty" -gt 0 ]]; then
        echo -e "  ${BOLD}Git:${NC}               ${YELLOW}${dirty} uncommitted changes${NC}"
    else
        echo -e "  ${BOLD}Git:${NC}               ${GREEN}clean${NC}"
    fi
fi

# ============================================================================
# Agent Scores
# ============================================================================

section "Agent Scores"

if [[ -f "$SCORES_FILE" ]] && command -v python3 &>/dev/null; then
    python3 << 'PYSCORES' - "$SCORES_FILE"
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

agents = data.get("agents", {})
if not agents:
    print("  (no agents tracked)")
    sys.exit(0)

# Header
print(f"  {'Agent':<25} {'Score':>6} {'Avg':>6} {'Trend':>12} {'Cycles':>7}")
print(f"  {'─'*25} {'─'*6} {'─'*6} {'─'*12} {'─'*7}")

for name, info in sorted(agents.items()):
    scores = info.get("scores", [])
    if scores:
        latest = scores[-1].get("overall", "—")
        # Color coding via ANSI
        if latest >= 4:
            score_str = f"\033[0;32m{latest}/5\033[0m"
        elif latest >= 3:
            score_str = f"\033[1;33m{latest}/5\033[0m"
        else:
            score_str = f"\033[0;31m{latest}/5\033[0m"
    else:
        latest = "—"
        score_str = "  —"

    avg = info.get("rolling_average")
    avg_str = f"{avg:.1f}" if avg else "  —"

    trend = info.get("trend", "—")
    trend_icons = {
        "improving": "\033[0;32m↑ improving\033[0m",
        "declining": "\033[0;31m↓ declining\033[0m",
        "stable":    "→ stable",
        "new":       "\033[2m● new\033[0m"
    }
    trend_str = trend_icons.get(trend, trend)

    cycles = info.get("cycles_completed", 0)

    # Raw print with ANSI
    print(f"  {name:<25} {score_str:>17} {avg_str:>6} {trend_str:>23} {cycles:>7}")
PYSCORES
else
    info "  (no scores recorded yet — run update-scores.sh after your first cycle)"
fi

# ============================================================================
# Recent Feedback
# ============================================================================

section "Recent Feedback"

recent_fb=$(find "$TEAM_DIR/feedback" -name "*.md" ! -name "template.md" -type f 2>/dev/null | sort -r | head -5)
if [[ -z "$recent_fb" ]]; then
    info "  (no feedback yet — run new-feedback.sh)"
else
    while IFS= read -r fb; do
        rel="${fb#${TEAM_DIR}/}"
        # Count items in the file
        items=$(grep -c "^### Item" "$fb" 2>/dev/null || echo "0")
        echo -e "  ${CYAN}${rel}${NC}  (${items} items)"
    done <<< "$recent_fb"
fi

# ============================================================================
# Cycle History
# ============================================================================

section "Cycle History"

cycle_dirs=$(find "$TEAM_DIR/evals" -maxdepth 1 -name "cycle-*" -type d 2>/dev/null | sort -V)
if [[ -z "$cycle_dirs" ]]; then
    info "  (no cycles run yet — run run-cycle.sh)"
else
    while IFS= read -r cdir; do
        cname=$(basename "$cdir")
        status=""
        if [[ -f "$cdir/REJECTED" ]]; then
            status="${RED}REJECTED${NC}"
        elif [[ -f "$cdir/evolution-proposal.md" && -f "$cdir/audit-report.md" ]]; then
            status="${GREEN}complete${NC}"
        elif [[ -f "$cdir/evolution-proposal.md" ]]; then
            status="${YELLOW}pending audit${NC}"
        else
            status="${DIM}in progress${NC}"
        fi
        echo -e "  ${cname}  ${status}"
    done <<< "$cycle_dirs"
fi

# ============================================================================
# Drift Check
# ============================================================================

section "Drift Check"

drift_found=false
for agent_dir in "$TEAM_DIR/agents"/*/; do
    [[ -d "$agent_dir" ]] || continue
    agent_name=$(basename "$agent_dir")
    changelog="$agent_dir/CHANGELOG.md"

    if [[ -f "$changelog" ]]; then
        # Count changelog entries (proxy for number of modifications)
        changes=$(grep -c "^## \[" "$changelog" 2>/dev/null || echo "0")
        if [[ "$changes" -gt 5 ]]; then
            echo -e "  ${YELLOW}⚠ ${agent_name}${NC}: ${changes} changelog entries — consider reviewing for cumulative drift"
            drift_found=true
        fi

        # Check for oscillation (same section changed multiple times)
        if grep -q "oscillat" "$changelog" 2>/dev/null; then
            echo -e "  ${RED}⚠ ${agent_name}${NC}: oscillation detected in changelog"
            drift_found=true
        fi
    fi
done

if ! $drift_found; then
    echo -e "  ${GREEN}✓ No drift warnings${NC}"
fi

# ============================================================================
# Quick Commands
# ============================================================================

section "Quick Commands"

echo -e "  ${DIM}# Run an agent${NC}"
first_agent=$(find "$TEAM_DIR/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "agent-name")
echo -e "  ./run-agent.sh ${TEAM_SLUG} ${first_agent}"
echo ""
echo -e "  ${DIM}# Start a feedback cycle${NC}"
echo -e "  ./new-feedback.sh ${TEAM_SLUG}"
echo ""
echo -e "  ${DIM}# Process feedback${NC}"
echo -e "  ./run-cycle.sh ${TEAM_SLUG}"
echo ""
echo -e "  ${DIM}# Record scores${NC}"
echo -e "  ./update-scores.sh ${TEAM_SLUG}"
echo ""
