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

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "============================================================"
Write-Host "OLO Ollama Model Installer"
Write-Host "============================================================"
Write-Host "Started at : $(Get-Date)"
Write-Host "============================================================"
Write-Host ""


# ============================================================
# STEP 1 - Verify Docker
# ============================================================

Write-Host "[STEP 1] Checking Docker availability..."

docker version *> $null

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "[ERROR] Docker is not available."
    Write-Host ""
    Write-Host "Probable causes:"
    Write-Host "  - Docker Desktop is not running."
    Write-Host "  - Docker CLI is not installed."
    Write-Host "  - Docker CLI is not available in PATH."
    Write-Host ""
    Write-Host "Try running:"
    Write-Host "  docker version"
    Write-Host ""

    exit 1
}

Write-Host "[OK] Docker is available."
Write-Host ""


# ============================================================
# STEP 2 - Find Ollama container
# ============================================================

Write-Host "[STEP 2] Looking for running Ollama container..."

$containers = @(
    docker ps `
        --filter "name=ollama" `
        --format "{{.Names}}"
)

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "[ERROR] Failed to query Docker containers."
    Write-Host ""
    Write-Host "Probable causes:"
    Write-Host "  - Docker Engine became unavailable."
    Write-Host "  - Docker daemon communication problem."
    Write-Host ""

    exit 1
}


$containers = @(
    $containers |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }
)


if ($containers.Count -eq 0) {

    Write-Host ""
    Write-Host "[ERROR] No running Ollama container found."
    Write-Host ""
    Write-Host "Expected container:"
    Write-Host "  - olo-ollama"
    Write-Host "  - olo-ollama-audio"
    Write-Host ""
    Write-Host "Probable causes:"
    Write-Host "  - OLO development stack is not running."
    Write-Host "  - Ollama container failed to start."
    Write-Host "  - Container name does not contain 'ollama'."
    Write-Host ""
    Write-Host "Current running containers:"
    Write-Host ""

    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    Write-Host ""

    exit 1
}


# ============================================================
# STEP 3 - Select Ollama container
# ============================================================

Write-Host "[STEP 3] Selecting Ollama container..."

if ($containers.Count -gt 1) {

    Write-Host ""
    Write-Host "[WARNING] Multiple Ollama containers found:"
    Write-Host ""

    foreach ($foundContainer in $containers) {
        Write-Host "  - $foundContainer"
    }

    Write-Host ""
    Write-Host "[INFO] Using first running Ollama container."

}

$container = $containers[0].Trim()

Write-Host "[OK] Using container: $container"
Write-Host ""


# ============================================================
# STEP 4 - Verify Ollama CLI inside container
# ============================================================

Write-Host "[STEP 4] Checking Ollama CLI inside container..."

docker exec $container ollama --version

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "[ERROR] Ollama CLI is not available inside container:"
    Write-Host "        $container"
    Write-Host ""
    Write-Host "Probable causes:"
    Write-Host "  - Wrong Docker container selected."
    Write-Host "  - Ollama installation is broken."
    Write-Host "  - Container is still starting."
    Write-Host ""

    Write-Host "Recent container logs:"
    Write-Host ""

    docker logs --tail 100 $container

    Write-Host ""

    exit 1
}

Write-Host ""
Write-Host "[OK] Ollama CLI is available."
Write-Host ""


# ============================================================
# STEP 5 - Configure models
# ============================================================

Write-Host "[STEP 5] Preparing Ollama model list..."

$models = @(

    "llama3.2",
    "llama3.1:8b",
    "llama3.1:70b",

    "mistral",

    "phi3",
    "phi3:medium",

    "codellama",

    "gemma2:9b",
    "gemma2:2b",

    "qwen2:7b",
    "qwen2.5:7b",

    "deepseek-coder",

    "mistral-nemo:12b",

    "llava"
)

Write-Host "[INFO] Models configured: $($models.Count)"

foreach ($model in $models) {
    Write-Host "       - $model"
}

Write-Host ""


# ============================================================
# STEP 6 - Pull Ollama models
# ============================================================

Write-Host "[STEP 6] Pulling Ollama models..."
Write-Host ""

$successfulModels = @()
$failedModels = @()

$modelNumber = 0


foreach ($model in $models) {

    $modelNumber++

    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "[MODEL $modelNumber/$($models.Count)] $model"
    Write-Host "------------------------------------------------------------"
    Write-Host ""

    Write-Host "[INFO] Pulling model: $model"
    Write-Host ""

    # Keep stdout/stderr attached so download progress remains visible.
    docker exec $container ollama pull $model

    $pullExitCode = $LASTEXITCODE

    Write-Host ""

    if ($pullExitCode -eq 0) {

        Write-Host "[OK] Model installed successfully: $model"

        $successfulModels += $model

    }
    else {

        Write-Host "[ERROR] Failed to install model: $model"
        Write-Host "[INFO] Ollama exit code: $pullExitCode"
        Write-Host ""
        Write-Host "Probable causes:"
        Write-Host "  - Internet connection problem."
        Write-Host "  - Ollama registry unavailable."
        Write-Host "  - Invalid or unavailable model name."
        Write-Host "  - Insufficient disk space."
        Write-Host "  - Ollama container became unavailable."
        Write-Host "  - Model download was interrupted."

        $failedModels += $model

    }

}


# ============================================================
# STEP 7 - Display installed models
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "[STEP 7] Current Ollama model list"
Write-Host "============================================================"
Write-Host ""

docker exec $container ollama list

$listExitCode = $LASTEXITCODE

if ($listExitCode -ne 0) {

    Write-Host ""
    Write-Host "[WARNING] Failed to retrieve Ollama model list."
    Write-Host ""
    Write-Host "Probable causes:"
    Write-Host "  - Ollama container became unavailable."
    Write-Host "  - Ollama process crashed."
    Write-Host ""

}


# ============================================================
# STEP 8 - Installation summary
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "OLLAMA MODEL INSTALLATION SUMMARY"
Write-Host "============================================================"
Write-Host ""
Write-Host "Container:"
Write-Host "  $container"
Write-Host ""
Write-Host "Total models:"
Write-Host "  $($models.Count)"
Write-Host ""
Write-Host "Successful:"
Write-Host "  $($successfulModels.Count)"
Write-Host ""
Write-Host "Failed:"
Write-Host "  $($failedModels.Count)"
Write-Host ""


if ($successfulModels.Count -gt 0) {

    Write-Host "Successfully installed models:"
    Write-Host ""

    foreach ($model in $successfulModels) {
        Write-Host "  [OK] $model"
    }

    Write-Host ""

}


if ($failedModels.Count -gt 0) {

    Write-Host "Failed models:"
    Write-Host ""

    foreach ($model in $failedModels) {
        Write-Host "  [FAILED] $model"
    }

    Write-Host ""
    Write-Host "Recent Ollama container logs:"
    Write-Host ""

    docker logs --tail 100 $container

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "OLLAMA MODEL INSTALLATION COMPLETED WITH ERRORS"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "Completed at : $(Get-Date)"
    Write-Host ""

    exit 1
}


# ============================================================
# SUCCESS
# ============================================================

Write-Host "============================================================"
Write-Host "OLLAMA MODEL INSTALLATION COMPLETED SUCCESSFULLY"
Write-Host "============================================================"
Write-Host ""
Write-Host "Installed models:"
Write-Host ""

foreach ($model in $successfulModels) {
    Write-Host "  [OK] $model"
}

Write-Host ""
Write-Host "Completed at : $(Get-Date)"
Write-Host ""

exit 0

