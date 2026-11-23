#!/usr/bin/env bash
set -euo pipefail

# Використання: ./claude-lms.sh [ID_моделі] [Довжина_контексту]
# ID моделі дивіться командою: lms ls
MODEL="${1:-google/gemma-4-e2b}"
CONTEXT_LENGTH="${2:-32768}"
PORT=1234

# Запуск сервера (якщо вже запущений, команда просто нічого не змінить)
echo "Starting LLM Studio ..."
lms server start --port "$PORT"

# Перевірка чи завантажена модель з відповідною довжиною контексту, якщо ні - завантажуємо
if ! lms ps | grep -q "$MODEL"; then
    # Завантаження моделі
    echo "Loading model: $MODEL ..."
    lms load "$MODEL" --context-length "$CONTEXT_LENGTH"
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

cleanup() {
    local exit_status=$?
    local cleanup_status=0
    trap - EXIT

    echo "Stopping LLM Studio ..."
    if ! lms unload "$MODEL"; then
        echo "Failed to unload model: $MODEL" >&2
        cleanup_status=1
    fi
    if ! lms server stop; then
        echo "Failed to stop LLM Studio server" >&2
        cleanup_status=1
    fi

    if (( exit_status != 0 )); then
        exit "$exit_status"
    fi
    exit "$cleanup_status"
}
trap cleanup EXIT

claude --model "$MODEL"
