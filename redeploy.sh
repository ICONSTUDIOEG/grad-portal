#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
TOKEN="$(python3 -c "import json;print(json.load(open('$HOME/.cursor/mcp.json'))['mcpServers']['hostinger-mcp']['env']['API_TOKEN'])")"
./generate-deploy-compose.sh >/dev/null
python3 << 'PY'
import json, pathlib
payload = {
    "virtualMachineId": 1714332,
    "project_name": "grad",
    "content": pathlib.Path("deploy-compose.yml").read_text(encoding="utf-8"),
}
pathlib.Path(".mcp-stdout-args.json").write_text(json.dumps(payload), encoding="utf-8")
print(len(payload["content"]))
PY
node .mcp-bridge.js .mcp-stdout-args.json "$TOKEN"
