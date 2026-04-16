#!/bin/bash
# Run this once after `docker compose up -d` to create users and configure Kimai.
# Usage: bash scripts/setup.sh

set -e

CONTAINER="kimai-app"

echo "Waiting for Kimai to be ready..."
until docker exec "$CONTAINER" /opt/kimai/bin/console kimai:user:list &>/dev/null; do
  sleep 3
done

echo "Creating admin user..."
docker exec "$CONTAINER" /opt/kimai/bin/console kimai:user:create admin admin@kimai.local ROLE_SUPER_ADMIN admin12345 || echo "Admin already exists, skipping."

echo "Creating dev users..."
for i in 1 2 3 4 5; do
  docker exec "$CONTAINER" /opt/kimai/bin/console kimai:user:create dev$i dev$i@kimai.local ROLE_USER devpass$i || echo "dev$i already exists, skipping."
done

echo "Setting Polish display names..."
docker exec kimai-db mysql --default-character-set=utf8mb4 \
  -u kimai -pkimai_test_password_123 kimai -e "
UPDATE kimai2_users SET alias='Piotr Kowalski'    WHERE username='dev1';
UPDATE kimai2_users SET alias='Anna Nowak'         WHERE username='dev2';
UPDATE kimai2_users SET alias='Tomasz Wiśniewski'  WHERE username='dev3';
UPDATE kimai2_users SET alias='Katarzyna Wójcik'   WHERE username='dev4';
UPDATE kimai2_users SET alias='Marek Kamiński'     WHERE username='dev5';
"

echo "Setting weekly hours as default view for all users..."
docker exec kimai-db mysql --default-character-set=utf8mb4 \
  -u kimai -pkimai_test_password_123 kimai -e "
UPDATE kimai2_user_preferences SET value = 'quick_entry' WHERE name = 'login_initial_view';
"

echo "Creating global Development activity..."
docker exec kimai-db mysql --default-character-set=utf8mb4 \
  -u kimai -pkimai_test_password_123 kimai -e "
INSERT IGNORE INTO kimai2_activities (id, project_id, name, visible, billable, time_budget, budget, created_at)
VALUES (1, NULL, 'Development', 1, 1, 0, 0, NOW())
ON DUPLICATE KEY UPDATE project_id = NULL, name = 'Development';
"

echo ""
echo "Setup complete!"
echo ""
echo "Login at http://localhost:8001"
echo "  Admin:  admin@kimai.local  / admin12345"
echo "  Users:  dev1@kimai.local   / devpass1  (Piotr Kowalski)"
echo "          dev2@kimai.local   / devpass2  (Anna Nowak)"
echo "          dev3@kimai.local   / devpass3  (Tomasz Wiśniewski)"
echo "          dev4@kimai.local   / devpass4  (Katarzyna Wójcik)"
echo "          dev5@kimai.local   / devpass5  (Marek Kamiński)"
