#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════
# Paperclip AI — Home Assistant Add-on Startskript
# ═══════════════════════════════════════════════════════

# Paperclip Home = persistent HA data volume
export PAPERCLIP_HOME="/data/paperclip"
export HOME="/root"

# --- Optionen aus HA-Config lesen ---
TELEMETRY=$(jq -r '.telemetry // false' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

# --- Onboard falls noch nicht geschehen ---
INSTANCE_DIR="${PAPERCLIP_HOME}/instances/default"
CONFIG_FILE="${INSTANCE_DIR}/config.json"

# Symlink ~/.paperclip -> /data/paperclip damit onboard dort schreibt
ln -sfn "${PAPERCLIP_HOME}" "${HOME}/.paperclip"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Running initial onboard..."
    paperclipai onboard --yes
fi

# Config anpassen: Host auf 0.0.0.0 und Postgres-User erstellen (root Container)
if [ -f "${CONFIG_FILE}" ]; then
    TMP=$(mktemp)
    jq '.server.host = "0.0.0.0" | .server.port = 3100 | .database.embeddedPostgres.createPostgresUser = true' "${CONFIG_FILE}" > "$TMP" && mv "$TMP" "${CONFIG_FILE}"
fi

# --- Env-Variablen laden ---
ENV_FILE="${INSTANCE_DIR}/.env"
if [ -f "${ENV_FILE}" ]; then
    export $(grep -v '^#' "${ENV_FILE}" | xargs)
fi
export LOG_LEVEL="${LOG_LEVEL}"

echo "========================================="
echo " Paperclip AI Add-on"
echo " Log Level: ${LOG_LEVEL}"
echo " Data Dir:  ${INSTANCE_DIR}"
echo " Port:      3100"
echo "========================================="

# --- Paperclip starten ---
cd "${PAPERCLIP_HOME}"
exec paperclipai run
