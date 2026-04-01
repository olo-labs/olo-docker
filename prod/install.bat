@echo off
cd /d "%~dp0"
if not exist .env (
  echo Warning: prod\.env not found. Copy prod\.env.example to prod\.env and set POSTGRES_PASSWORD.
  exit /b 1
)
echo Using .env for prod...
echo Creating shared Docker network olo-net (if needed)...
docker network inspect olo-net >nul 2>&1
if errorlevel 1 docker network create olo-net
echo Bringing up prod stack...
docker compose up -d
echo Prod stack is up.
