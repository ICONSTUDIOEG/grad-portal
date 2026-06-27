#!/bin/bash
# Deploy on VPS when index.html sits beside docker-compose.yml (SSH / manual copy)
set -euo pipefail
cd "$(dirname "$0")"
docker compose -f docker-compose.yml up -d --force-recreate
echo "Deployed. Site: https://grad.iconstudio.tech"
