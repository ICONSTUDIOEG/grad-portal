#!/usr/bin/env bash
set -euo pipefail
GH=/tmp/gh-cli/gh_2.95.0_macOS_arm64/bin/gh
cd /Users/ai-unit/Projects/grad-portal

if $GH auth status >/dev/null 2>&1; then
  echo "Already authenticated."
else
  echo "Starting GitHub device login..."
  open "https://github.com/login/device" 2>/dev/null || true
  ($GH auth login -h github.com -p https -w </dev/null & echo $! > /tmp/gh-auth.pid)
  sleep 3
  head -5 /tmp/gh-auth-login.txt 2>/dev/null || true
  echo "Waiting for browser authorization (up to 5 min)..."
  for i in $(seq 1 60); do
    if $GH auth status >/dev/null 2>&1; then
      echo "GitHub login OK."
      break
    fi
    sleep 5
  done
  $GH auth status
fi

./scripts/push-github.sh
./deploy-mini.sh
