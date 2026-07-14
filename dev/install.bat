@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ============================================================
rem OLO Development Stack Installer
rem ============================================================

echo.
echo ============================================================
echo OLO Development Stack Installer
echo ============================================================
echo Working directory : %CD%
echo Started at        : %DATE% %TIME%
echo ============================================================
echo.

rem ============================================================
rem STEP 1 - Verify Docker
rem ============================================================

echo [STEP 1] Checking Docker availability...

docker version >nul 2>&1

if errorlevel 1 (
    echo.
    echo [ERROR] Docker is not available.
    echo.
    echo Probable causes:
    echo   - Docker Desktop is not running.
    echo   - Docker CLI is not installed.
    echo   - Docker CLI is not available in PATH.
    echo   - Docker Engine failed to start.
    echo.
    echo Try running:
    echo   docker version
    echo.
    exit /b 1
)

echo [OK] Docker is available.
echo.


rem ============================================================
rem STEP 2 - Create shared Docker network
rem ============================================================

echo [STEP 2] Checking Docker network: olo-net

docker network inspect olo-net >nul 2>&1

if errorlevel 1 (
    echo [INFO] Network olo-net does not exist.
    echo [INFO] Creating network olo-net...

    docker network create olo-net

    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to create Docker network olo-net.
        echo.
        echo Probable causes:
        echo   - Docker Engine is unavailable.
        echo   - Docker daemon permission problem.
        echo   - Docker network configuration problem.
        echo.
        exit /b 1
    )

    echo [OK] Network olo-net created.
) else (
    echo [OK] Network olo-net already exists.
)

echo.


rem ============================================================
rem STEP 3 - Pull latest OLO images
rem ============================================================

echo [STEP 3] Pulling latest OLO images...
echo.

call :PullImage "ololab/olo:latest"
if errorlevel 1 exit /b 1

rem Uncomment when olo-worker image is enabled
rem call :PullImage "ololab/olo-worker:latest"
rem if errorlevel 1 exit /b 1

call :PullImage "ololab/olo-ui:latest"
if errorlevel 1 exit /b 1

call :PullImage "ololab/olo-chat:latest"
if errorlevel 1 exit /b 1

echo.
echo [OK] OLO images pulled successfully.
echo.


rem ============================================================
rem STEP 4 - Select AI containers
rem ============================================================

echo [STEP 4] Select AI containers to deploy
echo.

set "DEPLOY_TEXT=1"
echo [INFO] Text AI is always enabled.

set "DEPLOY_SPEECH=0"
set "ANS="
set /p "ANS=Deploy speech/audio AI? [y/N]: "
if /I "!ANS!"=="Y" set "DEPLOY_SPEECH=1"

set "DEPLOY_IMAGE=0"
set "ANS="
set /p "ANS=Deploy image AI? [y/N]: "
if /I "!ANS!"=="Y" set "DEPLOY_IMAGE=1"

set "DEPLOY_VIDEO=0"
set "ANS="
set /p "ANS=Deploy video AI? [y/N]: "
if /I "!ANS!"=="Y" set "DEPLOY_VIDEO=1"

echo.
echo AI Selection:
echo   Text   : !DEPLOY_TEXT!
echo   Speech : !DEPLOY_SPEECH!
echo   Image  : !DEPLOY_IMAGE!
echo   Video  : !DEPLOY_VIDEO!
echo.


rem ============================================================
rem STEP 5 - Build Docker Compose configuration
rem ============================================================

echo [STEP 5] Building Docker Compose configuration...

set "COMPOSE_FILES=-f docker-compose-db.yml -f docker-compose-cache.yml -f docker-compose-ElasticSearch.yml -f docker-compose-vectordb.yml -f docker-compose-temporal.yml -f docker-compose-olo.yml"

set "AI_SELECTED="

if "!DEPLOY_TEXT!"=="1" (
    set "COMPOSE_FILES=!COMPOSE_FILES! -f docker-compose-ai-text.yml"
    set "AI_SELECTED=!AI_SELECTED! text"
)

if "!DEPLOY_SPEECH!"=="1" (
    set "COMPOSE_FILES=!COMPOSE_FILES! -f docker-compose-ai-audio.yml"
    set "AI_SELECTED=!AI_SELECTED! speech"
)

if "!DEPLOY_IMAGE!"=="1" (
    set "COMPOSE_FILES=!COMPOSE_FILES! -f docker-compose-ai-image.yml"
    set "AI_SELECTED=!AI_SELECTED! image"
)

if "!DEPLOY_VIDEO!"=="1" (
    set "COMPOSE_FILES=!COMPOSE_FILES! -f docker-compose-ai-video.yml"
    set "AI_SELECTED=!AI_SELECTED! video"
)

echo [INFO] Core containers:
echo        db, cache, elastic, vectordb, temporal, olo

echo [INFO] AI containers:
echo       !AI_SELECTED!

echo.


rem ============================================================
rem STEP 6 - Validate Docker Compose configuration
rem ============================================================

echo [STEP 6] Validating Docker Compose configuration...

