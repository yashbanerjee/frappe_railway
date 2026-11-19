# Frappe Books on Railway

Separate single-instance deployment of frappe/frappe-books on Frappe develop.
Use the /books directory as the Railway root and mount a persistent volume at /data.
Expose port 8080 with healthcheck /api/method/ping and a 600-second startup timeout.
The web application is served at /books. SQLite database, files, Redis queue, and
initial admin password are stored on the volume. No credentials are in Git.
Initial Administrator password: /data/initial-admin-password (root readable).
This deployment uses development Frappe 17, and should be evaluated before using
it for live accounting. Keep volume backups. Do not scale above one replica.
