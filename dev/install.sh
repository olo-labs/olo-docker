#!/usr/bin/env bash

set -u
set -o pipefail

cd "$(dirname "$0")"

# ============================================================
# OLO Development Stack Installer
# ============================================================

echo
echo "============================================================"
echo "OLO Development Stack Installer"
echo "============================================================"
echo "Working directory : $(pwd)"
echo "Started at        : $(date)"
echo "============================================================"
echo


# ============================================================
# FUNCTIONS
# ============================================================

pull_image() {

    local image_name="$1"

    echo "------------------------------------------------------------"
    echo "[INFO] Pulling image: $image_name"
    echo "------------------------------------------------------------"

    if ! docker pull "$image_name"; then
        echo
        echo "[ERROR] Failed to pull Docker image:"
        echo "        $image_name"
        echo
        echo "Probable causes:"
        echo "  - Internet connection problem."
        echo "  - Docker Hub is unavailable."
        echo "  - Image name or tag is incorrect."
        echo "  - Docker Hub rate limit."
        echo "  - Docker registry authentication problem."
        echo
        exit 1
    fi

    echo "[OK] Image pulled: $image_name"
    echo
}


show_compose_status() {

    echo
    echo "Current Docker Compose container status:"
    echo

    "${COMPOSE_BASE_CMD[@]}" ps || true
}


show_ollama_diagnostics() {

    echo
    echo "Ollama container status:"
    echo

    docker ps -a --filter "name=olo-ollama" || true

    echo
    echo "Recent Ollama logs:"
    echo

    docker logs --tail 100 olo-ollama 2>&1 || true
}


show_localai_diagnostics() {

    echo
    echo "LocalAI container status:"
    echo

    docker ps -a --filter "name=olo-openai-oss" || true

    echo
    echo "Recent LocalAI logs:"
    echo

    docker logs --tail 100 olo-openai-oss 2>&1 || true
}


# ============================================================
# STEP 1 - Verify Docker
# ============================================================

echo "[STEP 1] Checking Docker availability..."

if ! docker version >/dev/null 2>&1; then
    echo
    echo "[ERROR] Docker is not available."
    echo
    echo "Probable causes:"
    echo "  - Docker service is not running."
    echo "  - Docker CLI is not installed."
    echo "  - Docker CLI is not available in PATH."
    echo "  - Current user does not have Docker permissions."
    echo
    echo "Try running:"
    echo "  docker version"
    echo
    exit 1
fi

echo "[OK] Docker is available."
echo


# ============================================================
# STEP 2 - Verify Docker Compose
# ============================================================

echo "[STEP 2] Checking Docker Compose availability..."

if ! docker compose version >/dev/null 2>&1; then
    echo
    echo "[ERROR] Docker Compose is not available."
    echo
    echo "Probable causes:"
    echo "  - Docker Compose plugin is not installed."
    echo "  - Installed Docker version is too old."
    echo
    echo "Try running:"
    echo "  docker compose version"
    echo
    exit 1
fi

echo "[OK] Docker Compose is available."
echo


# ============================================================
# STEP 3 - Create shared Docker network
# ============================================================

echo "[STEP 3] Checking Docker network: olo-net"

if ! docker network inspect olo-net >/dev/null 2>&1; then

    echo "[INFO] Network olo-net does not exist."
    echo "[INFO] Creating network olo-net..."

    if ! docker network create olo-net; then
        echo
        echo "[ERROR] Failed to create Docker network olo-net."
        echo
        echo "Probable causes:"
        echo "  - Docker Engine is unavailable."
        echo "  - Docker daemon permission problem."
        echo "  - Docker network configuration problem."
        echo
        exit 1
    fi

    echo "[OK] Network olo-net created."

else

    echo "[OK] Network olo-net already exists."

fi

echo


# ============================================================
# STEP 4 - Pull latest OLO images
# ============================================================

echo "[STEP 4] Pulling latest OLO images..."
echo

pull_image "openllmorchestrator/olo:latest"
pull_image "openllmorchestrator/olo-worker:latest"
pull_image "openllmorchestrator/olo-ui:latest"
pull_image "openllmorchestrator/olo-chat:latest"

echo "[OK] OLO images pulled successfully."
echo


# ============================================================
# STEP 5 - Select AI containers
# ============================================================

echo "[STEP 5] Select AI containers to deploy"
echo