docker compose -p olo !COMPOSE_FILES! config --quiet

if errorlevel 1 (
    echo.
    echo [ERROR] Docker Compose configuration validation failed.
    echo.
    echo Probable causes:
    echo   - A docker-compose YAML file is missing.
    echo   - YAML syntax error.
    echo   - Invalid environment variable.
    echo   - Invalid volume or network configuration.
    echo.
    echo Running full validation output:
    echo.
    docker compose -p olo !COMPOSE_FILES! config
    echo.
    exit /b 1
)

echo [OK] Docker Compose configuration is valid.
echo.


rem ============================================================
rem STEP 7 - Start OLO stack
rem ============================================================

echo [STEP 7] Starting OLO development stack...
echo.

docker compose -p olo !COMPOSE_FILES! up -d

if errorlevel 1 (
    echo.
    echo [ERROR] Docker Compose failed to start the OLO stack.
    echo.
    echo Probable causes:
    echo   - Container failed to start.
    echo   - Port already in use.
    echo   - Docker volume problem.
    echo   - Docker network problem.
    echo   - Insufficient memory or disk space.
    echo   - Image startup failure.
    echo.
    echo Current container status:
    echo.
    docker compose -p olo !COMPOSE_FILES! ps
    echo.
    echo Recent container events:
    echo.
    docker compose -p olo !COMPOSE_FILES! logs --tail 50
    echo.
    exit /b 1
)

echo.
echo [OK] Docker Compose command completed.
echo.


rem ============================================================
rem STEP 8 - Display container status
rem ============================================================

echo [STEP 8] Checking container status...
echo.

docker compose -p olo !COMPOSE_FILES! ps

echo.


rem ============================================================
rem STEP 9 - Wait for Ollama API
rem ============================================================

echo [STEP 9] Waiting for Ollama API...
echo [INFO] Expected Ollama endpoint:
echo        http://localhost:11435/api/tags
echo.

set "OLLAMA_READY=0"
set "OLLAMA_MAX_RETRIES=30"
set /a OLLAMA_RETRY=0

:WAIT_FOR_OLLAMA

set /a OLLAMA_RETRY+=1

echo [INFO] Ollama health check !OLLAMA_RETRY!/!OLLAMA_MAX_RETRIES!...

powershell -NoProfile -Command ^
  "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:11435/api/tags' -TimeoutSec 5; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

if not errorlevel 1 (
    set "OLLAMA_READY=1"
    goto OLLAMA_IS_READY
)

if !OLLAMA_RETRY! GEQ !OLLAMA_MAX_RETRIES! (
    goto OLLAMA_NOT_READY
)

echo [WAIT] Ollama API is not ready. Retrying in 5 seconds...
timeout /t 5 /nobreak >nul

goto WAIT_FOR_OLLAMA


:OLLAMA_NOT_READY

echo.
echo [ERROR] Ollama API did not become ready.
echo.
echo Probable causes:
echo   - olo-ollama container failed.
echo   - Ollama is still starting.
echo   - Port 11435 is not exposed.
echo   - docker-compose-ai-text.yml has incorrect port mapping.
echo   - Ollama process crashed inside the container.
echo.
echo Ollama container status:
echo.

docker ps -a --filter "name=olo-ollama"

echo.
echo Recent Ollama logs:
echo.

docker logs --tail 100 olo-ollama

echo.
echo Installation cannot continue because models cannot be pulled.
echo.

exit /b 1


:OLLAMA_IS_READY

echo.
echo [OK] Ollama API is ready.
echo.


rem ============================================================
rem STEP 10 - Display currently installed Ollama models
rem ============================================================

echo [STEP 10] Checking currently installed Ollama models...
echo.

powershell -NoProfile -Command ^
  "try { $r = Invoke-RestMethod -Uri 'http://localhost:11435/api/tags' -TimeoutSec 10; if ($r.models.Count -eq 0) { Write-Host '[INFO] No Ollama models are currently installed.' } else { Write-Host '[INFO] Installed Ollama models:'; $r.models | ForEach-Object { Write-Host ('       - ' + $_.name) } }; exit 0 } catch { Write-Host '[WARNING] Unable to retrieve Ollama model list.'; Write-Host $_.Exception.Message; exit 1 }"

echo.


rem ============================================================
rem STEP 11 - Pull Ollama models
rem ============================================================

echo [STEP 11] Installing Ollama models...

set "OLLAMA_SCRIPT=%~dp0scripts\ollama-pull-models.ps1"

echo [INFO] Ollama model script:
echo        !OLLAMA_SCRIPT!
echo.

if not exist "!OLLAMA_SCRIPT!" (
    echo [ERROR] Ollama model installation script does not exist.
    echo.
    echo Expected file:
    echo   !OLLAMA_SCRIPT!
    echo.
    echo Probable causes:
    echo   - scripts directory is missing.
    echo   - ollama-pull-models.ps1 was not included.
    echo   - Incorrect repository checkout.
    echo.
    exit /b 1
)

echo [INFO] Starting Ollama model installation script...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "!OLLAMA_SCRIPT!"

