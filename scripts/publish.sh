#!/usr/bin/env bash
# Linux/macOS twin of publish.ps1: builds the static site in dist/ from the local WordPress,
# and optionally deploys it to Vercel.
#
#   scripts/publish.sh            # export only; preview: node scripts/serve-dist.js (DEPLOYMENT.md)
#   scripts/publish.sh --deploy   # export, then deploy to Vercel (production)
#
# Needs docker (with the compose plugin), php with the curl extension, curl, and for --deploy
# the Vercel CLI (`npm install -g vercel`, `vercel login`, then once in this folder:
# `vercel link --yes --project jmcastillo-portfolio --scope kaizerrrs-projects`).
# .env needs STATIC_URL and WEB3FORMS_KEY, as on Windows.
set -euo pipefail
cd "$(dirname "$0")/.."

deploy=false
[[ "${1:-}" == "--deploy" ]] && deploy=true

fail() { echo "Error: $*" >&2; exit 1; }

[[ -f .env ]] || fail '.env is missing. Run scripts/setup.sh first.'
# Read one value from .env without sourcing it (values aren't shell-quoted).
env_get() { { grep -E "^$1=" .env || true; } | tail -n 1 | cut -d= -f2- | tr -d '\r' | sed 's/[[:space:]]*$//'; }
WP_URL=$(env_get WP_URL)
STATIC_URL=$(env_get STATIC_URL)
WEB3FORMS_KEY=$(env_get WEB3FORMS_KEY)

command -v docker >/dev/null || fail 'docker is not installed.'
command -v php >/dev/null || fail 'php is not installed (e.g. sudo apt install php-cli php-curl).'
php -r 'exit(function_exists("curl_init") ? 0 : 1);' || fail 'php has no curl extension (e.g. sudo apt install php-curl).'
command -v curl >/dev/null || fail 'curl is not installed.'
docker info >/dev/null 2>&1 || fail 'cannot reach Docker. Start it (sudo systemctl start docker) and make sure your user is in the docker group.'

docker compose up -d || fail 'docker compose up failed.'
# WordPress needs a moment after a cold start before the export can crawl it.
for _ in $(seq 30); do
    curl -fsS -o /dev/null --max-time 5 "$WP_URL" && break
    sleep 2
done

if $deploy; then scripts/backup.sh || fail 'nothing was deployed.'; fi

export_args=(scripts/export-static.php "--source=$WP_URL" "--form-key=$WEB3FORMS_KEY")
if [[ -n "$STATIC_URL" ]]; then
    export_args+=("--url=$STATIC_URL")
else
    echo 'STATIC_URL is not set in .env: links will be root-relative and canonical/og:url tags relative.'
fi
php "${export_args[@]}" || fail 'Static export failed; nothing was deployed.'

cp -r static/. dist/

if $deploy; then
    command -v vercel >/dev/null || fail 'the Vercel CLI is not installed (npm install -g vercel).'
    [[ -f .vercel/project.json ]] || fail 'not linked to Vercel: run `vercel link` in this folder first.'
    cp -r .vercel dist/
    vercel deploy dist --prod --yes || fail 'Vercel deploy failed.'
    printf '\n\033[32mDeployed: %s\033[0m\n' "$STATIC_URL"
fi
