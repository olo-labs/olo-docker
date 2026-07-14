#!/usr/bin/env bash

# ============================================================
# OLO Ollama Model Installer
#
# Pulls open-source models into the running OLO Ollama container.
#
# Expected containers:
#   - olo-ollama
#   - olo-ollama-audio
#
# Requires:
#   - Docker running
#   - OLO development stack running
#   - Ollama container available
# ============================================================

set -u
set -o pipefail


# ============================================================
# START
# ============================================================

echo
echo "============================================================"
echo "OLO Ollama Model Installer"
echo "============================================================"
echo "Started at : $(date)"
echo "============================================================"
echo


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
# STEP 2 - Find Ollama containers
# ============================================================

echo "[STEP 2] Looking for running Ollama container..."

mapfile -t CONTAINERS < <(
    docker ps \
        --filter "name=ollama" \
        --format "{{.Names}}"
)

DOCKER_PS_EXIT=${PIPESTATUS[0]}

if [[ "$DOCKER_PS_EXIT" -ne 0 ]]; then

    echo
    echo "[ERROR] Failed to query Docker containers."
    echo
    echo "Probable causes:"
    echo "  - Docker Engine became unavailable."
    echo "  - Docker daemon communication problem."
    echo "  - Current user does not have Docker permissions."
    echo

    exit 1
fi


# Remove empty entries if any
FILTERED_CONTAINERS=()

for found_container in "${CONTAINERS[@]}"; do

    found_container="${found_container//$'\r'/}"

    if [[ -n "$found_container" ]]; then
        FILTERED_CONTAINERS+=("$found_container")
    fi

done

CONTAINERS=("${FILTERED_CONTAINERS[@]}")


if [[ "${#CONTAINERS[@]}" -eq 0 ]]; then

    echo
    echo "[ERROR] No running Ollama container found."
    echo
    echo "Expected container:"
    echo "  - olo-ollama"
    echo "  - olo-ollama-audio"
    echo
    echo "Probable causes:"
    echo "  - OLO development stack is not running."
    echo "  - Ollama container failed to start."
    echo "  - Container name does not contain 'ollama'."
    echo
    echo "Current running containers:"
    echo

    docker ps \
        --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
        || true

    echo

    exit 1
fi


# ============================================================
# STEP 3 - Select Ollama container
# ============================================================

echo "[STEP 3] Selecting Ollama container..."

if [[ "${#CONTAINERS[@]}" -gt 1 ]]; then

    echo
    echo "[WARNING] Multiple Ollama containers found:"
    echo

    for found_container in "${CONTAINERS[@]}"; do
        echo "  - $found_container"
    done

    echo
    echo "[INFO] Using first running Ollama container."

fi


container="${CONTAINERS[0]}"

echo "[OK] Using container: $container"
echo


# ============================================================
# STEP 4 - Verify Ollama CLI inside container
# ============================================================

echo "[STEP 4] Checking Ollama CLI inside container..."

if ! docker exec "$container" ollama --version; then

    echo
    echo "[ERROR] Ollama CLI is not available inside container:"
    echo "        $container"
    echo
    echo "Probable causes:"
    echo "  - Wrong Docker container selected."
    echo "  - Ollama installation is broken."
    echo "  - Container is still starting."
    echo "  - Ollama process failed inside the container."
    echo
    echo "Recent container logs:"
    echo

    docker logs --tail 100 "$container" 2>&1 || true

    echo

    exit 1
fi

echo
echo "[OK] Ollama CLI is available."
echo


# ============================================================
# STEP 5 - Configure models
# ============================================================

echo "[STEP 5] Preparing Ollama model list..."

MODELS=(

    "llama3.2"
    "llama3.1:8b"
    "llama3.1:70b"

    "mistral"

    "phi3"
    "phi3:medium"

    "codellama"

    "gemma2:9b"
    "gemma2:2b"

    "qwen2:7b"
    "qwen2.5:7b"

    "deepseek-coder"

    "mistral-nemo:12b"

    "llava"
)

