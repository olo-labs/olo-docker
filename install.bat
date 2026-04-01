@echo off

rem Check that Docker is installed before proceeding
where docker >nul 2>&1
if errorlevel 1 (
  echo Docker does not appear to be installed or in your PATH.
  set /p ANSWER=Open the official Docker installation page in your browser? [Y/N]:
  if /I "%ANSWER%"=="Y" (
    start "" "https://docs.docker.com/get-docker/"
  ) else (
    echo Please install Docker from:
    echo   https://docs.docker.com/get-docker/
  )
  exit /b 1
)

set "ROOT=%~dp0"
set "FOLDER=%~1"
if "%FOLDER%"=="" set "FOLDER=dev"
if /I "%FOLDER%"=="dev" goto run
if /I "%FOLDER%"=="prod" goto run
if /I "%FOLDER%"=="demo" goto run
echo Usage: %~nx0 [dev^|prod^|demo]
echo Default: dev
exit /b 1
:run
echo Running install for: %FOLDER%
call "%ROOT%%FOLDER%\install.bat"
exit /b %ERRORLEVEL%
