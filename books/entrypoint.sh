#!/bin/bash
set -euo pipefail
cd /home/frappe/frappe-bench
mkdir -p /data/sites /data/redis logs
chown -R frappe:frappe /data logs
rm -rf sites
ln -s /data/sites sites
ln -sfn /home/frappe/assets sites/assets
printf 'frappe\nfrappe_books\n' > sites/apps.txt
test -f sites/common_site_config.json || echo '{}' > sites/common_site_config.json
chown frappe:frappe sites/apps.txt sites/common_site_config.json
runuser -u frappe -- redis-server --bind 127.0.0.1 --port 6379 --dir /data/redis --appendonly yes --daemonize yes
runuser -u frappe -- bench set-config -g redis_cache redis://127.0.0.1:6379
runuser -u frappe -- bench set-config -g redis_queue redis://127.0.0.1:6379
runuser -u frappe -- bench set-config -g redis_socketio redis://127.0.0.1:6379
runuser -u frappe -- bench set-config -gp socketio_port 9000
runuser -u frappe -- bench set-config -g chromium_path /usr/bin/chromium
if [ ! -f sites/books/site_config.json ]; then
  umask 077
  python -c 'import secrets; print(secrets.token_urlsafe(32))' > /data/initial-admin-password
  runuser -u frappe -- bench new-site books --db-type sqlite --admin-password "$(cat /data/initial-admin-password)"
fi
runuser -u frappe -- bench --site books install-app frappe_books
runuser -u frappe -- bench --site books migrate
runuser -u frappe -- bench use books
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  runuser -u frappe -- bench --site books set-config host_name "https://$RAILWAY_PUBLIC_DOMAIN"
fi
runuser -u frappe -- bench --site books enable-scheduler
sed -i "s/listen 8080;/listen ${PORT:-8080};/" /etc/nginx/sites-enabled/default
redis-cli shutdown
exec supervisord -c /etc/supervisor/supervisord.conf
