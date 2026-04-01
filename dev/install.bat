@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo Creating shared Docker network: olo-net (if needed)...
docker network inspect olo-net >nul 2>&1
if errorlevel 1 (
  docker network create olo-net
)

echo Pulling latest OLO images (olo, olo-worker, olo-ui, olo-chat)...
docker pull openllmorchestrator/olo:latest
docker pull openllmorchestrator/olo-worker:latest
docker pull openllmorchestrator/olo-ui:latest
docker pull openllmorchestrator/olo-chat:latest

echo.
echo Select AI containers to deploy (you can pick one or more):
set "DEPLOY_TEXT=1"
echo Text AI is always enabled.

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

echo Bringing up OLO dev stack (project: olo)...
echo Core containers: db, cache, elastic, vectordb, temporal, olo
echo AI containers:!AI_SELECTED!

docker compose -p olo !COMPOSE_FILES! up -d
if errorlevel 1 (
  echo Docker compose failed. Stack is not fully up.
  exit /b 1
)

echo Dev OLO stack is up (project: olo).

if "!DEPLOY_TEXT!!DEPLOY_SPEECH!"=="00" (
  echo Skipping Ollama/LocalAI model setup ^(text/speech AI not selected^).
) else (
  echo Waiting for Ollama, then pulling models ^(llama3.2, mistral, phi3, etc.^)...
  timeout /t 5 /nobreak >nul
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ollama-pull-models.ps1"

  echo Waiting for LocalAI ^(openai-oss^), then installing models...
  timeout /t 5 /nobreak >nul
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\openai-oss-pull-models.ps1"
)

echo Done.