echo "[INFO] Models configured: ${#MODELS[@]}"

for model in "${MODELS[@]}"; do
    echo "       - $model"
done

echo


# ============================================================
# STEP 6 - Pull Ollama models
# ============================================================

echo "[STEP 6] Pulling Ollama models..."
echo

SUCCESSFUL_MODELS=()
FAILED_MODELS=()

MODEL_NUMBER=0
TOTAL_MODELS=${#MODELS[@]}


for model in "${MODELS[@]}"; do

    MODEL_NUMBER=$((MODEL_NUMBER + 1))

    echo
    echo "------------------------------------------------------------"
    echo "[MODEL $MODEL_NUMBER/$TOTAL_MODELS] $model"
    echo "------------------------------------------------------------"
    echo

    echo "[INFO] Pulling model: $model"
    echo

    # Keep stdout/stderr attached so Ollama download progress
    # remains visible in the terminal.
    docker exec "$container" ollama pull "$model"

    PULL_EXIT_CODE=$?

    echo

    if [[ "$PULL_EXIT_CODE" -eq 0 ]]; then

        echo "[OK] Model installed successfully: $model"

        SUCCESSFUL_MODELS+=("$model")

    else

        echo "[ERROR] Failed to install model: $model"
        echo "[INFO] Ollama exit code: $PULL_EXIT_CODE"
        echo
        echo "Probable causes:"
        echo "  - Internet connection problem."
        echo "  - Ollama registry unavailable."
        echo "  - Invalid or unavailable model name."
        echo "  - Insufficient disk space."
        echo "  - Ollama container became unavailable."
        echo "  - Model download was interrupted."

        FAILED_MODELS+=("$model")

    fi

done


# ============================================================
# STEP 7 - Display installed models
# ============================================================

echo
echo "============================================================"
echo "[STEP 7] Current Ollama model list"
echo "============================================================"
echo

docker exec "$container" ollama list

LIST_EXIT_CODE=$?

if [[ "$LIST_EXIT_CODE" -ne 0 ]]; then

    echo
    echo "[WARNING] Failed to retrieve Ollama model list."
    echo
    echo "Probable causes:"
    echo "  - Ollama container became unavailable."
    echo "  - Ollama process crashed."
    echo "  - Docker daemon became unavailable."
    echo

fi


# ============================================================
# STEP 8 - Installation summary
# ============================================================

echo
echo "============================================================"
echo "OLLAMA MODEL INSTALLATION SUMMARY"
echo "============================================================"
echo
echo "Container:"
echo "  $container"
echo
echo "Total models:"
echo "  ${#MODELS[@]}"
echo
echo "Successful:"
echo "  ${#SUCCESSFUL_MODELS[@]}"
echo
echo "Failed:"
echo "  ${#FAILED_MODELS[@]}"
echo


if [[ "${#SUCCESSFUL_MODELS[@]}" -gt 0 ]]; then

    echo "Successfully installed models:"
    echo

    for model in "${SUCCESSFUL_MODELS[@]}"; do
        echo "  [OK] $model"
    done

    echo

fi


if [[ "${#FAILED_MODELS[@]}" -gt 0 ]]; then

    echo "Failed models:"
    echo

    for model in "${FAILED_MODELS[@]}"; do
        echo "  [FAILED] $model"
    done

    echo
    echo "Recent Ollama container logs:"
    echo

    docker logs --tail 100 "$container" 2>&1 || true

    echo
    echo "============================================================"
    echo "OLLAMA MODEL INSTALLATION COMPLETED WITH ERRORS"
    echo "============================================================"
    echo
    echo "Completed at : $(date)"
    echo

    exit 1
fi


# ============================================================
# SUCCESS
# ============================================================

echo "============================================================"
echo "OLLAMA MODEL INSTALLATION COMPLETED SUCCESSFULLY"
echo "============================================================"
echo
echo "Installed models:"
echo

for model in "${SUCCESSFUL_MODELS[@]}"; do
    echo "  [OK] $model"
done

echo
echo "Completed at : $(date)"
echo

exit 0

