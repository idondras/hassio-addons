ARG BUILD_FROM
FROM ${BUILD_FROM}

# Basis-Abhängigkeiten + Node.js 20 nativ aus Alpine 3.19 Repos
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

# Node-Version pruefen (sollte 20.x sein auf Alpine 3.19)
RUN node --version && npm --version

# Paperclip AI global installieren
RUN npm install -g paperclipai@2026.403.0

# Non-root User fuer Postgres
RUN addgroup -S paperclip && adduser -S paperclip -G paperclip

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
