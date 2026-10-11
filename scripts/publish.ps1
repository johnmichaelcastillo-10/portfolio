#Requires -Version 5.1
# Builds the static site in dist/ from the local WordPress, and optionally deploys it to Vercel.
#
#   .\scripts\publish.ps1            # export only; preview: node scripts/serve-dist.js (DEPLOYMENT.md)
#   .\scripts\publish.ps1 -Deploy    # export, then deploy to Vercel (production)
#
# First deploy only: `npm install -g vercel`, `vercel login`, then `vercel link` in this folder
# (creates .vercel/, which is copied into dist/ so the deploy lands on the same project).
# .env needs STATIC_URL (the Vercel domain) and WEB3FORMS_KEY (the contact form's access key).
param([switch]$Deploy)

# Not 'Stop': in PowerShell 5.1 that turns native stderr output into errors.
$ErrorActionPreference = 'Continue'
Set-Location (Split-Path $PSScriptRoot -Parent)

$cfg = @{}
foreach ($line in Get-Content .env) {
    if ($line -match '^([A-Z0-9_]+)=(.*)$') { $cfg[$Matches[1]] = $Matches[2].Trim() }
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Starting Docker Desktop...'
    Start-Process "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    for ($i = 0; $i -lt 60 -and $LASTEXITCODE -ne 0; $i++) { Start-Sleep 5; docker info *> $null }
    if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop did not start within 5 minutes.' }
}
docker compose up -d
if ($LASTEXITCODE -ne 0) { throw 'docker compose up failed.' }
# WordPress needs a moment after a cold start before the export can crawl it.
for ($i = 0; $i -lt 30; $i++) {
    try { Invoke-WebRequest $cfg.WP_URL -UseBasicParsing -TimeoutSec 5 *> $null; break } catch { Start-Sleep 2 }
}

if ($Deploy) { & "$PSScriptRoot\backup.ps1" } # throws, and so stops the deploy, if it fails

$exportArgs = @('scripts/export-static.php', "--source=$($cfg.WP_URL)", "--form-key=$($cfg.WEB3FORMS_KEY)")
if ($cfg.STATIC_URL) {
    $exportArgs += "--url=$($cfg.STATIC_URL)"
} else {
    Write-Host 'STATIC_URL is not set in .env: links will be root-relative and canonical/og:url tags relative.'
}
php @exportArgs
if ($LASTEXITCODE -ne 0) { throw 'Static export failed; nothing was deployed.' }
# The exporter copies static\ (vercel.json) in itself and adds the CSP header to it.

if ($Deploy) {
    if (-not (Test-Path .vercel\project.json)) { throw 'Not linked to Vercel: run `vercel link` in this folder first.' }
    Copy-Item .vercel dist\ -Recurse -Force
    vercel deploy dist --prod --yes
    if ($LASTEXITCODE -ne 0) { throw 'Vercel deploy failed.' }
    Write-Host "`nDeployed: $($cfg.STATIC_URL)" -ForegroundColor Green
}
