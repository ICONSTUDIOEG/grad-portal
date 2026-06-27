#!/usr/bin/env bash
# Deploy grad portal static site to Hostinger VPS (compose < 8KB limit)
set -euo pipefail
cd "$(dirname "$0")"
source ./deploy.config.sh

MODE="${1:-github}"  # github | zip-url

write_compose_from_github() {
  cat > deploy-compose-mini.yml <<EOF
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
        set -e
        mkdir -p /usr/share/nginx/html/data
        wget -qO /usr/share/nginx/html/index.html "${GITHUB_RAW_BASE}/index.html"
        wget -qO /usr/share/nginx/html/dashboard.html "${GITHUB_RAW_BASE}/dashboard.html"
        wget -qO /usr/share/nginx/html/data/projects.json "${GITHUB_RAW_BASE}/data/projects.json"
        wget -qO /usr/share/nginx/html/data/tracker-cleaned.xlsx "${GITHUB_RAW_BASE}/data/tracker-cleaned.xlsx"
        exec nginx -g 'daemon off;'

networks:
  n8n_default:
    external: true
EOF
}

write_compose_from_zip() {
  local bundle_url="$1"
  cat > deploy-compose-mini.yml <<EOF
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
        apk add --no-cache wget unzip >/dev/null 2>&1 || true
        wget -qO /tmp/b.zip "$bundle_url"
        unzip -oq /tmp/b.zip -d /usr/share/nginx/html
        exec nginx -g 'daemon off;'

networks:
  n8n_default:
    external: true
EOF
}

if [[ "$MODE" == "github" ]]; then
  echo "Using GitHub raw: ${GITHUB_RAW_BASE}"
  for path in index.html dashboard.html data/projects.json data/tracker-cleaned.xlsx; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" "${GITHUB_RAW_BASE}/${path}")
  if [[ "$code" != "200" ]]; then
    echo "ERROR: GitHub file not found (${code}): ${GITHUB_RAW_BASE}/${path}" >&2
    echo "Push the repo first: ./scripts/push-github.sh" >&2
    exit 1
  fi
  done
  write_compose_from_github
elif [[ "$MODE" == "zip-url" ]]; then
  BUNDLE_URL="${2:-}"
  [[ -n "$BUNDLE_URL" ]] || { echo "Usage: $0 zip-url <bundle-url>" >&2; exit 1; }
  write_compose_from_zip "$BUNDLE_URL"
else
  echo "Usage: $0 [github|zip-url <url>]" >&2
  exit 1
fi

COMPOSE_LEN=$(wc -c < deploy-compose-mini.yml | tr -d ' ')
echo "Compose size: ${COMPOSE_LEN} bytes (limit 8192)"
if [[ "$COMPOSE_LEN" -gt 8192 ]]; then
  echo "ERROR: compose still too large" >&2
  exit 1
fi

TOKEN="$(python3 -c "import json;print(json.load(open('$HOME/.cursor/mcp.json'))['mcpServers']['hostinger-mcp']['env']['API_TOKEN'])")"
python3 << PY > /tmp/grad-deploy-body.json
import json, pathlib
payload = {
    "project_name": "grad",
    "content": pathlib.Path("deploy-compose-mini.yml").read_text(encoding="utf-8"),
}
print(json.dumps(payload))
PY

echo "Deploying to VM 1714332..."
HTTP_CODE=$(curl -sS -w "%{http_code}" -o /tmp/grad-deploy-response.json \
  -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/1714332/docker" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --data-binary @/tmp/grad-deploy-body.json)

echo "HTTP $HTTP_CODE"
cat /tmp/grad-deploy-response.json
echo
[[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]
