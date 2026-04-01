#!/usr/bin/env bash
# Pull Ollama open-source models into the Ollama container (olo-ollama or olo-ollama-audio).
# Run from repo root or dev folder. Requires dev stack up.
# Edit MODELS below to add/remove. See https://ollama.com/library

set -e
# Resolve container: merged compose may create olo-ollama-audio when both ai-text and ai-audio are used
container=$(docker ps --filter "name=ollama" --format "{{.Names}}" | head -1)
if [ -z "$container" ]; then
    echo "No running Ollama container found (expected olo-ollama or olo-ollama-audio). Skipping model pull."
    exit 0
fi
container=$(echo "$container" | tr -d '\r')
echo "Using container: $container"

MODELS=(
    llama3.2
    llama3.1:8b
    llama3.1:70b
    mistral
    phi3
    phi3:medium
    codellama
    gemma2:9b
    gemma2:2b
    qwen2:7b
    qwen2.5:7b
    deepseek-coder
    mistral-nemo:12b
    llava
)

echo "Pulling Ollama models into container: $container"
for m in "${MODELS[@]}"; do
    echo "Pull $m ..."
    docker exec "$container" ollama pull "$m" || echo "  (pull failed or skipped: $m)"
done
echo "Done. List: docker exec $container ollama list"
