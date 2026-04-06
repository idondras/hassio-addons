ARG BUILD_FROM
FROM ${BUILD_FROM}

# Basis-Abhängigkeiten
RUN apk add --no-cache \
    bash \
    curl \
    openssl \
    icu-data-full \
    jq \
    su-exec \
    libstdc++

# Node.js 20 via offiziellem Binary (Alpine-Paket hat v24, zu neu fuer Paperclip)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then NODE_ARCH="arm64"; else NODE_ARCH="x64"; fi && \
    curl -fsSL "https://nodejs.org/dist/v20.19.0/node-v20.19.0-linux-${NODE_ARCH}.tar.xz" | \
    tar -xJ -C /usr/local --strip-components=1 && \
    node --version && npm --version

# Paperclip AI global installieren
RUN npm install -g paperclipai@2026.403.0

# Non-root User fuer Postgres
RUN addgroup -S paperclip && adduser -S paperclip -G paperclip

# Startskript
COPY run.sh /
RUN chmod +x /run.sh

EXPOSE 3100

CMD ["/run.sh"]
