# Install open-source models into LocalAI (openai-oss) via /models/apply API.
# Run from repo root or dev folder. Requires dev stack up.
# Edit $models below to add/remove. Gallery: https://models.localai.io

$ErrorActionPreference = "Continue"
$container = docker ps --filter "name=openai-oss" --format "{{.Names}}" | Select-Object -First 1
if (-not $container) {
    Write-Host "No running LocalAI (openai-oss) container found. Skipping model install."
    exit 0
}
$container = $container.Trim()
Write-Host "Using container: $container"

# Gallery model IDs for POST /models/apply. See https://models.localai.io
$models = @(
    "llama-3.2-1b-instruct",
    "llama-3.2-3b-instruct",
    "phi-2",
    "mistral-openorca",
    "hermes-2-theta-llama-3-8b"
)

# LocalAI may be published on 8090 (ai-text) or 8082 (ai-audio)
$ports = @(8090, 8082)
Write-Host "Installing LocalAI models via /models/apply API (trying host ports 8090, 8082)"
foreach ($m in $models) {
    Write-Host "Install $m ..."
    $body = '{"id":"' + $m + '"}'
    $ok = $false
    foreach ($port in $ports) {
        try {
            $null = Invoke-RestMethod -Uri "http://localhost:${port}/models/apply" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300 -ErrorAction Stop
            $ok = $true
            break
        } catch { }
    }
    if (-not $ok) { Write-Host "  (install failed or skipped: $m)" }
}
Write-Host "Done. List models: curl -s http://localhost:8090/v1/models (or 8082 for audio stack)"
