#!/usr/bin/env bash
set -e

# Check that Docker is installed before proceeding
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker does not appear to be installed or is not in your PATH."
  read -r -p "Open the official Docker installation page in your browser? [y/N]: " answer
  case "$answer" in
    [Yy]*)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "https://docs.docker.com/get-docker/"
      elif command -v open >/dev/null 2>&1; then
        open "https://docs.docker.com/get-docker/"
      else
        echo "Please visit this URL to install Docker:"
        echo "  https://docs.docker.com/get-docker/"
      fi
      ;;
    *)
      echo "Aborting. Please install Docker and re-run this script."
      ;;
  esac
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
FOLDER="${1:-dev}"
case "$FOLDER" in
  dev|prod|demo) ;;
  *)
    echo "Usage: $0 [dev|prod|demo]"
    echo "Default: dev"
    exit 1
    ;;
esac
echo "Running install for: $FOLDER"
exec "$ROOT/$FOLDER/install.sh"
