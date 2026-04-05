ARG BUILD_FROM
FROM ${BUILD_FROM}

# Node.js 20 + npm + PostgreSQL-Abhaengigkeiten
RUN apk add --no-cache \
    nodejs=~20 \
    npm \
    bash \
    curl \
    openssl \
    icu-data-full

# Paperclip AI global installieren
RUN npm install -g paperclipai@2026.403.0

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