set "OLLAMA_SCRIPT_EXIT=!ERRORLEVEL!"

echo.
echo [INFO] Ollama model script exit code: !OLLAMA_SCRIPT_EXIT!

if not "!OLLAMA_SCRIPT_EXIT!"=="0" (
    echo.
    echo [ERROR] Ollama model installation failed.
    echo.
    echo Probable causes:
    echo   - Ollama API became unavailable.
    echo   - Model download failed.
    echo   - Internet connection problem.
    echo   - Insufficient disk space.
    echo   - Invalid model name.
    echo   - PowerShell script terminated with an error.
    echo.
    echo Current Ollama container status:
    echo.

    docker ps -a --filter "name=olo-ollama"

    echo.
    echo Recent Ollama logs:
    echo.

    docker logs --tail 100 olo-ollama

    echo.
    exit /b 1
)

echo.
echo [OK] Ollama models installed successfully.
echo.


rem ============================================================
rem STEP 12 - Verify installed Ollama models
rem ============================================================

echo [STEP 12] Verifying installed Ollama models...
echo.

powershell -NoProfile -Command ^
  "try { $r = Invoke-RestMethod -Uri 'http://localhost:11435/api/tags' -TimeoutSec 10; if ($r.models.Count -eq 0) { Write-Host '[WARNING] Ollama API is available but no models are installed.'; exit 1 } else { Write-Host '[OK] Installed Ollama models:'; $r.models | ForEach-Object { Write-Host ('     - ' + $_.name) }; exit 0 } } catch { Write-Host '[ERROR] Failed to verify Ollama models.'; Write-Host $_.Exception.Message; exit 1 }"

if errorlevel 1 (
    echo.
    echo [ERROR] Ollama model verification failed.
    echo.
    echo Check:
    echo   http://localhost:11435/api/tags
    echo.
    exit /b 1
)

echo.


rem ============================================================
rem STEP 13 - Install LocalAI models
rem ============================================================

echo [STEP 13] Installing LocalAI models...

set "LOCALAI_SCRIPT=%~dp0scripts\openai-oss-pull-models.ps1"

echo [INFO] LocalAI model script:
echo        !LOCALAI_SCRIPT!
echo.

if not exist "!LOCALAI_SCRIPT!" (
    echo [ERROR] LocalAI model installation script does not exist.
    echo.
    echo Expected file:
    echo   !LOCALAI_SCRIPT!
    echo.
    exit /b 1
)

echo [INFO] Starting LocalAI model installation script...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "!LOCALAI_SCRIPT!"

set "LOCALAI_SCRIPT_EXIT=!ERRORLEVEL!"

echo.
echo [INFO] LocalAI model script exit code: !LOCALAI_SCRIPT_EXIT!

if not "!LOCALAI_SCRIPT_EXIT!"=="0" (
    echo.
    echo [ERROR] LocalAI model installation failed.
    echo.
    echo Probable causes:
    echo   - LocalAI container is not ready.
    echo   - Model download failed.
    echo   - Internet connection problem.
    echo   - Insufficient disk space.
    echo   - PowerShell script failed.
    echo.
    echo LocalAI container status:
    echo.

    docker ps -a --filter "name=olo-openai-oss"

    echo.
    echo Recent LocalAI logs:
    echo.

    docker logs --tail 100 olo-openai-oss

    echo.
    exit /b 1
)

echo.
echo [OK] LocalAI models installed successfully.
echo.


rem ============================================================
rem STEP 14 - Final container status
rem ============================================================

echo [STEP 14] Final container status...
echo.

docker compose -p olo !COMPOSE_FILES! ps

echo.


rem ============================================================
rem INSTALLATION COMPLETE
rem ============================================================

echo ============================================================
echo OLO INSTALLATION COMPLETED SUCCESSFULLY
echo ============================================================
echo.
echo Installed components:
echo   - OLO Core
echo   - OLO UI
echo   - OLO Chat
echo   - PostgreSQL
echo   - Redis
echo   - Elasticsearch
echo   - Qdrant
echo   - Temporal
echo   - Ollama
echo   - LocalAI
echo.
echo AI containers:
echo  !AI_SELECTED!
echo.
echo Ollama API:
echo   http://localhost:11435/api/tags
echo.
echo Completed at:
echo   %DATE% %TIME%
echo.
echo ============================================================

exit /b 0


rem ============================================================
rem FUNCTIONS
rem ============================================================

:PullImage

set "IMAGE_NAME=%~1"

echo ------------------------------------------------------------
echo [INFO] Pulling image: !IMAGE_NAME!
echo ------------------------------------------------------------

docker pull !IMAGE_NAME!

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to pull Docker image:
    echo         !IMAGE_NAME!
    echo.
    echo Probable causes:
    echo   - Internet connection problem.
    echo   - Docker Hub is unavailable.
    echo   - Image name or tag is incorrect.
    echo   - Docker Hub rate limit.
    echo   - Authentication problem.
    echo.
    exit /b 1
)

echo [OK] Image pulled: !IMAGE_NAME!
echo.

exit /b 0

