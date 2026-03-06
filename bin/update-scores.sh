#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# update-scores.sh — Record evaluation scores after a cycle
#
# Usage: ./update-scores.sh <team-slug> [cycle-number]
#
# Walks through each agent and asks for a 1-5 rating plus optional
# dimension scores. Updates evals/baseline-scores.json with the results.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAMS_DIR="${SCRIPT_DIR}/teams"

usage() {
    echo "Usage: $(basename "$0") <team-slug> [cycle-number]"
    echo ""
    echo "  team-slug     Name of the team directory under teams/"
    echo "  cycle-number  Cycle to record scores for (auto-detected if omitted)"
    echo ""
    echo "Interactively records 1-5 scores per agent, updates baseline-scores.json."
    exit 1
}

[[ $# -lt 1 ]] && usage

TEAM_SLUG="$1"
TEAM_DIR="${TEAMS_DIR}/${TEAM_SLUG}"
[[ -d "$TEAM_DIR" ]] || die "Team '${TEAM_SLUG}' not found at ${TEAM_DIR}"

SCORES_FILE="${TEAM_DIR}/evals/baseline-scores.json"
[[ -f "$SCORES_FILE" ]] || die "No baseline-scores.json found. Was the team scaffolded correctly?"

command -v python3 &>/dev/null || die "python3 required for JSON manipulation"

# --- Determine cycle ---
if [[ -n "${2:-}" ]]; then
    CYCLE="$2"
else
    CYCLE=$(python3 -c "
import json
with open('${SCORES_FILE}') as f:
    data = json.load(f)
print(data.get('metadata', {}).get('current_cycle', 1))
" 2>/dev/null || echo "1")
fi

# --- Get agents and dimensions ---
AGENTS=()
for d in "$TEAM_DIR/agents"/*/; do
    [[ -d "$d" ]] && AGENTS+=("$(basename "$d")")
done

[[ ${#AGENTS[@]} -eq 0 ]] && die "No agents found in ${TEAM_DIR}/agents/"

# Get dimension names from scores file
DIMENSIONS=$(python3 -c "
import json
with open('${SCORES_FILE}') as f:
    data = json.load(f)
dims = data.get('score_schema', {}).get('dimensions', {})
for name, desc in dims.items():
    print(f'{name}|{desc}')
" 2>/dev/null || echo "")

header "Record Scores — Cycle ${CYCLE}"
info "Rate each agent's output from this cycle."
info "Scale: 1=unusable  2=significant issues  3=usable with edits  4=good  5=excellent"
echo ""

# --- Collect scores ---
declare -A AGENT_SCORES
declare -A AGENT_DIM_SCORES
declare -A AGENT_NOTES

for agent in "${AGENTS[@]}"; do
    section "Agent: ${agent}"

    # Show agent description
    if [[ -f "$TEAM_DIR/agents/$agent/agent.yaml" ]]; then
        desc=$(grep "^description:" "$TEAM_DIR/agents/$agent/agent.yaml" 2>/dev/null | sed 's/^description: *//')
        [[ -n "$desc" ]] && info "$desc"
    fi
    echo ""

    # Overall score
    while true; do
        prompt "Overall rating (1-5, or 's' to skip): "
        read -r score
        if [[ "$score" == "s" ]]; then
            AGENT_SCORES[$agent]="skip"
            break
        elif [[ "$score" =~ ^[1-5]$ ]]; then
            AGENT_SCORES[$agent]="$score"
            break
        else
            warn "Enter 1-5 or 's' to skip"
        fi
    done

    [[ "${AGENT_SCORES[$agent]}" == "skip" ]] && continue

    # Dimension scores (optional)
    if [[ -n "$DIMENSIONS" ]]; then
        echo ""
        info "Dimension scores (Enter to skip, 1-5 to score):"
        dim_json="{"
        first=true
        while IFS='|' read -r dim_name dim_desc; do
            [[ -z "$dim_name" ]] && continue
            prompt "  ${dim_name} (${dim_desc}): "
            read -r dscore
            if [[ "$dscore" =~ ^[1-5]$ ]]; then
                $first || dim_json+=","
                dim_json+="\"${dim_name}\": ${dscore}"
                first=false
            fi
        done <<< "$DIMENSIONS"
        dim_json+="}"
        AGENT_DIM_SCORES[$agent]="$dim_json"
    fi

    # Optional note
    echo ""
    prompt "Quick note (optional): "
    read -r note
    AGENT_NOTES[$agent]="$note"
done

# ============================================================================
# Update baseline-scores.json
# ============================================================================

section "Updating Scores"

# Build the Python update
SCORE_UPDATES=""
for agent in "${AGENTS[@]}"; do
    [[ "${AGENT_SCORES[$agent]:-skip}" == "skip" ]] && continue
    score="${AGENT_SCORES[$agent]}"
    dims="${AGENT_DIM_SCORES[$agent]:-{}}"
    note="${AGENT_NOTES[$agent]:-}"

    SCORE_UPDATES+="
    if '${agent}' not in data['agents']:
        data['agents']['${agent}'] = {
            'version': '1.0.0',
            'cycles_completed': 0,
            'scores': [],
            'rolling_average': None,
            'trend': None
        }
    agent_data = data['agents']['${agent}']
    agent_data['cycles_completed'] = ${CYCLE}
    new_score = {
        'cycle': ${CYCLE},
        'date': '$(date +%Y-%m-%d)',
        'overall': ${score},
        'dimensions': json.loads('${dims}'),
        'note': '${note}'
    }
    agent_data['scores'].append(new_score)

    # Calculate rolling average (last 5 cycles)
    recent = [s['overall'] for s in agent_data['scores'][-5:]]
    agent_data['rolling_average'] = round(sum(recent) / len(recent), 2)

    # Calculate trend
    if len(agent_data['scores']) >= 2:
        prev = agent_data['scores'][-2]['overall']
        curr = ${score}
        if curr > prev:
            agent_data['trend'] = 'improving'
        elif curr < prev:
            agent_data['trend'] = 'declining'
        else:
            agent_data['trend'] = 'stable'
    else:
        agent_data['trend'] = 'new'
"
done

if [[ -z "$SCORE_UPDATES" ]]; then
    warn "No scores recorded."
    exit 0
fi

python3 << PYEOF
import json

with open('${SCORES_FILE}') as f:
    data = json.load(f)

data['metadata']['current_cycle'] = ${CYCLE}
data['metadata']['last_updated'] = '$(date +%Y-%m-%d)'

${SCORE_UPDATES}

with open('${SCORES_FILE}', 'w') as f:
    json.dump(data, f, indent=2)

print("Scores updated successfully.")
PYEOF

success "Scores recorded for cycle ${CYCLE}"

# --- Show summary ---
echo ""
for agent in "${AGENTS[@]}"; do
    [[ "${AGENT_SCORES[$agent]:-skip}" == "skip" ]] && continue
    score="${AGENT_SCORES[$agent]}"
    case "$score" in
        5) color="$GREEN" ;;
        4) color="$GREEN" ;;
        3) color="$YELLOW" ;;
        2) color="$RED" ;;
        1) color="$RED" ;;
        *) color="$NC" ;;
    esac
    echo -e "  ${agent}: ${color}${score}/5${NC}"
done
echo ""

# Git commit option
if git -C "$TEAM_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    echo -en "${BOLD}Commit score update? [Y/n]: ${NC}"
    read -r yn
    yn="${yn:-y}"
    if [[ "${yn,,}" == "y" ]]; then
        git -C "$TEAM_DIR" add evals/
        git -C "$TEAM_DIR" commit -m "Cycle ${CYCLE}: recorded evaluation scores"
        success "Committed."
    fi
fi
