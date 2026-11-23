#!/usr/bin/env bash
set -euo pipefail

# Використання: ./claude-lms.sh [ID_моделі]
# ID моделі дивіться командою: lms ls
MODEL="${1:-qwen2.5-coder-7b-instruct}"
PORT=1234

# Запуск сервера (якщо вже запущений, команда просто нічого не змінить)
echo "Starting LLM Studio ..."
lms server start --port "$PORT"

# Завантаження моделі
echo "Loading model: $MODEL ..."
lms load "$MODEL"

# Змінні для Claude Code
echo "Claude Code configuring ..."
export ANTHROPIC_BASE_URL="http://localhost:$PORT"
export ANTHROPIC_AUTH_TOKEN=lmstudio
export ANTHROPIC_API_KEY=""
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

# exec замінює процес скрипта на claude
echo "Lunch Claude Code ..."
exec claude --model "$MODEL"
