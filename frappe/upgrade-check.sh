#!/bin/bash
set -euo pipefail
cd /home/frappe/frappe-bench
test_site=upgrade-validation-v1660
marker="sites/.upgrade-v1660-validated"
if [ -f "$marker" ]; then exit 0; fi
backup="sites/${SITE_NAME:-frontend}/private/backups/${UPGRADE_BACKUP_PREFIX}-database.sql.gz"
test -s "$backup"
test -s "sites/${SITE_NAME:-frontend}/private/upgrade-rollback-state.json"
# Never recreate or overwrite a previous validation site automatically.
if [ -e "sites/$test_site/site_config.json" ]; then
  echo 'Validation site exists without a success marker; refusing to overwrite it.' >&2
  exit 1
fi
echo 'Restoring backup into isolated upgrade validation database'
runuser -u frappe -- bench new-site "$test_site" --mariadb-user-host-login-scope='%' --admin-password "$ADMIN_PASSWORD" --db-root-username root --db-root-password "$DB_ROOT_PASSWORD" --no-mariadb-socket
runuser -u frappe -- bench --site "$test_site" restore "$backup" --db-root-username root --db-root-password "$DB_ROOT_PASSWORD" --force
runuser -u frappe -- bench --site "$test_site" set-config maintenance_mode 1
runuser -u frappe -- bench --site "$test_site" set-config pause_scheduler 1
runuser -u frappe -- bench --site "$test_site" migrate
(cd sites && runuser -u frappe -- /home/frappe/frappe-bench/env/bin/python /usr/local/bin/preserve-accounting.py "$test_site" check)
touch "$marker"
echo 'Isolated migration and data checks passed; proceeding to live migration'
