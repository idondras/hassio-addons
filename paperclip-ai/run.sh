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

    # Erst pruefen was drin ist
    echo "Current config keys:"
    jq 'keys' "${CONFIG_FILE}" 2>/dev/null || true

    # Patch anwenden
    TMP=$(mktemp)
    if jq '
      .server.host = "0.0.0.0" |
      .server.port = 3100 |
      .database.embeddedPostgres.createPostgresUser = true
    ' "${CONFIG_FILE}" > "$TMP" 2>/dev/null; then
        mv "$TMP" "${CONFIG_FILE}"
        echo "Config patched successfully."
    else
        echo "WARNING: jq patch failed, trying sed fallback..."
        rm -f "$TMP"
        # Fallback: sed fuer createPostgresUser
        if ! grep -q "createPostgresUser" "${CONFIG_FILE}"; then
            sed -i 's/"embeddedPostgres":{/"embeddedPostgres":{"createPostgresUser":true,/' "${CONFIG_FILE}"
        fi
        # Host patchen
        sed -i 's/"host":"127.0.0.1"/"host":"0.0.0.0"/' "${CONFIG_FILE}"
    fi

    # Verifizieren
    echo "createPostgresUser value:"
    jq '.database.embeddedPostgres.createPostgresUser' "${CONFIG_FILE}" 2>/dev/null || echo "MISSING"
    echo "server.host value:"
    jq '.server.host' "${CONFIG_FILE}" 2>/dev/null || echo "MISSING"
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
