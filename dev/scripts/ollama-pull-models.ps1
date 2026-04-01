# Pull Ollama open-source models into the Ollama container (olo-ollama or olo-ollama-audio).
# Run from repo root or dev folder. Requires dev stack up.
# Edit $models below to add/remove models. See https://ollama.com/library

$ErrorActionPreference = "Continue"
# Resolve container: merged compose may create olo-ollama-audio when both ai-text and ai-audio are used
$container = docker ps --filter "name=ollama" --format "{{.Names}}" | Select-Object -First 1
if (-not $container) {
    Write-Host "No running Ollama container found (expected olo-ollama or olo-ollama-audio). Skipping model pull."
    exit 0
}
$container = $container.Trim()
Write-Host "Using container: $container"

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

Write-Host "Pulling Ollama models into container: $container"
foreach ($m in $models) {
    Write-Host "Pull $m ..."
    # Suppress stderr so Ollama progress output (written to stderr) does not trigger PowerShell errors
    $null = docker exec $container ollama pull $m 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  (pull failed or skipped: $m)" }
}
Write-Host "Done. List: docker exec $container ollama list"
