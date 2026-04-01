#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "Creating shared Docker network: olo-net (if needed)..."
if ! docker network inspect olo-net >/dev/null 2>&1; then
  docker network create olo-net
fi

echo "Pulling latest OLO images (olo, olo-worker, olo-ui, olo-chat)..."
docker pull openllmorchestrator/olo:latest
docker pull openllmorchestrator/olo-worker:latest
docker pull openllmorchestrator/olo-ui:latest
docker pull openllmorchestrator/olo-chat:latest

echo
echo "Text AI is always enabled."
read -r -p "Deploy speech/audio AI? [y/N]: " DEPLOY_SPEECH_ANSWER
read -r -p "Deploy image AI? [y/N]: " DEPLOY_IMAGE_ANSWER
read -r -p "Deploy video AI? [y/N]: " DEPLOY_VIDEO_ANSWER

COMPOSE_FILES=(
  docker-compose-db.yml
  docker-compose-cache.yml
  docker-compose-ElasticSearch.yml
  docker-compose-vectordb.yml
  docker-compose-temporal.yml
  docker-compose-olo.yml
  docker-compose-ai-text.yml
)

AI_SELECTED="text"
case "$DEPLOY_SPEECH_ANSWER" in
  [Yy]*) COMPOSE_FILES+=(docker-compose-ai-audio.yml); AI_SELECTED="$AI_SELECTED speech" ;;
esac
case "$DEPLOY_IMAGE_ANSWER" in
  [Yy]*) COMPOSE_FILES+=(docker-compose-ai-image.yml); AI_SELECTED="$AI_SELECTED image" ;;
esac
case "$DEPLOY_VIDEO_ANSWER" in
  [Yy]*) COMPOSE_FILES+=(docker-compose-ai-video.yml); AI_SELECTED="$AI_SELECTED video" ;;
esac

echo "Bringing up OLO dev stack (project: olo)..."
echo "Core containers: db, cache, elastic, vectordb, temporal, olo"
echo "AI containers: $AI_SELECTED"

COMPOSE_CMD=(docker compose -p olo)
for compose_file in "${COMPOSE_FILES[@]}"; do
  COMPOSE_CMD+=(-f "$compose_file")
done
COMPOSE_CMD+=(up -d)
"${COMPOSE_CMD[@]}"

echo "Dev OLO stack is up (project: olo)."

echo "Waiting for Ollama, then pulling models (llama3.2, mistral, phi3, etc.)..."
sleep 5
"$(dirname "$0")/scripts/ollama-pull-models.sh" || true

echo "Waiting for LocalAI (openai-oss), then installing models..."
sleep 5
"$(dirname "$0")/scripts/openai-oss-pull-models.sh" || true

echo "Done."
