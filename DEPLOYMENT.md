# Deploying to production (cPanel, via git)

The live site (`gharnepal.kitetool.com`) is a **git checkout** on the cPanel
server, on the `deploy` branch of this repo. There's no CI, no zip upload,
no scp — just two scripts:

```
YOUR MACHINE                                   SERVER
─────────────                                  ──────
deploy/build-and-push.sh
  1. npm run build (frontend)          ──git──▶  deploy/server-deploy.sh
  2. merge build + backend/ into                  1. git pull origin deploy
     one tree (vendor/storage/.env                2. composer install
     excluded — server-side state)                   (server has Composer,
  3. commit + push to `deploy` branch                no Node.js needed)
                                                   3. php artisan migrate
                                                   4. php artisan optimize:clear
```

The frontend is **only ever built on your machine**. The server never runs
`npm` — it only receives already-built files through `git pull` and installs
PHP dependencies with Composer.

Two SSH keys are involved and are **not the same key**:

- **Your own key** — to `git push` from your machine to GitHub (whatever you
  already use for this repo).
- **The server's own deploy key** — lets the *server* `git pull` this
  private repo. Set up once, below.

## One-time server setup

Run these on the cPanel server itself (SSH terminal, or cPanel's Terminal
app).

### 1. Generate a deploy key on the server

```bash
ssh-keygen -t ed25519 -C "gharnepal-server-deploy" -f ~/.ssh/id_ed25519_gharnepal -N ""
cat ~/.ssh/id_ed25519_gharnepal.pub
```

Copy the printed public key.

### 2. Add it to GitHub as a Deploy Key

On GitHub: repo → **Settings → Deploy keys → Add deploy key**. Paste the
public key. Leave **"Allow write access" unchecked** — the server only ever
pulls.

### 3. Point github.com at that key for this repo

```bash
cat >> ~/.ssh/config <<'EOF'
Host github.com
  IdentityFile ~/.ssh/id_ed25519_gharnepal
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
ssh -T git@github.com   # should greet you by the repo name
```

### 4. Get `deploy/server-deploy.sh` onto the server and run it

You need this one file before the repo even exists there. Easiest path:
open it from GitHub (raw view, on the `deploy` branch once step 5 below has
created it) and paste it into a new file on the server, or `scp` it over
once from your machine:

```bash
scp deploy/server-deploy.sh youruser@yourhost:~/server-deploy.sh
```

Then on the server:

```bash
bash ~/server-deploy.sh
```

First run clones the `deploy` branch into `TARGET_DIR` (edit the
`REPO_URL` / `TARGET_DIR` variables at the top of the script first if they
don't match your setup), creates the `storage/` folder structure, and stops
to let you fill in `.env` with real values (DB credentials, `APP_URL`,
mail, etc. — copy from `.env.example`).

Run it again after editing `.env` — it'll run `composer install`, generate
`APP_KEY`, migrate, and finish.

Point the domain's document root (cPanel → **Domains**) at:

```
<TARGET_DIR>/public
```

`config/filesystems.php`'s `public` disk already points directly at
`public/storage` (no `storage:link` symlink needed), so uploaded media just
needs that directory to exist and be writable — the script already created
it.

## Day-to-day deploys

1. On your machine: `bash deploy/build-and-push.sh`
2. On the server: `bash deploy/server-deploy.sh`

That's it — step 1 builds and pushes, step 2 pulls and finishes the job.
Since `deploy/server-deploy.sh` itself travels inside the pushed tree, the
copy already on the server is always current after step 1; you don't need
to re-copy it by hand again after the first setup.

## What never gets touched by a deploy

Excluded from the `deploy` branch entirely, so `git pull` never overwrites
or deletes them: `.env`, `vendor/`, `storage/` (logs, cache, sessions, and
`storage/app/public` — real uploaded media), `public/storage`. They're
server-only state, created once during setup and left alone by every
later pull.

One deliberate exception: `public/storage/demo/` — the ~18 stock photos
`DemoDataSeeder`/`BannerDemoDataSeeder` reference by filename. Real user
uploads live everywhere else under `public/storage/` and stay untouched;
only that one `demo/` subfolder is git-managed static content, shipped by
`build-and-push.sh` so seeded demo listings actually have images once you
run the seeder on the server.

## Seeding demo content

The seeder classes are ordinary backend code, so they're already on the
server after any deploy — seeding itself is a one-off DB operation you run
by hand on the server, not something a git pull triggers:

```bash
cd <TARGET_DIR>
php artisan db:seed
```

This runs the full `DatabaseSeeder` chain — reference data (roles,
locations, amenities), ~26 demo listings across every property
type/purpose/MVP city, agencies, neighborhoods, homepage banners, ratings,
and a default `superadmin@gharnepal.local` / `password` admin login plus a
`buyer@example.com` test buyer. Every seeder in the chain is idempotent
(safe to re-run after a later deploy without duplicating data) — see
`backend/database/seeders/DatabaseSeeder.php` for the full chain. **Change
or remove the default admin password before the site is genuinely
public-facing** — it's plain-text in the repo's history.

## Frontend / backend / mobile compatibility

No API contract changes here — this only changes *how files get onto the
server*, not what the app serves:

- The built SPA is same-origin with the API (`VITE_API_URL` is empty in
  `frontend/.env.production`, so the client calls relative `/api/v1/...`
  paths) — unaffected by this deploy mechanism.
- The Flutter app's `ApiConfig.baseUrl` is a compile-time
  `--dart-define`, pointed at `https://gharnepal.kitetool.com` when you
  build a release APK — also unaffected.
