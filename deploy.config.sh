# GitHub raw hosting for grad.iconstudio.tech deploys
# After pushing this repo, redeploy with: ./deploy-mini.sh
export GITHUB_OWNER="${GITHUB_OWNER:-ICONSTUDIOEG}"
export GITHUB_REPO="${GITHUB_REPO:-grad-portal}"
export GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
export GITHUB_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
