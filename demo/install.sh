#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
echo "Creating shared Docker network olo-net (if needed)..."
docker network inspect olo-net >/dev/null 2>&1 || docker network create olo-net
echo "Bringing up demo stack..."
docker compose up -d
echo "Demo stack is up."
