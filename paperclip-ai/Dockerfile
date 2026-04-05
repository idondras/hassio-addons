ARG BUILD_FROM
FROM ${BUILD_FROM}

# Node.js 22 + npm + Abhängigkeiten
RUN apk add --no-cache \
    nodejs \
    npm \
    bash \
    curl \
    openssl \
    icu-data-full \
    jq

# Paperclip AI global installieren
RUN npm install -g paperclipai@2026.403.0

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
