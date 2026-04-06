#!/bin/bash

# ═══════════════════════════════════════════════════════
# Paperclip AI — Home Assistant Add-on Startskript
# ═══════════════════════════════════════════════════════

PAPERCLIP_HOME="/data/paperclip"
INSTANCE_DIR="${PAPERCLIP_HOME}/instances/default"
CONFIG_FILE="${INSTANCE_DIR}/config.json"

# --- Optionen aus HA-Config lesen ---
TELEMETRY=$(jq -r '.telemetry // false' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

# --- Verzeichnisse vorbereiten (als root, bevor wir zu paperclip wechseln) ---
mkdir -p "${PAPERCLIP_HOME}"
chown -R paperclip:paperclip "${PAPERCLIP_HOME}"

# Symlink ~/.paperclip -> /data/paperclip fuer den paperclip User
PAPERCLIP_USER_HOME=$(getent passwd paperclip | cut -d: -f6)
mkdir -p "${PAPERCLIP_USER_HOME}"
ln -sfn "${PAPERCLIP_HOME}" "${PAPERCLIP_USER_HOME}/.paperclip"
chown -h paperclip:paperclip "${PAPERCLIP_USER_HOME}/.paperclip"

# --- Config-Validierung: bei ungueltigem deploymentMode neu erstellen ---
if [ -f "${CONFIG_FILE}" ]; then
    MODE=$(jq -r '.server.deploymentMode // "unknown"' "${CONFIG_FILE}" 2>/dev/null)
    if [ "${MODE}" != "local_trusted" ] && [ "${MODE}" != "authenticated" ]; then
        echo "Invalid deploymentMode '${MODE}', removing for fresh onboard..."
        rm -f "${CONFIG_FILE}"
    fi
fi

# --- Onboard als paperclip User ---
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Running paperclipai onboard..."
    su-exec paperclip env NODE_OPTIONS="--experimental-require-module" paperclipai onboard --yes
fi

# --- Config patchen fuer HA (host 0.0.0.0, authenticated mode) ---
if [ -f "${CONFIG_FILE}" ]; then
    echo "Patching config for HA environment..."
    TMP=$(mktemp)
    if jq '
      .server.host = "0.0.0.0" |
      .server.port = 3100 |
      .server.deploymentMode = "authenticated"
    ' "${CONFIG_FILE}" > "$TMP" 2>/dev/null; then
        mv "$TMP" "${CONFIG_FILE}"
        chown paperclip:paperclip "${CONFIG_FILE}"
    else
        rm -f "$TMP"
    fi
    echo "  -> deploymentMode: $(jq -r '.server.deploymentMode' "${CONFIG_FILE}" 2>/dev/null)"
    echo "  -> host: $(jq -r '.server.host' "${CONFIG_FILE}" 2>/dev/null)"
fi

# --- Env laden ---
ENV_FILE="${INSTANCE_DIR}/.env"
EXPORT_VARS=""
if [ -f "${ENV_FILE}" ]; then
    EXPORT_VARS=$(grep -v '^#' "${ENV_FILE}" | xargs)
fi

echo "========================================="
echo " Paperclip AI Add-on v1.3.1"
echo " Log Level: ${LOG_LEVEL}"
echo " Data Dir:  ${INSTANCE_DIR}"
echo " User:      paperclip (non-root)"
echo " Port:      3100"
echo "========================================="

# --- Paperclip als non-root User starten ---
cd "${PAPERCLIP_HOME}"
exec su-exec paperclip env ${EXPORT_VARS} LOG_LEVEL="${LOG_LEVEL}" HOME="${PAPERCLIP_USER_HOME}" NODE_OPTIONS="--experimental-require-module" paperclipai run
