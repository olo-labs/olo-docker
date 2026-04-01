#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
if [ -f .env ]; then
  echo "Using .env for prod..."
else
  echo "Warning: prod/.env not found. Copy prod/.env.example to prod/.env and set POSTGRES_PASSWORD."
  exit 1
fi
echo "Creating shared Docker network olo-net (if needed)..."
docker network inspect olo-net >/dev/null 2>&1 || docker network create olo-net
echo "Bringing up prod stack..."
docker compose up -d
echo "Prod stack is up."
