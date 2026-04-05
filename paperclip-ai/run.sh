#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════
# Paperclip AI — Home Assistant Add-on Startskript
# ═══════════════════════════════════════════════════════

PAPERCLIP_HOME="/data/paperclip"
INSTANCE_DIR="${PAPERCLIP_HOME}/instances/default"

# --- Verzeichnisse anlegen ---
mkdir -p "${INSTANCE_DIR}/db"
mkdir -p "${INSTANCE_DIR}/data/storage"
mkdir -p "${INSTANCE_DIR}/data/backups"
mkdir -p "${INSTANCE_DIR}/logs"
mkdir -p "${INSTANCE_DIR}/secrets"

# --- Optionen aus HA-Config lesen ---
TELEMETRY=$(jq -r '.telemetry // false' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

# --- JWT-Secret generieren (einmalig) ---
ENV_FILE="${INSTANCE_DIR}/.env"
if [ ! -f "${ENV_FILE}" ]; then
    echo "Generating JWT secret..."
    JWT_SECRET=$(openssl rand -hex 32)
    echo "PAPERCLIP_AGENT_JWT_SECRET=${JWT_SECRET}" > "${ENV_FILE}"
fi

# --- Master-Key generieren (einmalig) ---
MASTER_KEY="${INSTANCE_DIR}/secrets/master.key"
if [ ! -f "${MASTER_KEY}" ]; then
    echo "Generating master encryption key..."
    openssl rand -base64 32 > "${MASTER_KEY}"
    chmod 600 "${MASTER_KEY}"
fi

# --- Config generieren ---
# Config loeschen falls ungueltig, dann onboard laufen lassen
if [ -f "${INSTANCE_DIR}/config.json" ]; then
    if ! jq -e '."$meta"' "${INSTANCE_DIR}/config.json" > /dev/null 2>&1; then
        echo "Removing invalid config, will re-onboard..."
        rm -f "${INSTANCE_DIR}/config.json"
    fi
fi

if [ ! -f "${INSTANCE_DIR}/config.json" ]; then
    echo "Running initial onboard..."
    paperclipai onboard --yes
fi

# Config anpassen: Host auf 0.0.0.0 setzen fuer Ingress
if [ -f "${INSTANCE_DIR}/config.json" ]; then
    TMP=$(mktemp)
    jq '.server.host = "0.0.0.0" | .server.port = 3100' "${INSTANCE_DIR}/config.json" > "$TMP" && mv "$TMP" "${INSTANCE_DIR}/config.json"
fi

echo "========================================="
echo " Paperclip AI Add-on"
echo " Log Level: ${LOG_LEVEL}"
echo " Data Dir:  ${INSTANCE_DIR}"
echo " Port:      3100"
echo "========================================="

# --- Env-Variablen laden ---
export $(grep -v '^#' "${ENV_FILE}" | xargs)
export PAPERCLIP_HOME="${PAPERCLIP_HOME}"
export PAPERCLIP_INSTANCE="default"
export LOG_LEVEL="${LOG_LEVEL}"

# --- Paperclip starten ---
cd "${PAPERCLIP_HOME}"
exec paperclipai run
