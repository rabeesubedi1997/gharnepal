#!/usr/bin/env bash
# Run this LOCALLY (Git Bash) whenever you want to ship a new version.
#
# It builds the React frontend right here on your machine, merges it with
# the Laravel backend into one ready-to-serve tree, and pushes that tree as
# a single commit on the `deploy` branch. The server never builds anything
# — it only ever runs `git pull` (see server-deploy.sh) and adds the files
# that commit contains.
#
# Nothing here touches `main` — your normal source history stays clean of
# build artifacts. `deploy` is a generated, force-committed-on-top branch;
# don't hand-edit files on it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BRANCH="deploy"
SITEROOT="$REPO_ROOT/deploy/siteroot"

echo "==> Building frontend"
(cd frontend && npm run build)

echo "==> Preparing '$BRANCH' branch checkout"
rm -rf "$SITEROOT"
REMOTE_URL="$(git remote get-url origin)"
if git clone --quiet --branch "$BRANCH" --single-branch "$REMOTE_URL" "$SITEROOT" 2>/dev/null; then
  echo "    ($BRANCH branch already exists)"
else
  git clone --quiet "$REMOTE_URL" "$SITEROOT"
  (cd "$SITEROOT" && git checkout --quiet --orphan "$BRANCH" && git rm -rf --quiet . >/dev/null)
  echo "    (created $BRANCH branch)"
fi

echo "==> Syncing backend/ into the checkout"
# Clear out everything except .git, then copy a fresh backend/ over it.
find "$SITEROOT" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -r backend/. "$SITEROOT/"
# These are server-side state or dev-only — never shipped via git.
rm -rf "$SITEROOT/vendor" "$SITEROOT/storage" "$SITEROOT/tests" "$SITEROOT/node_modules"
rm -f "$SITEROOT/.env" "$SITEROOT/.env.example" "$SITEROOT/.env.production" "$SITEROOT/phpunit.xml"

echo "==> Merging built SPA into public/"
rm -rf "$SITEROOT/public/storage"
cp -r frontend/dist/. "$SITEROOT/public/"

echo "==> Copying server deploy script along for the ride"
mkdir -p "$SITEROOT/deploy"
cp deploy/server-deploy.sh "$SITEROOT/deploy/server-deploy.sh"

cat > "$SITEROOT/.gitignore" <<'EOF'
# Server-side state that composer/artisan create at runtime — never
# tracked on the deploy branch, so `git pull`/`git reset` never touches it.
/vendor
/.env
/.env.production
/storage
/public/storage
/public/hot
/bootstrap/cache/*.php
EOF

echo "==> Committing and pushing"
cd "$SITEROOT"
git add -A
git -c user.name="deploy-script" -c user.email="deploy@localhost" \
  commit --quiet -m "Deploy build $(date -u +%Y-%m-%dT%H:%M:%SZ)" --allow-empty
git push --quiet origin "$BRANCH"
cd "$REPO_ROOT"
rm -rf "$SITEROOT"

echo ""
echo "Pushed to '$BRANCH'. Now on the server, run:"
echo "  bash deploy/server-deploy.sh"
