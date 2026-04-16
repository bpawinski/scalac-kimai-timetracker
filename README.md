# Kimai Local

Local development setup for [Kimai](https://www.kimai.org/) time-tracking, running via Docker.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac, Windows, Linux)
- Git

## Quick start

```bash
# 1. Clone the repo
git clone <repo-url>
cd kimai-local

# 2. Start containers
docker compose up -d

# 3. Wait ~30 seconds for Kimai to install, then run the setup script
bash scripts/setup.sh
```

Open http://localhost:8001

## Credentials

| Role       | Email                | Password   | Display name      |
|------------|----------------------|------------|-------------------|
| Super Admin| admin@kimai.local    | admin12345 |                   |
| Developer  | dev1@kimai.local     | devpass1   | Piotr Kowalski    |
| Developer  | dev2@kimai.local     | devpass2   | Anna Nowak        |
| Developer  | dev3@kimai.local     | devpass3   | Tomasz Wiśniewski |
| Developer  | dev4@kimai.local     | devpass4   | Katarzyna Wójcik  |
| Developer  | dev5@kimai.local     | devpass5   | Marek Kamiński    |

## Project structure

```
kimai-local/
├── docker-compose.yml          # Docker services definition
├── config/
│   └── local.yaml              # Kimai config overrides (mounted into container)
├── public/
│   └── custom.css              # Custom styles (mounted into container)
├── templates/
│   └── base.html.twig          # Modified base template (mounted into container)
└── scripts/
    └── setup.sh                # One-time user & data setup script
```

## Customisations applied

- **Apache image** (`kimai/kimai2:apache`) instead of PHP-FPM
- **Invoicing hidden** — removed from all menus and roles
- **Live time tracking disabled** — play button hidden, start/stop permissions removed
- **Default view** — Weekly hours (`/en/quick_entry/`) for all users
- **Default start time** — 08:00, business hours 08:00–16:00
- **Weekend columns** — highlighted in dark green in the weekly view
- **Global activity** — "Development" available on all projects by default
- **Dev users** — 5 pre-created users with Polish names

## Useful commands

```bash
# Start
docker compose up -d

# Stop
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
```
