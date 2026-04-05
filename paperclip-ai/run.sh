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
# EINMALIG: Config loeschen wegen v1.0.8 Bug (deploymentMode=private)
FIXFLAG="/data/paperclip/.config_fixed_v110"
if [ ! -f "${FIXFLAG}" ]; then
    echo "One-time config reset for v1.1.x..."
    rm -f "${CONFIG_FILE}"
    touch "${FIXFLAG}"
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Running initial onboard..."
    paperclipai onboard --yes
fi

# --- Config patchen: Host 0.0.0.0 + createPostgresUser ---
if [ -f "${CONFIG_FILE}" ]; then
    echo "Patching config for HA environment..."

    # jq-basiertes Patching fuer flache Config-Struktur
    TMP=$(mktemp)
    jq '
      .server.host = "0.0.0.0" |
      .server.port = 3100 |
      .server.deploymentMode = "authenticated" |
      .database.embeddedPostgres.createPostgresUser = true
    ' "${CONFIG_FILE}" > "$TMP" && mv "$TMP" "${CONFIG_FILE}"

    echo "Config patched: host=0.0.0.0, mode=authenticated, createPostgresUser=true"
    echo "Verify deploymentMode: $(jq -r '.server.deploymentMode' "${CONFIG_FILE}" 2>/dev/null)"
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
