ARG BUILD_FROM
FROM ${BUILD_FROM}

# Basis-Abhängigkeiten + Node.js aus Alpine 3.21 Repos (Node 22.x)
RUN apk add --no-cache \
    bash \
    curl \
    openssl \
    icu-data-full \
    jq \
    su-exec \
    libstdc++ \
    nodejs \
    npm

# Node-Version pruefen
RUN node --version && npm --version

# Paperclip AI global installieren
# NODE_OPTIONS noetig weil einige Dependencies ESM-only sind aber von CJS require()'d werden
ENV NODE_OPTIONS="--experimental-require-module"
RUN npm install -g paperclipai@2026.403.0

# Non-root User fuer Postgres
RUN addgroup -S paperclip && adduser -S paperclip -G paperclip

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
