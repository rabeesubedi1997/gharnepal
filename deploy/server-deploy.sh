#!/usr/bin/env bash
# Run this ON THE SERVER (cPanel SSH/Terminal) to set up or update the site.
# Safe to re-run any time — first run bootstraps folder structure and
# server state, every later run just pulls + updates.
#
# The server never builds the frontend and never runs npm — that already
# happened on your machine (deploy/build-and-push.sh) and is baked into the
# `deploy` branch this script pulls. Composer DOES run here, since it's
# available on this host.
set -euo pipefail

# --- configure these three for your host, then leave them alone ---
REPO_URL="git@github.com:rabeesubedi1997/gharnepal.git"
REPO_BRANCH="deploy"
TARGET_DIR="/home/vertexen/gharnepal.kitetool.com"
# --------------------------------------------------------------------

if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "==> First run: cloning '$REPO_BRANCH' into $TARGET_DIR"
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone --branch "$REPO_BRANCH" --single-branch "$REPO_URL" "$TARGET_DIR"
else
  echo "==> Pulling latest '$REPO_BRANCH'"
  git -C "$TARGET_DIR" pull origin "$REPO_BRANCH"
fi

cd "$TARGET_DIR"

echo "==> Ensuring folder structure (storage/, public/storage)"
mkdir -p \
  storage/app/public \
  storage/app/private \
  storage/framework/cache/data \
  storage/framework/sessions \
  storage/framework/testing \
  storage/framework/views \
  storage/logs \
  public/storage
chmod -R 775 storage bootstrap/cache

if [ ! -f .env ]; then
  echo "==> No .env yet — creating one from .env.example"
  cp .env.example .env
  echo ""
  echo "*** STOP: edit .env now with real DB / mail / app values, then"
  echo "*** re-run this script (bash deploy/server-deploy.sh) to continue."
  exit 0
fi

echo "==> composer install"
composer install --no-dev --optimize-autoloader --no-interaction

if ! grep -q '^APP_KEY=base64:' .env; then
  echo "==> Generating APP_KEY"
  php artisan key:generate --force
fi

echo "==> Migrating"
php artisan migrate --force

echo "==> Optimizing"
php artisan optimize:clear

echo ""
echo "Deploy complete. Document root for this domain should point at:"
echo "  $TARGET_DIR/public"
