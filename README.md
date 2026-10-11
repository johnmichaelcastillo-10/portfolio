# John Michael Castillo · Portfolio

Personal portfolio of John Michael Castillo, software developer. Built as a custom WordPress
block theme, edited locally and published as a fast static site.

**Live:** https://jmcastillo-portfolio.vercel.app

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshot-dark.webp">
  <img alt="The portfolio's home page: a large headline, a short introduction, contact and resume buttons, and a photo of code" src="docs/screenshot-light.webp">
</picture>

## Features

- **Custom block theme** with its own design system: palette, type scale and spacing as
  `theme.json` tokens, self-hosted Schibsted Grotesk and IBM Plex Mono fonts.
- **Automatic dark mode** that follows the visitor's system setting.
- **Responsive** from small phones up, with a lightweight mobile menu (no heavy core
  Navigation block, so very little JavaScript).
- **Projects** as their own content type, tagged with skills, with live-site and source-code
  buttons that hide themselves when empty. The Work section only appears once a project is published.
- **Contact form** with spam protection, sent through Web3Forms on the live site.
- **Privacy-friendly analytics:** Vercel Web Analytics on the live site, with no cookies.
- **Link previews and SEO:** Open Graph and Twitter card tags, canonical URLs and a sitemap.
- **Security headers:** a strict Content-Security-Policy (inline scripts allowed only by
  hash, generated at export), plus clickjacking, MIME-sniffing and referrer protection.
- **Static hosting:** the public site is plain HTML, CSS and images, with no server code or
  database to attack or maintain.

## Tech stack

| Layer | Technology |
| --- | --- |
| CMS (local editor) | WordPress, PHP 8.5, MariaDB 12.3, WP-CLI, all in Docker |
| Theme | Block theme (`theme.json`, block templates, PHP patterns), vanilla CSS and JS |
| Plugin | Custom post type and taxonomy, Block Bindings, a server-rendered contact form block |
| Publishing | Custom PHP static exporter, Vercel (hosting), Web3Forms (contact form) |
| Tooling | PowerShell and Bash scripts, Playwright CLI for visual checks |

## How it works

```
 WordPress in Docker  ──export──▶  dist/ (static files)  ──deploy──▶  Vercel
   (your computer)                 HTML, CSS, fonts, images            (live site)
```

You edit content in the local WordPress admin, then one command crawls the site, saves it as
static files and uploads them. See **[DEPLOYMENT.md](DEPLOYMENT.md)** for the full setup:
software to install, accounts, and commands for Windows, Linux and macOS.

## Repository layout

| Path | What |
| --- | --- |
| `wp-content/themes/jmc-portfolio` | Block theme: design tokens (`theme.json`), templates, front-page sections (`patterns/`), fonts, CSS and JS |
| `wp-content/plugins/jmc-portfolio-core` | Projects and skills, link buttons, the contact form block, meta tags |
| `scripts/` | Setup (`setup.ps1`, `setup.sh`), publish (`publish.ps1`, `publish.sh`), backup (`backup.ps1`, `backup.sh`), the static exporter, content seeding |
| `static/vercel.json` | Live site headers, caching and URL rules (the exporter adds the CSP) |
| `Deploy.cmd`, `deploy.sh` | One-step publish (Windows, Linux/macOS) |
| `docker-compose.yml` | WordPress, MariaDB and WP-CLI containers |
| `DESIGN.md` | Design spec: palette, type, layout rules. Read it before changing the theme |
| `DEPLOYMENT.md` | Install, configure and publish |
| `.claude/skills/` | Claude Code skills used for the design work |

WordPress core, uploads and the database live in Docker volumes, not in git.

## Quick start

Requires Docker, PHP and Node.js; [DEPLOYMENT.md](DEPLOYMENT.md) has the install commands.

```powershell
.\scripts\setup.ps1          # Windows
```
```bash
scripts/setup.sh             # Linux / macOS
```

- Site: http://localhost:8088
- Admin: http://localhost:8088/wp-admin (user `admin`, password in `.env`)

Day to day:

```bash
docker compose up -d                      # start
docker compose stop                       # stop
docker compose run --rm cli wp <command>  # WP-CLI
docker compose down -v                    # delete everything, including the database
```

The theme and plugin folders are mounted into the container, so code edits show up on refresh.

## Editing content

- **Projects:** Admin → Projects. Set a featured image, an excerpt (the card text) and skills.
  For the "View live site" and "Source code" buttons, open the editor's ⋮ menu →
  Preferences → General → Custom fields, then fill in `project_url` and `repo_url`.
  A button whose field is empty is hidden.
- **Resume button:** upload the PDF under Media, then paste its URL in Settings → General →
  Resume (PDF) URL. The hero's "Resume" button is hidden until this is set.
- **Contact form messages:** on the live site they arrive by email through Web3Forms. Locally,
  every message is saved under Admin → Messages (there is no mail server).
- **Footer and contact links:** edit `patterns/footer.php` and `patterns/contact.php` in the theme.
- **Link previews:** the page description and preview image come from the site tagline, each
  project's excerpt and featured image, and the Site Icon (Settings → General). Installing an
  SEO plugin (Yoast, Rank Math) turns these tags off automatically.
- **Front page text:** Appearance → Editor → Templates → Front Page. Edits made there
  are stored in the database. To keep them in git, copy the changed markup back into
  `patterns/`, or export the theme with Appearance → Editor → ⋮ → Export.

After editing, publish with `Deploy.cmd` (Windows) or `./deploy.sh` (Linux/macOS).

## License

The theme is licensed GPL-2.0-or-later (see its `style.css` header).
