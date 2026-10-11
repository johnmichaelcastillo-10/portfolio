#Requires -Version 5.1
# Saves the WordPress database and uploads into backups\auto-<date-time>\ and keeps the newest
# -Keep automatic backups (older auto-* folders are deleted; other backups are never touched).
# publish.ps1 -Deploy runs this first, so every deploy has a backup. Run it on its own any time:
#
#   .\scripts\backup.ps1
#
# backups\ is gitignored. Copy it to a private cloud drive yourself: the dump holds the contact
# messages and the admin password hash. Restore steps are in DEPLOYMENT.md.
param([int]$Keep = 10)

# Not 'Stop': in PowerShell 5.1 that turns native stderr output into errors.
$ErrorActionPreference = 'Continue'
Set-Location (Split-Path $PSScriptRoot -Parent)

$cfg = @{}
foreach ($line in Get-Content .env) {
    if ($line -match '^([A-Z0-9_]+)=(.*)$') { $cfg[$Matches[1]] = $Matches[2].Trim() }
}

$dir = "backups\auto-$(Get-Date -Format 'yyyy-MM-dd_HHmmss')"
New-Item -ItemType Directory -Force $dir | Out-Null

try {
    # Dump inside the container and copy the file out: piping through PowerShell 5.1 re-encodes it.
    docker compose exec -T -e "MYSQL_PWD=$($cfg.DB_ROOT_PASSWORD)" db sh -c "mariadb-dump -u root --single-transaction --databases $($cfg.DB_NAME) > /tmp/jmc-backup.sql"
    if ($LASTEXITCODE -ne 0) { throw 'could not dump the database.' }
    docker compose cp db:/tmp/jmc-backup.sql "$dir\wordpress.sql" *> $null
    if ($LASTEXITCODE -ne 0) { throw 'could not copy the database dump out of the container.' }
    docker compose exec -T db rm -f /tmp/jmc-backup.sql

    if (-not (Select-String -Path "$dir\wordpress.sql" -Pattern 'CREATE TABLE' -SimpleMatch -Quiet)) { throw 'the database dump has no tables in it.' }

    docker compose exec -T wordpress test -d /var/www/html/wp-content/uploads
    if ($LASTEXITCODE -eq 0) {
        docker compose cp wordpress:/var/www/html/wp-content/uploads "$dir\uploads" *> $null
        if ($LASTEXITCODE -ne 0) { throw 'could not copy the uploads folder.' }
    }
} catch {
    # A half-written backup must not be mistaken for a good one (or count towards -Keep).
    Remove-Item -Recurse -Force $dir -Confirm:$false -ErrorAction SilentlyContinue
    throw "Backup failed: $($_.Exception.Message)"
}

Get-ChildItem backups -Directory -Filter 'auto-*' | Sort-Object Name -Descending |
    Select-Object -Skip $Keep | Remove-Item -Recurse -Force -Confirm:$false

$size = (Get-ChildItem $dir -Recurse -File | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("Backup saved: {0} ({1:N1} MB)" -f $dir, $size)
