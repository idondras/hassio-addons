#!/bin/bash

# ═══════════════════════════════════════════════════════
# Paperclip AI — Home Assistant Add-on Startskript
# ═══════════════════════════════════════════════════════

# Paperclip Home = persistent HA data volume
export PAPERCLIP_HOME="/data/paperclip"
export HOME="/root"

# --- Optionen aus HA-Config lesen ---
TELEMETRY=$(jq -r '.telemetry // false' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

# Symlink ~/.paperclip -> /data/paperclip damit onboard dort schreibt
ln -sfn "${PAPERCLIP_HOME}" "${HOME}/.paperclip"

INSTANCE_DIR="${PAPERCLIP_HOME}/instances/default"
CONFIG_FILE="${INSTANCE_DIR}/config.json"

# --- Onboard falls noch nicht geschehen ---
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Running initial onboard..."
    paperclipai onboard --yes
fi

# --- Config patchen: Host 0.0.0.0 + createPostgresUser ---
if [ -f "${CONFIG_FILE}" ]; then
    echo "Patching config for HA environment..."

    echo "Config structure before patch:"
    cat "${CONFIG_FILE}" | head -5
    echo "..."

    # Sed-basiertes Patching (zuverlaessiger als jq bei unbekannter Struktur)
    # 1. Host auf 0.0.0.0
    sed -i 's/"host"[[:space:]]*:[[:space:]]*"127\.0\.0\.1"/"host":"0.0.0.0"/g' "${CONFIG_FILE}"
    # 2. deploymentMode auf private statt local_trusted
    sed -i 's/"deploymentMode"[[:space:]]*:[[:space:]]*"local_trusted"/"deploymentMode":"private"/g' "${CONFIG_FILE}"
    # 3. createPostgresUser hinzufuegen
    if ! grep -q "createPostgresUser" "${CONFIG_FILE}"; then
        sed -i 's/"embeddedPostgres"[[:space:]]*:[[:space:]]*{/"embeddedPostgres":{"createPostgresUser":true,/g' "${CONFIG_FILE}"
    fi

    echo "Config after patch (first 200 chars):"
    head -c 200 "${CONFIG_FILE}"
    echo ""
    echo "createPostgresUser present: $(grep -c createPostgresUser "${CONFIG_FILE}")"
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
