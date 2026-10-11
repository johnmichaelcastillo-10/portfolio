# CLAUDE.md

Project memory for Claude Code. Read this first; update it when something here stops being
true or a new non-obvious lesson is learned. Design rules live in `DESIGN.md`, the GitHub-facing
overview in `README.md` (hero screenshots in `docs/`, retake them after visual changes), and
install/publish steps for Windows, Linux and macOS in `DEPLOYMENT.md` (keep it in step with
the scripts); this file holds what is expensive to rediscover.

## What this is

Project name: **jmcastillo-portfolio** (folder, GitHub repo and Docker project; Docker
volumes are `jmcastillo-portfolio_db_data` and `jmcastillo-portfolio_wp_core`).

John Michael Castillo's personal portfolio: a WordPress block theme
(`wp-content/themes/jmc-portfolio`) plus a plugin (`wp-content/plugins/jmc-portfolio-core`:
projects, skills, contact form, resume link, meta tags), running locally in Docker.
Hosted as a static export on Vercel (see Data).

## Git and accounts (do not get wrong)

- Belongs to GitHub account **johnmichaelcastillo-10**, not the machine's default
  `jmcastillo-mets`. Remote is `git@github-jmc10:johnmichaelcastillo-10/jmcastillo-portfolio.git`
  (SSH alias in `~/.ssh/config`, key `~/.ssh/github_johnmichaelcastillo10`). Repo-local
  `user.name` / `user.email` are set; never change them or use HTTPS for this remote.
- Never add `Co-Authored-By` or any AI attribution to commits.
- Work on `main`, GitHub's default and only branch. The old `master` branch (someone else's
  2022 Coursera capstone) was deleted on 2026-10-11; never bring anything from it back.
- GitHub CLI: `gh` 2.102 (winget, `C:\Program Files\GitHub CLI\gh.exe`), logged in as
  `johnmichaelcastillo-10` with scopes `gist`, `read:org`, `repo` (no `delete_repo`). Shells
  started before the install don't have it on PATH: prefix commands with
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`.
  `gh auth login` / `gh auth refresh -s <scope>` are interactive (one-time code): the owner
  runs them in a separate PowerShell window, since `!` commands here lose the code and long
  pasted `!` lines get wrapped and break. Repo deletion is blocked by the permission
  classifier; hand the owner a script file to run instead.
- Repo `jmcastillo-portfolio` is the account's only public repo (all others made private and
  empty ones deleted on 2026-10-11). It has a description, homepage (the Vercel URL) and
  topics; pinning it on the profile has no API (owner does it on github.com).
- Never commit `.env`, `backups/` or the resume PDF (it contains a phone number).

## Run and verify

```powershell
docker compose up -d                                   # http://localhost:8088
docker compose run --rm cli wp <command>               # WP-CLI (PHP 8.5)
php -l <file>                                          # host PHP 8.5.11, lint only
```

- Port **8088**: 8080 belongs to another project's container on this machine.
- Stack: `wordpress:php8.5-apache`, `mariadb:12.3` (LTS, `MARIADB_AUTO_UPGRADE=1`),
  `wordpress:cli-php8.5`. WordPress core, uploads and the DB live in Docker volumes.
- Host PHP 8.5.11 lives in `%LOCALAPPDATA%\Programs\PHP\8.5` (official php.net zip, not
  winget); Composer in `%LOCALAPPDATA%\Programs\Composer`. The site never uses host PHP.
- `WP_DEBUG=1` prints PHP warnings into the HTML: after any change, fetch the pages and grep
  for `<b>Warning</b>` / `Deprecated` / `Fatal error`.
- Visual checks: `playwright-cli` (global install; skill in `.claude/skills/playwright-cli`)
  with `--browser=msedge`. Set `set-reduced-motion reduce` before full-page screenshots or the
  scroll-reveal leaves sections faded. Check light, dark (`set-color-scheme dark`) and 390px.
  Headless Edge's own `--window-size` can't go below ~500px; use `playwright-cli resize`.
- Code graph: Graphify (`uv tool install graphifyy`, project-scoped install). `graphify-out/`
  is gitignored, so after a fresh clone run `graphify update .` (local AST pass, no API cost).
  `.graphifyignore` keeps the vendored `.claude/skills/` out of the graph. Rules for using it
  are in the "graphify" section at the end of this file.

## Data

- **Confidentiality rule (from the owner): systems built at any job or internship must never
  appear on the site**: no project pages, screenshots, system names or descriptions of them
  (WMS, customer portal, e-wallet, university systems, the 3D twin, the Nuxt ERP...). Projects
  are personal work only, added by the owner. Experience duties stay generic ("internal
  business web applications"). The Work section, its nav/footer links and the hero's "View my
  work" button appear only when a project is published (`jmc_has_projects()`).
- **Live site:** https://jmcastillo-portfolio.vercel.app (Vercel project `jmcastillo-portfolio`,
  Vercel user `jmcastillo`, team scope `kaizerrrs-projects`, Hobby plan; linked via `.vercel/`,
  gitignored). The owner deploys by double-clicking `Deploy.cmd`, which runs
  `.\scripts\publish.ps1 -Deploy` (starts Docker Desktop if needed, waits for WordPress, copies
  `.vercel/` into `dist/`, then `vercel deploy dist --prod`). Linux/macOS twins:
  `deploy.sh` → `scripts/publish.sh --deploy`, and `scripts/setup.sh`; keep them in step with
  the `.ps1` versions. They were tested in WSL Ubuntu (PHP 8.3 from apt) with docker stubbed:
  running `docker compose` from WSL against the Windows Docker Desktop recreates the
  WordPress container (bind-mount paths differ) and fails on port 8088, after which
  `docker compose up -d` from Windows restores it. Never run compose from WSL here. The account has two teams, so non-interactive CLI calls need
  `--scope kaizerrrs-projects`. `*.vercel.app` doesn't load from this network (TLS fails, also
  via WebFetch and `vercel curl`): the owner checks the live site from his phone.
  The owner confirmed the Vercel site and form work (2026-10-11). The old Netlify site
  (jmcastillo-portfolio.netlify.app) is no longer deployed; the owner deletes it from the
  Netlify dashboard, and `.netlify/` is stale.
- **Contact form is Web3Forms** (free). `.env` holds `WEB3FORMS_KEY` (public by design, ends up
  in the HTML). The exporter rewrites the form to post to `api.web3forms.com/submit` with
  `access_key`, `subject`, `from_name`, `redirect` = `STATIC_URL/message-sent/` (free plan only
  redirects to the same domain, so `STATIC_URL` is required) and honeypot checkbox `botcheck`.
  It fails the export if the key/URL is missing or the plugin's form markup stops matching.
  Web3Forms' dashboard errored ("<!DOCTYPE ... is not valid JSON") when the site URL wasn't
  live yet; deploy first, then register the domain.
- **Hosting is static.** `scripts/publish.ps1` runs `scripts/export-static.php`
  (host PHP, crawls http://localhost:8088 from `/`, `/projects/`, `/message-sent/` and the
  sitemap, downloads every referenced asset, rewrites URLs to `STATIC_URL`, strips REST/feed
  head links) into `dist/` (gitignored), then copies `static/` (`vercel.json`: headers,
  `trailingSlash`) in. The export fails on PHP warnings or leftover localhost links. Anything
  that needs PHP at request time won't work live; new server features must have a static
  equivalent. A new page reachable only by a link is found by the crawler; one not linked
  anywhere must be added to the seed list in the exporter.
- `scripts/seed-content.php` sets the tagline and creates the `message-sent` page. Pre-removal backup with the old projects:
  `backups/wordpress-before-removing-projects-*.sql` (local only, never publish it).
- Back up before anything risky. Dump inside the container and copy out, never pipe through
  PowerShell 5.1 (it re-encodes):
  `docker compose exec -T -e MYSQL_PWD=... db sh -c "mariadb-dump -u root --single-transaction --databases wordpress > /tmp/x.sql"`
  then `docker compose cp db:/tmp/x.sql backups/`.
- Photos: **only CC0 or public domain** (the owner wants no credits on the site). The hero
  photo ships with the theme (`assets/images/`, see SOURCES.md). No captions, no credits page.
- Images must be HD: project images 1920×1200 (WordPress makes the srcset sizes), hero
  ~1100px wide. Source them from **Wikimedia Commons** (API search, filter licence to
  CC0/public domain, width ≥ 2000); download the 1920px `thumburl` (arbitrary widths like
  2400px return an error page, so check the file is really an image). Openverse's proxy
  caps downloads at ~800–1024px, so it is only good for finding candidates.
- Finding images: Openverse API with `license=cc0,pdm` (never `by`). Flickr's image host
  (live.staticflickr.com) is unreachable from this network; download through Openverse's
  proxy `https://api.openverse.org/v1/images/<id>/thumb/?full_size=true&compressed=false`.
  Crop/convert with host PHP GD (`imagewebp`).
