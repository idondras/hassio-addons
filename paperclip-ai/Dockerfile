ARG BUILD_FROM
FROM ${BUILD_FROM}

# Basis-Abhängigkeiten + Node.js aus Alpine 3.21 Repos (Node 22.x) + PostgreSQL
RUN apk add --no-cache \
    bash \
    curl \
    openssl \
    icu-data-full \
    jq \
    su-exec \
    libstdc++ \
    nodejs \
    npm \
    nginx \
    postgresql16 \
    postgresql16-client

# Node-Version pruefen
RUN node --version && npm --version && postgres --version

# Paperclip AI global installieren
# NODE_OPTIONS noetig weil einige Dependencies ESM-only sind aber von CJS require()'d werden
ENV NODE_OPTIONS="--experimental-require-module"
RUN npm install -g paperclipai@2026.403.0

# Symlink fuer embedded-postgres: zeige auf Alpine's native PostgreSQL
# embedded-postgres sucht unter linux-arm64/native/bin/ — wir linken dorthin
RUN PG_EMBED_DIR=$(find /usr/local/lib/node_modules/paperclipai/node_modules -path "*/@embedded-postgres" -type d 2>/dev/null | head -1) && \
    if [ -n "$PG_EMBED_DIR" ]; then \
      ARCH=$(uname -m) && \
      if [ "$ARCH" = "aarch64" ]; then PG_ARCH="linux-arm64"; else PG_ARCH="linux-x64"; fi && \
      mkdir -p "$PG_EMBED_DIR/$PG_ARCH/native/bin" && \
      mkdir -p "$PG_EMBED_DIR/$PG_ARCH/native/lib" && \
      mkdir -p "$PG_EMBED_DIR/$PG_ARCH/native/share" && \
      for bin in initdb postgres pg_ctl pg_isready psql pg_dump pg_restore; do \
        if command -v $bin >/dev/null 2>&1; then \
          ln -sf $(which $bin) "$PG_EMBED_DIR/$PG_ARCH/native/bin/$bin"; \
        fi; \
      done && \
      ln -sfn /usr/lib/postgresql16 "$PG_EMBED_DIR/$PG_ARCH/native/lib/postgresql" && \
      ln -sfn /usr/share/postgresql16 "$PG_EMBED_DIR/$PG_ARCH/native/share/postgresql" && \
      echo "Postgres symlinks created in $PG_EMBED_DIR/$PG_ARCH/native/bin/"; \
    else \
      echo "WARNING: embedded-postgres dir not found"; \
    fi

# Non-root User fuer Postgres
RUN addgroup -S paperclip && adduser -S paperclip -G paperclip

# nginx Config fuer Ingress Path-Rewriting
COPY nginx.conf /etc/nginx/nginx.conf

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
