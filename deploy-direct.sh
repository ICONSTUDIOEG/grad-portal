#!/usr/bin/env bash
# Deploy grad portal via Hostinger REST API (bypasses MCP stdio timeout)
set -euo pipefail
cd "$(dirname "$0")"

./generate-deploy-compose.sh >/dev/null

TOKEN="$(python3 -c "import json;print(json.load(open('$HOME/.cursor/mcp.json'))['mcpServers']['hostinger-mcp']['env']['API_TOKEN'])")"
VMID=1714332
PROJECT=grad

python3 << PY > /tmp/grad-deploy-body.json
import json, pathlib
payload = {
    "project_name": "$PROJECT",
    "content": pathlib.Path("deploy-compose.yml").read_text(encoding="utf-8"),
}
print(json.dumps(payload))
PY

echo "Deploying $PROJECT to VM $VMID ($(wc -c < deploy-compose.yml) bytes compose)..."

HTTP_CODE=$(curl -sS -w "%{http_code}" -o /tmp/grad-deploy-response.json \
  -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/${VMID}/docker" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --data-binary @/tmp/grad-deploy-body.json)

echo "HTTP $HTTP_CODE"
cat /tmp/grad-deploy-response.json
echo

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  echo "Deploy request accepted."
  exit 0
fi
exit 1
