#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# run-agent.sh — Run a specific agent with context loading
#
# Usage: ./run-agent.sh <team-slug> <agent-name> [prompt]
#
# Loads the agent's system prompt plus all context_sources from agent.yaml,
# then invokes claude with everything wired up. If no prompt is given,
# drops you into an interactive session.
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

# --- Resolve paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEAMS_DIR="${SCRIPT_DIR}/../teams"

# --- Usage ---
usage() {
    echo "Usage: $(basename "$0") <team-slug> <agent-name> [prompt]"
    echo ""
    echo "  team-slug   Name of the team directory under teams/"
    echo "  agent-name  Name of the agent (or 'meta-agent' or 'auditor')"
    echo "  prompt      Optional one-shot prompt. Omit for interactive session."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") devops incident-response"
    echo "  $(basename "$0") devops meta-agent"
    echo "  $(basename "$0") devops auditor"
    echo "  $(basename "$0") sales content-writer \"Draft a cold outreach email for SaaS CTOs\""
    echo ""
    echo "Available teams:"
    if [[ -d "$TEAMS_DIR" ]]; then
        for d in "$TEAMS_DIR"/*/; do
            [[ -d "$d" ]] && echo "  $(basename "$d")"
        done
    else
        echo "  (none — run build-team-template.sh first)"
    fi
    exit 1
}

[[ $# -lt 2 ]] && usage

TEAM_SLUG="$1"
AGENT_NAME="$2"
PROMPT="${3:-}"

TEAM_DIR="${TEAMS_DIR}/${TEAM_SLUG}"
[[ -d "$TEAM_DIR" ]] || die "Team '${TEAM_SLUG}' not found at ${TEAM_DIR}"

# --- Resolve agent path ---
if [[ "$AGENT_NAME" == "meta-agent" ]]; then
    AGENT_DIR="${TEAM_DIR}/meta-agent"
elif [[ "$AGENT_NAME" == "auditor" ]]; then
    AGENT_DIR="${TEAM_DIR}/auditor"
else
    AGENT_DIR="${TEAM_DIR}/agents/${AGENT_NAME}"
fi

[[ -d "$AGENT_DIR" ]] || die "Agent '${AGENT_NAME}' not found at ${AGENT_DIR}"
[[ -f "$AGENT_DIR/system-prompt.md" ]] || die "No system-prompt.md found in ${AGENT_DIR}"

# --- Parse context sources from agent.yaml ---
CONTEXT_FILES=()
if [[ -f "$AGENT_DIR/agent.yaml" ]]; then
    # Extract context_sources list from yaml (simple parser — handles "  - path" lines)
    in_context=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^context_sources: ]]; then
            in_context=true
            continue
        fi
        if $in_context; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
                src="${BASH_REMATCH[1]}"
                # Resolve relative to team dir
                full_path="${TEAM_DIR}/${src}"
                if [[ -f "$full_path" ]]; then
                    CONTEXT_FILES+=("$full_path")
                elif [[ -d "$full_path" ]]; then
                    # For directories (like feedback/), grab most recent files
                    while IFS= read -r f; do
                        CONTEXT_FILES+=("$f")
                    done < <(find "$full_path" -name "*.md" -o -name "*.json" | sort -r | head -10)
                fi
            elif [[ ! "$line" =~ ^[[:space:]] ]]; then
                in_context=false
            fi
        fi
    done < "$AGENT_DIR/agent.yaml"
fi

# --- Build the combined system prompt ---
COMBINED_PROMPT=$(mktemp /tmp/agent-prompt-XXXXXX.md)
trap "rm -f '$COMBINED_PROMPT'" EXIT

# Start with the agent's own system prompt
cat "$AGENT_DIR/system-prompt.md" > "$COMBINED_PROMPT"

# Append context sources
if [[ ${#CONTEXT_FILES[@]} -gt 0 ]]; then
    echo "" >> "$COMBINED_PROMPT"
    echo "---" >> "$COMBINED_PROMPT"
    echo "" >> "$COMBINED_PROMPT"
    echo "# Context" >> "$COMBINED_PROMPT"
    echo "" >> "$COMBINED_PROMPT"
    for ctx in "${CONTEXT_FILES[@]}"; do
        rel_path="${ctx#${TEAM_DIR}/}"
        echo "## ${rel_path}" >> "$COMBINED_PROMPT"
        echo "" >> "$COMBINED_PROMPT"
        cat "$ctx" >> "$COMBINED_PROMPT"
        echo "" >> "$COMBINED_PROMPT"
    done
fi

# --- Display info ---
header "Running: ${AGENT_NAME}"
info "Team: ${TEAM_SLUG}"
info "System prompt: ${AGENT_DIR}/system-prompt.md"
if [[ ${#CONTEXT_FILES[@]} -gt 0 ]]; then
    info "Context loaded (${#CONTEXT_FILES[@]} files):"
    for ctx in "${CONTEXT_FILES[@]}"; do
        info "  ${ctx#${TEAM_DIR}/}"
    done
fi
echo ""

# --- Check for claude CLI ---
if ! command -v claude &>/dev/null; then
    die "claude CLI not found. Install it: npm install -g @anthropic-ai/claude-code"
fi

# --- Run ---
if [[ -n "$PROMPT" ]]; then
    info "Mode: one-shot"
    echo ""
    claude --system-prompt "$COMBINED_PROMPT" --prompt "$PROMPT"
else
    info "Mode: interactive (Ctrl+C to exit)"
    echo ""
    claude --system-prompt "$COMBINED_PROMPT"
fi
