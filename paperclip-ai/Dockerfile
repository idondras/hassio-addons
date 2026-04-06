ARG BUILD_FROM
FROM ${BUILD_FROM}

# Node.js + npm + Abhängigkeiten
RUN apk add --no-cache \
    nodejs \
    npm \
    bash \
    curl \
    openssl \
    icu-data-full \
    jq \
    su-exec

# Paperclip AI global installieren
RUN npm install -g paperclipai@2026.403.0

# Non-root User fuer Postgres (laeuft nicht als root)
RUN addgroup -S paperclip && adduser -S paperclip -G paperclip

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
