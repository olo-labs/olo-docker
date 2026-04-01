#!/usr/bin/env bash
# Install open-source models into LocalAI (openai-oss) via /models/apply API.
# Run from repo root or dev folder. Requires dev stack up.
# Edit MODELS below to add/remove. Gallery: https://models.localai.io

set -e
container=$(docker ps --filter "name=openai-oss" --format "{{.Names}}" | head -1)
if [ -z "$container" ]; then
    echo "No running LocalAI (openai-oss) container found. Skipping model install."
    exit 0
fi
container=$(echo "$container" | tr -d '\r')
echo "Using container: $container"

# Gallery model IDs for POST /models/apply. See https://models.localai.io
MODELS=(
    llama-3.2-1b-instruct
    llama-3.2-3b-instruct
    phi-2
    mistral-openorca
    hermes-2-theta-llama-3-8b
)

# LocalAI may be published on 8090 (ai-text) or 8082 (ai-audio). Call API from host.
echo "Installing LocalAI models via /models/apply API (trying host ports 8090, 8082)"
for m in "${MODELS[@]}"; do
    echo "Install $m ..."
    if curl -s -X POST "http://localhost:8090/models/apply" -H "Content-Type: application/json" -d "{\"id\":\"$m\"}" --max-time 300 2>/dev/null; then
        :
    elif curl -s -X POST "http://localhost:8082/models/apply" -H "Content-Type: application/json" -d "{\"id\":\"$m\"}" --max-time 300 2>/dev/null; then
        :
    else
        echo "  (install failed or skipped: $m)"
    fi
done
echo "Done. List models: curl -s http://localhost:8090/v1/models (or 8082 for audio stack)"
