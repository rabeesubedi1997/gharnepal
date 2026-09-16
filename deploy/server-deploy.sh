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

# --- Resolve a real CLI PHP binary -----------------------------------------
# Some hosts put a CGI/FastCGI `php` on PATH (this one did) — running
# composer/artisan through it doesn't fail loudly, it just silently ignores
# every argument and prints the tool's own help/command-list instead of
# doing anything. Composer does print one warning line about it ("should be
# invoked via the CLI version of PHP, not the cgi-fcgi SAPI"), but it's easy
# to miss buried in output — that's exactly what happened here once
# already: composer install, migrate, and optimize:clear all silently
# no-op'd on a real deploy. Prefer plain `php` only once confirmed to
# genuinely be the CLI SAPI; otherwise search cPanel's per-version EA4 CLI
# binaries, newest first (composer.json requires "php": "^8.2").
resolve_php_cli() {
  if command -v php >/dev/null 2>&1 && php -r 'exit(PHP_SAPI === "cli" ? 0 : 1);' 2>/dev/null; then
    command -v php
    return
  fi

  local candidate
  for candidate in \
    /opt/cpanel/ea-php84/root/usr/bin/php \
    /opt/cpanel/ea-php83/root/usr/bin/php \
    /opt/cpanel/ea-php82/root/usr/bin/php \
    /usr/local/bin/ea-php84 \
    /usr/local/bin/ea-php83 \
    /usr/local/bin/ea-php82 \
  ; do
    if [ -x "$candidate" ] && "$candidate" -r 'exit(PHP_SAPI === "cli" ? 0 : 1);' 2>/dev/null; then
      echo "$candidate"
      return
    fi
  done

  echo "!!! No CLI PHP binary found — only a CGI/FastCGI 'php' is on PATH, and" >&2
  echo "!!! none of the usual cPanel EA4 CLI paths exist or work on this host." >&2
  echo "!!! Find this host's real CLI binary (check 'php -v' for a version" >&2
  echo "!!! hint, or WHM > MultiPHP Manager) and add its path to the list" >&2
  echo "!!! above in resolve_php_cli()." >&2
  return 1
}

PHP_BIN="$(resolve_php_cli)"
echo "==> Using CLI PHP: $PHP_BIN ($("$PHP_BIN" -r 'echo PHP_VERSION;'))"

COMPOSER_PHAR="$(command -v composer)"
# Every bare `php`/`composer` call below this point now runs through the
# resolved CLI binary instead of whatever (possibly CGI) one is on PATH.
php() { "$PHP_BIN" "$@"; }
composer() { "$PHP_BIN" "$COMPOSER_PHAR" "$@"; }

if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "==> First run: cloning '$REPO_BRANCH' into $TARGET_DIR"
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone --branch "$REPO_BRANCH" --single-branch "$REPO_URL" "$TARGET_DIR"
else
  echo "==> Pulling latest '$REPO_BRANCH'"
  git -C "$TARGET_DIR" pull origin "$REPO_BRANCH"
fi

cd "$TARGET_DIR"

# The pull above may have just rewritten THIS VERY FILE (this script lives
# in the repo it pulls). Bash keeps running the version it already read
# into memory when it started, not whatever's on disk now — so every step
# after this point would silently run stale, pre-update code for the rest
# of this invocation (exactly how a real fix here once landed on disk via
# the pull but never actually took effect until the next separate run).
# Re-exec fresh so the rest of this run always matches what's really on
# disk, and this class of problem can't recur on any future edit to this
# script either.
if [ -z "${SERVER_DEPLOY_REEXECED:-}" ]; then
  export SERVER_DEPLOY_REEXECED=1
  exec bash "$TARGET_DIR/deploy/server-deploy.sh" "$@"
fi

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

echo "==> Ensuring VAPID keys exist (web push — no Firebase/Google account needed)"
if ! grep -q '^VAPID_PUBLIC_KEY=.\+' .env 2>/dev/null; then
  echo "    No VAPID_PUBLIC_KEY set yet — generating a fresh keypair"
  VAPID_OUT="$(php artisan tinker --execute='
    $k = Minishlink\WebPush\VAPID::createVapidKeys();
    echo "VAPID_PUBLIC_KEY=".$k["publicKey"]."\nVAPID_PRIVATE_KEY=".$k["privateKey"];
  ' 2>&1)" || true
  if echo "$VAPID_OUT" | grep -q '^VAPID_PUBLIC_KEY='; then
    # Drop any existing (empty) VAPID_* lines from .env.example's copy, then
    # append the real generated pair.
    grep -v '^VAPID_PUBLIC_KEY=\|^VAPID_PRIVATE_KEY=' .env > .env.tmp
    mv .env.tmp .env
    echo "$VAPID_OUT" | grep '^VAPID_PUBLIC_KEY=\|^VAPID_PRIVATE_KEY=' >> .env
    echo "    Generated and saved to .env — web push is now live"
  else
    echo "    WARNING: couldn't auto-generate a VAPID keypair (this host's PHP"
    echo "    OpenSSL may not support EC keys — a known issue on some Windows"
    echo "    PHP builds, less common on Linux). Web push stays disabled until"
    echo "    you add VAPID_PUBLIC_KEY/VAPID_PRIVATE_KEY to .env by hand — see"
    echo "    DEPLOYMENT.md for the 'npx web-push generate-vapid-keys' fallback."
    echo "    (tinker output: $VAPID_OUT)"
  fi
else
  echo "    Already set"
fi

echo "==> Migrating"
php artisan migrate --force

echo "==> Optimizing"
php artisan optimize:clear

echo "==> Ensuring cron runs the scheduler (saved-search email digests)"
# Cron runs with its own minimal environment — it won't have this script's
# `php()` function, and its own PATH may not even resolve `php` at all — so
# this needs the resolved CLI binary's absolute path spelled out directly.
CRON_CMD="cd $TARGET_DIR && $PHP_BIN artisan schedule:run >> /dev/null 2>&1"
if command -v crontab >/dev/null 2>&1; then
  if crontab -l 2>/dev/null | grep -qF "$CRON_CMD"; then
    echo "    Already scheduled"
  else
    # Drop any prior entry for this project's scheduler first — an earlier
    # deploy may have added one built from a bare (possibly wrong-SAPI)
    # `php`, and leaving both in place means the scheduler fires twice a
    # minute, which for a daily/weekly digest command means duplicate
    # emails once its actual scheduled minute comes around.
    { crontab -l 2>/dev/null | grep -vF "cd $TARGET_DIR && " || true; echo "* * * * * $CRON_CMD"; } | crontab -
    echo "    Added: * * * * * $CRON_CMD"
  fi
else
  echo "    WARNING: no 'crontab' command on this host — add this manually via"
  echo "    cPanel's Cron Jobs UI, or daily/weekly saved-search alerts will"
  echo "    silently never send (instant alerts are unaffected):"
  echo "    * * * * * $CRON_CMD"
fi

echo ""
echo "Deploy complete. Document root for this domain should point at:"
echo "  $TARGET_DIR/public"
