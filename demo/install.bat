@echo off
cd /d "%~dp0"
echo Creating shared Docker network olo-net (if needed)...
docker network inspect olo-net >nul 2>&1
if errorlevel 1 docker network create olo-net
echo Bringing up demo stack...
docker compose up -d
echo Demo stack is up.
