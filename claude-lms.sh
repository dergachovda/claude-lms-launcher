#!/usr/bin/env bash
set -euo pipefail

# Використання: ./claude-lms.sh [ID_моделі] [Довжина_контексту]
# ID моделі дивіться командою: lms ls
MODEL="${1:-google/gemma-4-e2b}"
CONTEXT_LENGTH="${2:-32768}"
PORT=1234
is_lms_server_started=false
is_model_loaded=false

cleanup() {
    local exit_status=$?
    local cleanup_status=0
    trap - EXIT

    if [[ "$is_model_loaded" == true ]]; then
        echo "Unloading model ..."
        if ! lms unload "$MODEL"; then
            echo "Failed to unload model: $MODEL" >&2
            cleanup_status=1
        fi
    fi
    if [[ "$is_lms_server_started" == true ]]; then
        echo "Stopping LLM Studio ..."
        if ! lms server stop; then
            echo "Failed to stop LLM Studio server" >&2
            cleanup_status=1
        fi
    fi

    if (( exit_status != 0 )); then
        exit "$exit_status"
    fi
    exit "$cleanup_status"
}
trap cleanup EXIT

# Запуск сервера, якщо він ще не запущений
server_status="$(lms server status 2>&1)"
case "$server_status" in
    *"not running"*)
        echo "Starting LLM Studio ..."
        lms server start --port "$PORT"
        is_lms_server_started=true
        ;;
    *"running"*)
        echo "LLM Studio server already running."
        ;;
    *)
        echo "Could not determine LLM Studio server status: $server_status" >&2
        exit 1
        ;;
esac

# Перевірка чи завантажена модель, якщо ні - завантажуємо
if ! lms ps | grep -F -- "$MODEL" >/dev/null; then
    echo "Loading model: $MODEL ..."
    lms load "$MODEL" --context-length "$CONTEXT_LENGTH"
    is_model_loaded=true
else
    echo "Model $MODEL already loaded."
fi

# Змінні для Claude Code
echo "Claude Code configuring ..."
export ANTHROPIC_BASE_URL="http://localhost:$PORT"
export ANTHROPIC_AUTH_TOKEN=lmstudio
export ANTHROPIC_API_KEY=""
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

echo "Launching Claude Code ..."

claude --model "$MODEL"