DEPLOY_TEXT=1

echo "[INFO] Text AI is always enabled."

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
    [Yy]*)
        COMPOSE_FILES+=(docker-compose-ai-audio.yml)
        AI_SELECTED="$AI_SELECTED speech"
        ;;
esac

case "$DEPLOY_IMAGE_ANSWER" in
    [Yy]*)
        COMPOSE_FILES+=(docker-compose-ai-image.yml)
        AI_SELECTED="$AI_SELECTED image"
        ;;
esac

case "$DEPLOY_VIDEO_ANSWER" in
    [Yy]*)
        COMPOSE_FILES+=(docker-compose-ai-video.yml)
        AI_SELECTED="$AI_SELECTED video"
        ;;
esac

echo
echo "AI Selection:"
echo "  Text   : enabled"

case "$DEPLOY_SPEECH_ANSWER" in
    [Yy]*) echo "  Speech : enabled" ;;
    *)     echo "  Speech : disabled" ;;
esac

case "$DEPLOY_IMAGE_ANSWER" in
    [Yy]*) echo "  Image  : enabled" ;;
    *)     echo "  Image  : disabled" ;;
esac

case "$DEPLOY_VIDEO_ANSWER" in
    [Yy]*) echo "  Video  : enabled" ;;
    *)     echo "  Video  : disabled" ;;
esac

echo


# ============================================================
# STEP 6 - Build Docker Compose command
# ============================================================

echo "[STEP 6] Building Docker Compose configuration..."

COMPOSE_BASE_CMD=(docker compose -p olo)

for compose_file in "${COMPOSE_FILES[@]}"; do

    if [[ ! -f "$compose_file" ]]; then
        echo
        echo "[ERROR] Docker Compose file does not exist:"
        echo "        $compose_file"
        echo
        echo "Probable causes:"
        echo "  - Repository checkout is incomplete."
        echo "  - Compose file was renamed."
        echo "  - Installer is running from the wrong directory."
        echo
        exit 1
    fi

    COMPOSE_BASE_CMD+=(-f "$compose_file")

done

echo "[INFO] Core containers:"
echo "       db, cache, elastic, vectordb, temporal, olo"

echo "[INFO] AI containers:"
echo "       $AI_SELECTED"

echo


# ============================================================
# STEP 7 - Validate Docker Compose configuration
# ============================================================

echo "[STEP 7] Validating Docker Compose configuration..."

if ! "${COMPOSE_BASE_CMD[@]}" config --quiet; then

    echo
    echo "[ERROR] Docker Compose configuration validation failed."
    echo
    echo "Probable causes:"
    echo "  - Docker Compose YAML syntax error."
    echo "  - Invalid environment variable."
    echo "  - Invalid volume configuration."
    echo "  - Invalid network configuration."
    echo
    echo "Running full Docker Compose validation:"
    echo

    "${COMPOSE_BASE_CMD[@]}" config || true

    exit 1
fi

echo "[OK] Docker Compose configuration is valid."
echo


# ============================================================
# STEP 8 - Start OLO stack
# ============================================================

echo "[STEP 8] Starting OLO development stack..."
echo

if ! "${COMPOSE_BASE_CMD[@]}" up -d; then

    echo
    echo "[ERROR] Docker Compose failed to start the OLO stack."
    echo
    echo "Probable causes:"
    echo "  - Container failed to start."
    echo "  - Port already in use."
    echo "  - Docker volume problem."
    echo "  - Docker network problem."
    echo "  - Insufficient memory."
    echo "  - Insufficient disk space."
    echo "  - Image startup failure."

    show_compose_status

    echo
    echo "Recent container logs:"
    echo

    "${COMPOSE_BASE_CMD[@]}" logs --tail 50 || true

    exit 1
fi

echo
echo "[OK] Docker Compose command completed."
echo


# ============================================================
# STEP 9 - Display container status
# ============================================================

echo "[STEP 9] Checking container status..."

show_compose_status

echo


# ============================================================
# STEP 10 - Wait for Ollama API
# ============================================================

echo "[STEP 10] Waiting for Ollama API..."
echo
echo "[INFO] Expected Ollama endpoint:"
echo "       http://localhost:11435/api/tags"
echo

OLLAMA_MAX_RETRIES=30
OLLAMA_RETRY=0
OLLAMA_READY=0

