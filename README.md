# Kimai Local — Scalac Time Tracker

Local development setup for [Kimai](https://www.kimai.org/) time-tracking, running via Docker.

No need to download Kimai manually — Docker pulls the image automatically from Docker Hub on first run.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac, Windows, Linux)
- Git

## Setup for a new machine (colleague)

```bash
# 1. Clone the repository
git clone https://github.com/bpawinski/scalac-kimai-timetracker.git
cd scalac-kimai-timetracker

# 2. Start containers
#    Docker will automatically download Kimai and MySQL images on first run (~500MB, takes a few minutes)
docker compose up -d

# 3. Wait ~30 seconds for Kimai to finish installing, then run the one-time setup script
bash scripts/setup.sh
```

Open http://localhost:8001 — done.

> The `kimai-src/` directory is intentionally gitignored. Docker mounts only the config files
> from this repo (`config/`, `public/`, `templates/`) into the container.

## Credentials

| Role        | Email               | Password   | Display name      |
|-------------|---------------------|------------|-------------------|
| Super Admin | admin@kimai.local   | admin12345 |                   |
| Developer   | dev1@kimai.local    | devpass1   | Piotr Kowalski    |
| Developer   | dev2@kimai.local    | devpass2   | Anna Nowak        |
| Developer   | dev3@kimai.local    | devpass3   | Tomasz Wiśniewski |
| Developer   | dev4@kimai.local    | devpass4   | Katarzyna Wójcik  |
| Developer   | dev5@kimai.local    | devpass5   | Marek Kamiński    |

## Project structure

```
scalac-kimai-timetracker/
├── docker-compose.yml                          # Docker services definition
├── config/
│   └── local.yaml                              # Kimai config overrides (mounted into container)
├── public/
│   ├── custom.css                              # Custom styles
│   ├── custom.js                               # Custom behaviour (auto-select, delete row)
│   └── sign-red.png                            # Scalac company logo
├── templates/
│   ├── base.html.twig                          # Main app layout (navbar logo, custom.css/js)
│   ├── login.html.twig                         # Login page (custom.css, logo)
│   └── password-reset-layout.html.twig         # Password reset page (custom.css, logo)
├── scripts/
│   └── setup.sh                                # One-time user & data setup script
└── KIMAI_DOCKER_COMMANDS.md                    # Full command reference (Polish)
```

## Customisations applied

### Branding
- **Company logo** (`public/sign-red.png`) — shown on login page, password reset page, and navbar after login
- **Login page** — logo size reduced, login card larger with rounded corners, inputs and buttons rounded
- **Password reset page** — same styling as login page

### Permissions & navigation
- **Apache image** (`kimai/kimai2:apache`) instead of PHP-FPM
- **Invoicing hidden** — removed from all menus and roles (`INVOICE`, `INVOICE_ADMIN` sets stripped)
- **Live time tracking disabled** — play button hidden via CSS, `start_own_timesheet` / `stop_own_timesheet` permissions removed

### Time tracking defaults
- **Default view** — Weekly hours (`/en/quick_entry/`) for all users on login
- **Default start time** — 08:00, business hours 08:00–16:00 in calendar
- **1 row by default** — weekly view shows 1 row, use `+ Add` for more
- **Auto-select project** — if a user has only 1 project assigned, it is selected automatically
- **Auto-select activity** — "Development" activity is selected automatically when project is chosen
- **Delete row** — trash button on each weekly hours row to remove it

### Visual
- **Weekend columns** — Saturday and Sunday highlighted in dark green in the weekly view
- **Global activity** — "Development" available on all projects by default (global, not project-specific)

### Users
- **5 dev users** pre-created with Polish names (dev1–dev5)

## How customisations work

| File | What it does |
|---|---|
| `config/local.yaml` | Kimai permission sets, calendar hours, default start time |
| `public/custom.css` | Logo sizing, rounded UI on login/reset, green weekends, hides play button |
| `public/custom.js` | Auto-select project & activity, delete row button in weekly view |
| `public/sign-red.png` | Scalac logo — mounted into container public directory |
| `templates/base.html.twig` | Injects `custom.css` + `custom.js`, overrides navbar logo with `sign-red.png` |
| `templates/login.html.twig` | Injects `custom.css` on login page |
| `templates/password-reset-layout.html.twig` | Injects `custom.css` + sets body class for logo sizing |
| DB: `theme.branding.logo` | Points login page logo partial to `/sign-red.png` |
| DB: `quick_entry.minimum_rows` | Set to `1` — shows 1 row by default in weekly view |

## Useful commands

```bash
# Start
docker compose up -d

# Stop (keeps data)
docker compose down

# Stop and delete all data (full reset)
docker compose down -v

# View logs
docker logs kimai-app -f

# List users
docker exec kimai-app /opt/kimai/bin/console kimai:user:list

# Reload config after editing local.yaml
docker exec kimai-app /opt/kimai/bin/console kimai:reload --env=prod
docker exec kimai-app chown -R www-data:www-data /opt/kimai/var/cache

# Apply changes to docker-compose.yml (new volume mounts etc.)
docker compose up -d --force-recreate kimai
```

## Contributing changes

```bash
# Pull latest changes from the repo
git pull

# After making changes, commit and push
git add .
git commit -m "describe your change"
git push
```
