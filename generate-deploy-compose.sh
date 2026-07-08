#!/usr/bin/env bash
# Generates deploy-compose.yml with static assets embedded as base64 for Hostinger VPS deploy
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

b64() { base64 < "$1" | tr -d '\n'; }

B64_INDEX="$(b64 "$DIR/index.html")"
B64_DASH="$(b64 "$DIR/dashboard.html")"
B64_PRES="$(b64 "$DIR/presentation.html")"
B64_BAL="$(b64 "$DIR/balance-simulation.html")"
B64_JSON="$(b64 "$DIR/data/projects.json")"
B64_XLSX="$(b64 "$DIR/data/tracker-cleaned.xlsx")"

cat > "$DIR/deploy-compose.yml" <<EOF
services:
  web:
    image: nginx:alpine
    restart: always
    networks:
      - n8n_default
    labels:
      - traefik.enable=true
      - traefik.docker.network=n8n_default
      - "traefik.http.routers.grad.rule=Host(\`grad.iconstudio.tech\`)"
      - traefik.http.routers.grad.entrypoints=web,websecure
      - traefik.http.routers.grad.tls=true
      - traefik.http.routers.grad.tls.certresolver=mytlschallenge
      - traefik.http.services.grad.loadbalancer.server.port=80
    command:
      - sh
      - -c
      - |
        mkdir -p /usr/share/nginx/html/data
        echo "$B64_INDEX" | base64 -d > /usr/share/nginx/html/index.html
        echo "$B64_DASH" | base64 -d > /usr/share/nginx/html/dashboard.html
        echo "$B64_PRES" | base64 -d > /usr/share/nginx/html/presentation.html
        echo "$B64_BAL" | base64 -d > /usr/share/nginx/html/balance-simulation.html
        echo "$B64_JSON" | base64 -d > /usr/share/nginx/html/data/projects.json
        echo "$B64_XLSX" | base64 -d > /usr/share/nginx/html/data/tracker-cleaned.xlsx
        exec nginx -g 'daemon off;'

networks:
  n8n_default:
    external: true
EOF

echo "Wrote $DIR/deploy-compose.yml ($(wc -c < "$DIR/deploy-compose.yml") bytes)"