while [[ "$OLLAMA_RETRY" -lt "$OLLAMA_MAX_RETRIES" ]]; do

    OLLAMA_RETRY=$((OLLAMA_RETRY + 1))

    echo "[INFO] Ollama health check $OLLAMA_RETRY/$OLLAMA_MAX_RETRIES..."

    if curl \
        --silent \
        --show-error \
        --fail \
        --max-time 5 \
        http://localhost:11435/api/tags \
        >/dev/null 2>&1; then

        OLLAMA_READY=1
        break
    fi

    echo "[WAIT] Ollama API is not ready. Retrying in 5 seconds..."

    sleep 5

done


if [[ "$OLLAMA_READY" -ne 1 ]]; then

    echo
    echo "[ERROR] Ollama API did not become ready."
    echo
    echo "Probable causes:"
    echo "  - olo-ollama container failed."
    echo "  - Ollama is still starting."
    echo "  - Port 11435 is not exposed."
    echo "  - docker-compose-ai-text.yml has incorrect port mapping."
    echo "  - Ollama process crashed inside the container."
    echo "  - Host firewall is blocking port 11435."

    show_ollama_diagnostics

    echo
    echo "Installation cannot continue because models cannot be pulled."
    echo

    exit 1
fi

echo
echo "[OK] Ollama API is ready."
echo


# ============================================================
# STEP 11 - Display currently installed Ollama models
# ============================================================

echo "[STEP 11] Checking currently installed Ollama models..."
echo

if command -v python3 >/dev/null 2>&1; then

    if ! curl \
        --silent \
        --show-error \
        --fail \
        http://localhost:11435/api/tags \
        | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    models = data.get("models", [])

    if not models:
        print("[INFO] No Ollama models are currently installed.")
    else:
        print("[INFO] Installed Ollama models:")
        for model in models:
            print("       - " + model.get("name", "unknown"))

except Exception as exc:
    print("[WARNING] Unable to parse Ollama model list:", exc)
    sys.exit(1)
'; then

        echo "[WARNING] Unable to display Ollama model list."

    fi

else

    echo "[WARNING] python3 is not installed."
    echo "[INFO] Displaying raw Ollama API response:"
    echo

    curl \
        --silent \
        --show-error \
        http://localhost:11435/api/tags || true

    echo

fi

echo


# ============================================================
# STEP 12 - Pull Ollama models
# ============================================================

echo "[STEP 12] Installing Ollama models..."

OLLAMA_SCRIPT="$(pwd)/scripts/ollama-pull-models.sh"

echo "[INFO] Ollama model script:"
echo "       $OLLAMA_SCRIPT"
echo

if [[ ! -f "$OLLAMA_SCRIPT" ]]; then

    echo "[ERROR] Ollama model installation script does not exist."
    echo
    echo "Expected file:"
    echo "  $OLLAMA_SCRIPT"
    echo
    echo "Probable causes:"
    echo "  - scripts directory is missing."
    echo "  - ollama-pull-models.sh was not included."
    echo "  - Repository checkout is incomplete."
    echo

    exit 1
fi


if [[ ! -x "$OLLAMA_SCRIPT" ]]; then

    echo "[WARNING] Ollama model script is not executable."
    echo "[INFO] Attempting to add execute permission..."

    if ! chmod +x "$OLLAMA_SCRIPT"; then

        echo
        echo "[ERROR] Failed to make Ollama script executable."
        echo
        echo "Try running:"
        echo "  chmod +x $OLLAMA_SCRIPT"
        echo

        exit 1
    fi

    echo "[OK] Execute permission added."

fi

echo
echo "[INFO] Starting Ollama model installation script..."
echo

"$OLLAMA_SCRIPT"

OLLAMA_SCRIPT_EXIT=$?

echo
echo "[INFO] Ollama model script exit code: $OLLAMA_SCRIPT_EXIT"

if [[ "$OLLAMA_SCRIPT_EXIT" -ne 0 ]]; then

    echo
    echo "[ERROR] Ollama model installation failed."
    echo
    echo "Probable causes:"
    echo "  - Ollama API became unavailable."
    echo "  - Model download failed."
    echo "  - Internet connection problem."
    echo "  - Insufficient disk space."
    echo "  - Invalid Ollama model name."
    echo "  - Model installation script terminated with an error."

    show_ollama_diagnostics

    exit 1
fi

