#!/bin/bash
# Import users, customers, projects and assignments from a CSV file.
# Usage: bash scripts/import.sh [path/to/file.csv]
#
# CSV format (one row per user–project assignment):
#   username,display_name,email,password,role,customer,project
#
# Duplicate username rows = same user on multiple projects.
# The script is idempotent — safe to run more than once.

set -e

CONTAINER="kimai-app"
DB_CONTAINER="kimai-db"
DB_USER="kimai"
DB_PASS="kimai_test_password_123"
DB_NAME="kimai"

# Defaults for new customers (override by setting env vars before running)
COUNTRY="${COUNTRY:-PL}"
CURRENCY="${CURRENCY:-PLN}"
TIMEZONE="${TIMEZONE:-Europe/Warsaw}"

CSV="${1:-data/import.csv}"

if [[ ! -f "$CSV" ]]; then
    echo "ERROR: CSV file not found: $CSV"
    echo "Usage: bash scripts/import.sh [path/to/file.csv]"
    exit 1
fi

# ── helpers ──────────────────────────────────────────────────────────────────

sql() {
    docker exec "$DB_CONTAINER" mysql \
        --default-character-set=utf8mb4 \
        -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
        -e "$1"
}

# ── wait for Kimai ────────────────────────────────────────────────────────────

echo "Waiting for Kimai to be ready..."
until docker exec "$CONTAINER" /opt/kimai/bin/console kimai:user:list &>/dev/null; do
    sleep 3
done

# ── process CSV ───────────────────────────────────────────────────────────────

echo ""
echo "Reading $CSV ..."
echo ""

# Temp file to track which usernames we've already created (survives subshell in pipe)
CREATED_USERS_FILE=$(mktemp)
trap 'rm -f "$CREATED_USERS_FILE"' EXIT

tail -n +2 "$CSV" | while IFS=',' read -r username display_name email password role customer project; do
    # Trim whitespace
    username=$(echo "$username" | xargs)
    display_name=$(echo "$display_name" | xargs)
    email=$(echo "$email" | xargs)
    password=$(echo "$password" | xargs)
    role=$(echo "$role" | xargs)
    customer=$(echo "$customer" | xargs)
    project=$(echo "$project" | xargs)

    if [[ -z "$username" || -z "$email" ]]; then
        continue
    fi

    echo "── Processing: $display_name ($username) → $customer / $project"

    # ── 1. Create user (once per username) ───────────────────────────────────
    if ! grep -qxF "$username" "$CREATED_USERS_FILE" 2>/dev/null; then
        docker exec "$CONTAINER" /opt/kimai/bin/console \
            kimai:user:create "$username" "$email" "$role" "$password" \
            2>&1 | grep -v "^$" | sed 's/^/  /' || true
        echo "$username" >> "$CREATED_USERS_FILE"
    fi

    # ── 2. Set display name ───────────────────────────────────────────────────
    sql "UPDATE kimai2_users
         SET alias='$(echo "$display_name" | sed "s/'/''/g")'
         WHERE username='$(echo "$username" | sed "s/'/''/g")'
           AND (alias IS NULL OR alias = '');"

    # ── 3. Set weekly hours as default view ───────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_user_preferences (user_id, name, value)
         SELECT id, 'login_initial_view', 'quick_entry'
         FROM kimai2_users WHERE username='$(echo "$username" | sed "s/'/''/g")';"

    # ── 4. Create customer ────────────────────────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_customers
             (name, visible, billable, country, currency, timezone, created_at)
         VALUES
             ('$(echo "$customer" | sed "s/'/''/g")', 1, 1, '$COUNTRY', '$CURRENCY', '$TIMEZONE', NOW());"

    # ── 5. Create project (linked to customer) ────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_projects
             (customer_id, name, visible, billable, budget, global_activities, created_at)
         SELECT id,
                '$(echo "$project" | sed "s/'/''/g")',
                1, 1, 0, 1, NOW()
         FROM kimai2_customers
         WHERE name='$(echo "$customer" | sed "s/'/''/g")'
         LIMIT 1;"

    # ── 6. Create team (one per project) ──────────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_teams (name)
         VALUES ('$(echo "$project" | sed "s/'/''/g")');"

    # ── 7. Link team → project ────────────────────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_projects_teams (project_id, team_id)
         SELECT p.id, t.id
         FROM kimai2_projects p
         JOIN kimai2_teams t ON t.name = '$(echo "$project" | sed "s/'/''/g")'
         WHERE p.name = '$(echo "$project" | sed "s/'/''/g")'
         LIMIT 1;"

    # ── 8. Link team → customer ───────────────────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_customers_teams (customer_id, team_id)
         SELECT c.id, t.id
         FROM kimai2_customers c
         JOIN kimai2_teams t ON t.name = '$(echo "$project" | sed "s/'/''/g")'
         WHERE c.name = '$(echo "$customer" | sed "s/'/''/g")'
         LIMIT 1;"

    # ── 9. Add user to team ───────────────────────────────────────────────────
    sql "INSERT IGNORE INTO kimai2_users_teams (user_id, team_id, teamlead)
         SELECT u.id, t.id, 0
         FROM kimai2_users u
         JOIN kimai2_teams t ON t.name = '$(echo "$project" | sed "s/'/''/g")'
         WHERE u.username = '$(echo "$username" | sed "s/'/''/g")'
         LIMIT 1;"

done

echo ""
echo "Import complete!"
echo ""
echo "Open http://localhost:8001 and log in to verify."
