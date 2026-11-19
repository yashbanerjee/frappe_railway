FROM node:24-bookworm-slim AS node
FROM python:3.14-slim-trixie
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && npm install -g yarn@1.22.22
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential pkg-config libcups2-dev libmariadb-dev mariadb-client libpq-dev redis-server nginx supervisor curl libpango-1.0-0 libharfbuzz-subset0 chromium fonts-liberation && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir frappe-bench && useradd -m -s /bin/bash frappe
USER frappe
WORKDIR /home/frappe
RUN bench init frappe-bench --frappe-branch develop --python /usr/local/bin/python --skip-assets --no-backups
WORKDIR /home/frappe/frappe-bench
RUN git -C apps/frappe checkout e15a7118c5ff932c201c5384802999f8117f30f6 && bench setup requirements
RUN git clone https://github.com/frappe/frappe-books /home/frappe/frappe-books && git -C /home/frappe/frappe-books checkout 343b60cdef5f4e4259eeb134d045e864d09ff6d3 && bench get-app --skip-assets /home/frappe/frappe-books
RUN bench set-config -gp socketio_port 9000 && bench build && cp -a sites/assets /home/frappe/assets
USER root
COPY entrypoint.sh /usr/local/bin/books-entrypoint
COPY supervisord.conf /etc/supervisor/conf.d/books.conf
COPY nginx.conf /etc/nginx/sites-enabled/default
RUN chmod 755 /usr/local/bin/books-entrypoint
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/books-entrypoint"]
