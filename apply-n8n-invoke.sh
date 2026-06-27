#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
node .n8n-update-call.js
