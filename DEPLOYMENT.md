# Deployment guide

How to set up this project on a new computer and publish the site. The short version, once
everything below is installed and configured:

| System | Publish the site |
| --- | --- |
| Windows | Double-click `Deploy.cmd` |
| Linux / macOS | `./deploy.sh` |

## How publishing works

WordPress runs only on your computer, in Docker, as the editor. Publishing does three things:

1. **Export.** `scripts/export-static.php` crawls the local site at http://localhost:8088 and
   saves every page, stylesheet, script, font and image into `dist/` as plain files. It
   rewrites links to the live address, switches the contact form over to Web3Forms and adds
   the Vercel Web Analytics script (visits show under the project's **Analytics** tab).
2. **Configure.** The files in `static/` (`vercel.json`: security headers, caching, trailing
   slashes) are copied into `dist/`.
3. **Deploy.** The Vercel CLI uploads `dist/` to production.

The live site has no PHP or database, so there's nothing on it to patch or hack. If the export
finds a PHP warning, a broken page or a leftover `localhost` link, it stops and nothing is
published.

## 1. Install the software

| Software | Why | Version |
| --- | --- | --- |
| Git | Clone the repo | Any recent |
| Docker (Desktop on Windows/macOS, Engine on Linux) | Runs WordPress, MariaDB and WP-CLI | Compose v2 (`docker compose`) |
| PHP CLI with the **curl** extension | Runs the static export on your computer | 8.1 or newer |
| Node.js with npm | Installs the Vercel CLI | Current LTS |
| Vercel CLI | Uploads the site | Latest (`npm install -g vercel`) |

WordPress itself, MariaDB and WP-CLI come as Docker images; you don't install them.

### Windows 10/11

In PowerShell:

```powershell
winget install -e --id Git.Git
winget install -e --id Docker.DockerDesktop
winget install -e --id OpenJS.NodeJS.LTS
```

Restart after installing Docker Desktop, open it once and accept its terms.

PHP for Windows comes as a zip, not an installer:

1. Download the latest **VS17 x64 Non Thread Safe** zip from https://windows.php.net/download/.
2. Extract it to `%LOCALAPPDATA%\Programs\PHP\8.5` (any folder works).
3. In that folder, copy `php.ini-development` to `php.ini`, then remove the leading `;` from
   these lines:
   ```ini
   extension_dir = "ext"
   extension=curl
   extension=gd
   ```
   (`gd` is only needed for image editing scripts; `curl` is required.)
4. Add the folder to your user `Path` (Settings → System → About → Advanced system settings →
   Environment Variables), then open a new terminal.

Then install the Vercel CLI and check everything:

```powershell
npm install -g vercel
git --version; docker --version; php -v; node -v; vercel --version
php -r "echo function_exists('curl_init') ? 'curl OK' : 'curl MISSING';"
```

If PowerShell refuses to run scripts, allow local ones once:
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. (`Deploy.cmd` doesn't need this.)

### Linux (Ubuntu / Debian)

```bash
sudo apt update
sudo apt install -y git curl php-cli php-curl

# Docker Engine with the compose plugin (official convenience script)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"      # log out and back in for this to take effect

# Node.js LTS through nvm (distro packages are often too old for the Vercel CLI)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install --lts

npm install -g vercel
```

Check:

```bash
git --version; docker compose version; php -v; node -v; vercel --version
php -r 'echo function_exists("curl_init") ? "curl OK\n" : "curl MISSING\n";'
docker run --rm hello-world          # confirms Docker works without sudo
```

On Fedora, use `sudo dnf install git curl php-cli` (curl is built in) and follow
https://docs.docker.com/engine/install/fedora/ for Docker.

### macOS

With [Homebrew](https://brew.sh):

```bash
brew install git php node
brew install --cask docker           # then open Docker.app once
npm install -g vercel
```

Homebrew's PHP includes curl.

## 2. Accounts you need

| Account | What for | Cost |
| --- | --- | --- |
| [GitHub](https://github.com) (`johnmichaelcastillo-10`) | The code | Free |
| [Vercel](https://vercel.com) | Hosting (project `jmcastillo-portfolio`, team `kaizerrrs-projects`) | Free (Hobby plan) |
| [Web3Forms](https://web3forms.com) | Emails you the contact form messages | Free |

## 3. First-time setup on a computer

### Get the code

```bash
git clone git@github.com:johnmichaelcastillo-10/jmcastillo-portfolio.git
cd jmcastillo-portfolio
```

The SSH key on that computer must belong to the `johnmichaelcastillo-10` GitHub account.

### Install WordPress locally

| Windows | Linux / macOS |
| --- | --- |
| `.\scripts\setup.ps1` | `scripts/setup.sh` |

This creates `.env` with random passwords, starts the containers, installs WordPress,
activates the theme and plugin, and creates the "Message sent" page. It's safe to re-run.

- Site: http://localhost:8088
- Admin: http://localhost:8088/wp-admin (user `admin`, password in `.env`)

### Bring your content over

A fresh install has the theme and its pages, but not what you added in the WordPress admin
on your other computer (projects, skills, the resume link, uploaded images). That lives in
Docker volumes, not in git. **Deploying a fresh install would replace the live site with the
bare one**, so copy the content first.

On the old computer (replace `<DB_ROOT_PASSWORD>` with the value from its `.env`):

```bash
docker compose exec -T -e MYSQL_PWD=<DB_ROOT_PASSWORD> db sh -c "mariadb-dump -u root --single-transaction --databases wordpress > /tmp/wp.sql"
docker compose cp db:/tmp/wp.sql backups/wp.sql
docker compose cp wordpress:/var/www/html/wp-content/uploads backups/uploads
```

Copy the `backups/` folder to the new computer (USB drive, cloud drive; never commit it).
Then, on the new computer after the setup script, using **its** root password:

```bash
docker compose cp backups/wp.sql db:/tmp/wp.sql
docker compose exec -T -e MYSQL_PWD=<DB_ROOT_PASSWORD> db sh -c "mariadb -u root < /tmp/wp.sql"
docker compose cp backups/uploads/. wordpress:/var/www/html/wp-content/uploads
docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content/uploads
```

The imported database keeps the old WordPress admin password.

### Configure `.env`

Add or check these lines in `.env` (it's never committed):

| Key | Value |
| --- | --- |
| `STATIC_URL` | `https://jmcastillo-portfolio.vercel.app` (or your own domain later) |
| `WEB3FORMS_KEY` | The access key from your Web3Forms dashboard |

The export refuses to run without both: the contact form needs the key, and Web3Forms' free
plan only sends visitors back to the same domain after they submit.

### Connect to Vercel

```bash
vercel login
vercel link --yes --project jmcastillo-portfolio --scope kaizerrrs-projects
```

This creates `.vercel/` (and a `.env.local` token), both gitignored.

## 4. Publish

| | Windows | Linux / macOS |
| --- | --- | --- |
| Build and deploy | Double-click `Deploy.cmd` | `./deploy.sh` |
| Same, from a terminal | `.\scripts\publish.ps1 -Deploy` | `scripts/publish.sh --deploy` |
| Build only (no upload) | `.\scripts\publish.ps1` | `scripts/publish.sh` |
| Preview the build | `php -S 127.0.0.1:8099 -t dist` | `php -S 127.0.0.1:8099 -t dist` |

On Windows the script starts Docker Desktop if it isn't running. On Linux, start Docker
yourself (`sudo systemctl start docker`) if it isn't running.

A successful deploy ends with:

```
Deployed: https://jmcastillo-portfolio.vercel.app
```

Then check, ideally from your phone:

- The home page loads, in light and dark mode.
- The contact form sends: you land on the "Message sent" page and the email arrives.
- A made-up address such as `/nope/` shows the site's own 404 page.

Every deploy stays in the Vercel dashboard. To undo a bad one, open the project's
**Deployments** tab, open the previous production deployment's ⋯ menu and choose
**Instant Rollback**.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `docker compose up failed` / port 8088 in use | Another app uses port 8088. Stop it, or change `WP_PORT` and `WP_URL` in `.env`. |
| `cannot reach Docker` (Linux) | `sudo systemctl start docker`; make sure you logged out and back in after `usermod -aG docker`. |
| `Static export failed` with "contains a PHP warning" | A page shows a PHP error. Open it at http://localhost:8088 and fix the code first. |
| "the contact form needs --form-key" | `WEB3FORMS_KEY` or `STATIC_URL` is missing from `.env` (check the spelling). |
| "the contact form markup no longer matches" | The plugin's form HTML changed; update the rewrite in `scripts/export-static.php`. |
| `Not linked to Vercel` | Run the `vercel link` command above. |
| Vercel asks to log in again | `vercel login`. |
| `php has no curl extension` | Linux: `sudo apt install php-curl`. Windows: enable `extension=curl` in `php.ini`. |
| The live site won't open on some networks | Some networks block `*.vercel.app`; check from mobile data. A custom domain avoids this. |
| Contact emails don't arrive | Check spam, then the form's settings in the Web3Forms dashboard. |
