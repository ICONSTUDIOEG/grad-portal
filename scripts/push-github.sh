#!/usr/bin/env bash
# Initialize repo and push to GitHub (ICONSTUDIOEG/grad-portal by default)
set -euo pipefail
cd "$(dirname "$0")/.."
source ./deploy.config.sh

REPO_SLUG="${GITHUB_OWNER}/${GITHUB_REPO}"
REMOTE="https://github.com/${REPO_SLUG}.git"

if ! command -v gh >/dev/null 2>&1; then
  GH_BIN="${GH_BIN:-/tmp/gh-cli/gh_2.95.0_macOS_arm64/bin/gh}"
  if [[ -x "$GH_BIN" ]]; then
    gh() { "$GH_BIN" "$@"; }
  else
    echo "GitHub CLI (gh) is required. Install: https://cli.github.com/" >&2
    echo "Then run: gh auth login" >&2
    exit 1
  fi
fi

gh auth status >/dev/null

# Ensure git uses gh credentials in non-interactive shells
gh auth setup-git 2>/dev/null || true

if [[ ! -d .git ]]; then
  git init -b "${GITHUB_BRANCH}"
fi

git add .gitignore README.md index.html dashboard.html deploy.config.sh deploy-mini.sh deploy-direct.sh \
  generate-deploy-compose.sh redeploy.sh Dockerfile docker-compose.yml docker-compose.configs.example.yml \
  docker-compose.remote-html.yml deploy-local.sh scripts/ data/ n8n/

git diff --cached --quiet && echo "Nothing to commit." || git commit -m "$(cat <<'EOF'
Add grad portal dashboard and GitHub-based deploy

Serve static tracker dashboard and cleaned data from GitHub raw URLs for permanent VPS deploys.
EOF
)"

if ! git remote get-url origin >/dev/null 2>&1; then
  if gh repo view "${REPO_SLUG}" >/dev/null 2>&1; then
    git remote add origin "${REMOTE}"
  else
    gh repo create "${REPO_SLUG}" --public --source=. --remote=origin \
      --description "Graduation film project tracker portal — grad.iconstudio.tech"
  fi
fi

git push -u origin "${GITHUB_BRANCH}"
echo "Pushed to ${REMOTE}"
echo "Raw base: ${GITHUB_RAW_BASE}"