echo
echo "[OK] Ollama models installed successfully."
echo


# ============================================================
# STEP 13 - Verify installed Ollama models
# ============================================================

echo "[STEP 13] Verifying installed Ollama models..."
echo

OLLAMA_RESPONSE="$(
    curl \
        --silent \
        --show-error \
        --fail \
        --max-time 10 \
        http://localhost:11435/api/tags
)"

CURL_EXIT=$?

if [[ "$CURL_EXIT" -ne 0 ]]; then

    echo
    echo "[ERROR] Failed to retrieve installed Ollama models."
    echo
    echo "Probable causes:"
    echo "  - Ollama API became unavailable."
    echo "  - Ollama container restarted."
    echo "  - Network connection problem."

    show_ollama_diagnostics

    exit 1
fi


if [[ "$OLLAMA_RESPONSE" == *'"models":[]'* ]]; then

    echo
    echo "[ERROR] Ollama API is available but no models are installed."
    echo
    echo "Check the output of:"
    echo "  $OLLAMA_SCRIPT"
    echo

    exit 1
fi


echo "[OK] Ollama model verification completed."

if command -v python3 >/dev/null 2>&1; then

    echo "$OLLAMA_RESPONSE" | python3 -c '
import json
import sys

data = json.load(sys.stdin)

print("[OK] Installed Ollama models:")

for model in data.get("models", []):
    print("     - " + model.get("name", "unknown"))
'

else

    echo "$OLLAMA_RESPONSE"

fi

echo


# ============================================================
# STEP 14 - Install LocalAI models
# ============================================================

echo "[STEP 14] Installing LocalAI models..."

LOCALAI_SCRIPT="$(pwd)/scripts/openai-oss-pull-models.sh"

echo "[INFO] LocalAI model script:"
echo "       $LOCALAI_SCRIPT"
echo

if [[ ! -f "$LOCALAI_SCRIPT" ]]; then

    echo "[ERROR] LocalAI model installation script does not exist."
    echo
    echo "Expected file:"
    echo "  $LOCALAI_SCRIPT"
    echo

    exit 1
fi


if [[ ! -x "$LOCALAI_SCRIPT" ]]; then

    echo "[WARNING] LocalAI model script is not executable."
    echo "[INFO] Attempting to add execute permission..."

    if ! chmod +x "$LOCALAI_SCRIPT"; then

        echo
        echo "[ERROR] Failed to make LocalAI script executable."
        echo
        echo "Try running:"
        echo "  chmod +x $LOCALAI_SCRIPT"
        echo

        exit 1
    fi

    echo "[OK] Execute permission added."

fi

echo
echo "[INFO] Starting LocalAI model installation script..."
echo

"$LOCALAI_SCRIPT"

LOCALAI_SCRIPT_EXIT=$?

echo
echo "[INFO] LocalAI model script exit code: $LOCALAI_SCRIPT_EXIT"

if [[ "$LOCALAI_SCRIPT_EXIT" -ne 0 ]]; then

    echo
    echo "[ERROR] LocalAI model installation failed."
    echo
    echo "Probable causes:"
    echo "  - LocalAI container is not ready."
    echo "  - Model download failed."
    echo "  - Internet connection problem."
    echo "  - Insufficient disk space."
    echo "  - LocalAI model script failed."

    show_localai_diagnostics

    exit 1
fi

echo
echo "[OK] LocalAI models installed successfully."
echo


# ============================================================
# STEP 15 - Final container status
# ============================================================

echo "[STEP 15] Final container status..."

show_compose_status

echo


# ============================================================
# INSTALLATION COMPLETE
# ============================================================

echo "============================================================"
echo "OLO INSTALLATION COMPLETED SUCCESSFULLY"
echo "============================================================"
echo
echo "Installed components:"
echo "  - OLO Core"
echo "  - OLO Worker"
echo "  - OLO UI"
echo "  - OLO Chat"
echo "  - PostgreSQL"
echo "  - Redis"
echo "  - Elasticsearch"
echo "  - Qdrant"
echo "  - Temporal"
echo "  - Ollama"
echo "  - LocalAI"
echo
echo "AI containers:"
echo "  $AI_SELECTED"
echo
echo "Ollama API:"
echo "  http://localhost:11435/api/tags"
echo
echo "Completed at:"
echo "  $(date)"
echo
echo "============================================================"

exit 0