- Identity rule (from the owner): present him as a software developer in general. Employers,
  including Mets Cold Storage, appear **only in the Experience section**, never in the hero,
  About, Work intro, project write-ups, tagline or meta tags.
- Content rule: only facts from the resume (`Downloads\Castillo-Resume-Dev.pdf`). Never invent
  metrics, outcomes or promises. Ask the user for numbers.

## WordPress lessons learned here

- Shortcodes don't run inside a pattern placed in a template (shortcodes expand before
  patterns). Server features must be blocks; the contact form is `jmc-portfolio/contact-form`.
- New pattern files are invisible until the pattern cache expires unless
  `WP_DEVELOPMENT_MODE` is `theme` (set in `docker-compose.yml`).
- `wptexturize` turns `" - "` and digit ranges into en dashes. Copy bans dashes, so write
  "Since 2025", "Mar to May 2024".
- kses strips `<email>`-looking text from post titles; message titles use `Name — email`.
- Buttons bound to post meta / the resume option (Block Bindings) render nothing when empty;
  see `includes/links.php`.
- Navigation and Social Icons blocks are banned on the front end (≈20 KB and ≈12 KB of inline
  CSS, plus the Interactivity API). Header and footer are PHP patterns holding Custom HTML;
  the mobile menu and current-section marker are `assets/js/site.js`. The menu only
  collapses when `<html>` has the `js` class (set inline in `<head>` by functions.php).
- A `wp:pattern` inside a Query Loop's post template loses the post context (titles render
  empty), so card markup is inlined in each query.
- Plain `.btn` links need `box-sizing: border-box` (core only sets it on block buttons).
- `jmc_icon()` must only strip width/height from the root `<svg>`; inner `<rect>`s need theirs.
- PowerShell 5.1: don't use `$ErrorActionPreference = 'Stop'` around docker (stderr progress
  becomes errors); check `$LASTEXITCODE` instead.

## Design

`DESIGN.md` is the source of truth (palette, Schibsted Grotesk + IBM Plex Mono, label-margin
layout, banned "AI look" patterns, engineering rules). Skills used to produce it are vendored
in `.claude/skills/` (taste, redesign, image-to-code, web-design-guidelines, playwright-cli).
Image generation (Higgsfield) costs credits: never use it without asking.

## Open items

- Missing from the user: personal projects (none yet), LinkedIn URL, resume copy without
  the phone number.
- Analytics. The owner still has to delete the old Netlify project.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
