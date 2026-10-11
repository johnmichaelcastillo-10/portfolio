#!/usr/bin/env bash
# Linux/macOS twin of backup.ps1: saves the WordPress database and uploads into
# backups/auto-<date-time>/ and keeps the newest $KEEP (default 10) automatic backups.
# publish.sh --deploy runs this first; run it on its own any time: scripts/backup.sh
# backups/ is gitignored. Copy it to a private cloud drive yourself (the dump holds the
# contact messages and the admin password hash). Restore steps are in DEPLOYMENT.md.
set -euo pipefail
cd "$(dirname "$0")/.."

KEEP=${KEEP:-10}
dir="backups/auto-$(date +%Y-%m-%d_%H%M%S)"
# A half-written backup must not be mistaken for a good one (or count towards KEEP).
fail() { rm -rf "$dir"; echo "Backup failed: $*" >&2; exit 1; }
env_get() { { grep -E "^$1=" .env || true; } | tail -n 1 | cut -d= -f2- | tr -d '\r' | sed 's/[[:space:]]*$//'; }

mkdir -p "$dir"

docker compose exec -T -e "MYSQL_PWD=$(env_get DB_ROOT_PASSWORD)" db sh -c \
    "mariadb-dump -u root --single-transaction --databases $(env_get DB_NAME) > /tmp/jmc-backup.sql" \
    || fail 'could not dump the database.'
docker compose cp db:/tmp/jmc-backup.sql "$dir/wordpress.sql" >/dev/null 2>&1 \
    || fail 'could not copy the database dump out of the container.'
docker compose exec -T db rm -f /tmp/jmc-backup.sql
grep -q 'CREATE TABLE' "$dir/wordpress.sql" || fail 'the database dump has no tables in it.'

if docker compose exec -T wordpress test -d /var/www/html/wp-content/uploads; then
    docker compose cp wordpress:/var/www/html/wp-content/uploads "$dir/uploads" >/dev/null 2>&1 \
        || fail 'could not copy the uploads folder.'
fi

# Prune old automatic backups (names sort by date); other backups are never touched.
ls -1d backups/auto-* 2>/dev/null | sort -r | tail -n +$((KEEP + 1)) | while read -r old; do rm -rf "$old"; done

echo "Backup saved: $dir ($(du -sh "$dir" | cut -f1))"
