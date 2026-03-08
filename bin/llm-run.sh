#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# llm-run.sh — Provider-agnostic LLM invocation
#
# Usage:
#   llm-run.sh --system-file FILE --prompt TEXT [options]
#   llm-run.sh --system-file FILE --interactive [options]
#
# Options:
#   --provider PROVIDER   claude | llm | ollama | openai
#   --model MODEL         model ID override
#
# Config (priority order):
#   1. CLI flags (--provider, --model)
#   2. AGENT_PROVIDER / AGENT_MODEL environment variables
#   3. .agent-teams.env file in repo root
#   4. Provider defaults
#
# Supported providers:
#   claude   Anthropic Claude Code CLI (default)
#            Requires: npm install -g @anthropic-ai/claude-code
#
#   llm      Simon Willison's multi-provider llm tool
#            Requires: pip install llm
#            Supports: OpenAI, Anthropic, Gemini, Ollama, and more via plugins
#            See: https://llm.datasette.io
#
#   ollama   Local models via Ollama
#            Requires: https://ollama.ai
#            Default model: llama3.2
#
#   openai   OpenAI-compatible API via curl + jq
#            Requires: OPENAI_API_KEY or AGENT_API_KEY in .agent-teams.env
#            Also works with local servers (LM Studio, vLLM, etc.)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Load .agent-teams.env if present ---
if [[ -f "${REPO_ROOT}/.agent-teams.env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/.agent-teams.env"
    set +a
fi

# --- Defaults (may be overridden by env or CLI) ---
SYSTEM_FILE=""
PROMPT_TEXT=""
INTERACTIVE=false
PROVIDER="${AGENT_PROVIDER:-claude}"
MODEL="${AGENT_MODEL:-}"

usage() {
    echo "Usage: $(basename "$0") --system-file FILE (--prompt TEXT | --interactive) [--provider PROVIDER] [--model MODEL]"
    echo ""
    echo "Providers: claude (default), llm, ollama, openai"
    echo ""
    echo "Configure globally via .agent-teams.env (copy from .agent-teams.env.example):"
    echo "  AGENT_PROVIDER=ollama"
    echo "  AGENT_MODEL=llama3.2"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system-file)  SYSTEM_FILE="$2";  shift 2 ;;
        --prompt)       PROMPT_TEXT="$2";  shift 2 ;;
        --provider)     PROVIDER="$2";     shift 2 ;;
        --model)        MODEL="$2";        shift 2 ;;
        --interactive)  INTERACTIVE=true;  shift ;;
        -h|--help)      usage ;;
        *) echo "Error: Unknown argument: $1" >&2; usage ;;
    esac
done

[[ -n "$SYSTEM_FILE" ]] || { echo "Error: --system-file is required." >&2; usage; }
[[ -f "$SYSTEM_FILE" ]]  || { echo "Error: System file not found: $SYSTEM_FILE" >&2; exit 1; }

if ! $INTERACTIVE && [[ -z "$PROMPT_TEXT" ]]; then
    echo "Error: Either --prompt TEXT or --interactive is required." >&2
    usage
fi

# ============================================================================
# Provider dispatch
# ============================================================================

case "$PROVIDER" in

    # ── Claude Code CLI ────────────────────────────────────────────────────
    claude|anthropic)
        command -v claude &>/dev/null || {
            echo "Error: claude CLI not found." >&2
            echo "       Install: npm install -g @anthropic-ai/claude-code" >&2
            exit 1
        }
        if $INTERACTIVE; then
            exec claude --system-prompt "$SYSTEM_FILE"
        else
            exec claude --system-prompt "$SYSTEM_FILE" -p "$PROMPT_TEXT"
        fi
        ;;

    # ── Simon Willison's llm tool ──────────────────────────────────────────
    llm)
        command -v llm &>/dev/null || {
            echo "Error: 'llm' CLI not found." >&2
            echo "       Install: pip install llm" >&2
            echo "       Docs: https://llm.datasette.io" >&2
            exit 1
        }
        SYSTEM_CONTENT="$(cat "$SYSTEM_FILE")"
        MODEL_ARGS=()
        [[ -n "$MODEL" ]] && MODEL_ARGS=(-m "$MODEL")
        if $INTERACTIVE; then
            exec llm chat -s "$SYSTEM_CONTENT" "${MODEL_ARGS[@]}"
        else
            printf '%s' "$PROMPT_TEXT" | exec llm -s "$SYSTEM_CONTENT" "${MODEL_ARGS[@]}"
        fi
        ;;

    # ── Ollama (local models) ──────────────────────────────────────────────
    ollama)
        command -v ollama &>/dev/null || {
            echo "Error: ollama not found." >&2
            echo "       Install: https://ollama.ai" >&2
            exit 1
        }
        MODEL="${MODEL:-llama3.2}"
        SYSTEM_CONTENT="$(cat "$SYSTEM_FILE")"
        if $INTERACTIVE; then
            exec ollama run "$MODEL" --system "$SYSTEM_CONTENT"
        else
            printf '%s' "$PROMPT_TEXT" | exec ollama run "$MODEL" --system "$SYSTEM_CONTENT"
        fi
        ;;

    # ── OpenAI-compatible API (curl + jq) ─────────────────────────────────
    openai)
        command -v curl &>/dev/null || { echo "Error: curl not found." >&2; exit 1; }
        command -v jq   &>/dev/null || {
            echo "Error: jq not found." >&2
            echo "       Install: brew install jq  (macOS) or apt install jq" >&2
            exit 1
        }
        if $INTERACTIVE; then
            echo "Error: Interactive mode is not supported for the openai provider." >&2
            exit 1
        fi
        API_KEY="${OPENAI_API_KEY:-${AGENT_API_KEY:-}}"
        [[ -n "$API_KEY" ]] || {
            echo "Error: No API key found." >&2
            echo "       Set OPENAI_API_KEY or AGENT_API_KEY in .agent-teams.env" >&2
            exit 1
        }
        API_BASE="${AGENT_API_BASE:-https://api.openai.com/v1}"
        MODEL="${MODEL:-gpt-4o}"
        SYSTEM_CONTENT="$(cat "$SYSTEM_FILE")"
        curl -s "${API_BASE}/chat/completions" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
                --arg model   "$MODEL" \
                --arg system  "$SYSTEM_CONTENT" \
                --arg user    "$PROMPT_TEXT" \
                '{model: $model, messages: [{role:"system",content:$system},{role:"user",content:$user}]}')" \
            | jq -r '.choices[0].message.content'
        ;;

    *)
        echo "Error: Unknown provider '${PROVIDER}'." >&2
        echo "Valid providers: claude, llm, ollama, openai" >&2
        exit 1
        ;;
esac
