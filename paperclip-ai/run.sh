#!/bin/bash

# ═══════════════════════════════════════════════════════
# Paperclip AI — Home Assistant Add-on Startskript
# ═══════════════════════════════════════════════════════

export PAPERCLIP_HOME="/data/paperclip"
export HOME="/root"

TELEMETRY=$(jq -r '.telemetry // false' /data/options.json)
LOG_LEVEL=$(jq -r '.log_level // "info"' /data/options.json)

# Symlink damit onboard nach /data/paperclip schreibt
ln -sfn "${PAPERCLIP_HOME}" "${HOME}/.paperclip"

INSTANCE_DIR="${PAPERCLIP_HOME}/instances/default"
CONFIG_FILE="${INSTANCE_DIR}/config.json"

# ── Config-Validierung: bei ungueltigem deploymentMode neu erstellen ──
if [ -f "${CONFIG_FILE}" ]; then
    # Prüfe ob deploymentMode gültig ist (local_trusted oder authenticated)
    MODE=$(jq -r '.server.deploymentMode // "unknown"' "${CONFIG_FILE}" 2>/dev/null)
    echo "Current deploymentMode: ${MODE}"
    if [ "${MODE}" != "local_trusted" ] && [ "${MODE}" != "authenticated" ]; then
        echo "Invalid deploymentMode '${MODE}', removing config for fresh onboard..."
        rm -f "${CONFIG_FILE}"
    fi
fi

# ── Onboard falls keine Config vorhanden ──
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Running paperclipai onboard..."
    paperclipai onboard --yes
fi

# ── Config patchen für HA-Umgebung ──
if [ -f "${CONFIG_FILE}" ]; then
    echo "Patching config for HA (host=0.0.0.0, authenticated, createPostgresUser)..."
    TMP=$(mktemp)
    if jq '
      .server.host = "0.0.0.0" |
      .server.port = 3100 |
      .server.deploymentMode = "authenticated" |
      .database.embeddedPostgres.createPostgresUser = true
    ' "${CONFIG_FILE}" > "$TMP" 2>/dev/null; then
        mv "$TMP" "${CONFIG_FILE}"
        echo "  -> jq patch OK"
    else
        rm -f "$TMP"
        echo "  -> jq patch failed, using sed..."
        sed -i 's/"host":"127\.0\.0\.1"/"host":"0.0.0.0"/g' "${CONFIG_FILE}"
        sed -i 's/"deploymentMode":"local_trusted"/"deploymentMode":"authenticated"/g' "${CONFIG_FILE}"
        if ! grep -q "createPostgresUser" "${CONFIG_FILE}"; then
            sed -i '/"embeddedPostgres"/s/{/{"createPostgresUser":true,/' "${CONFIG_FILE}"
        fi
    fi
    echo "  -> deploymentMode: $(jq -r '.server.deploymentMode' "${CONFIG_FILE}" 2>/dev/null)"
    echo "  -> host: $(jq -r '.server.host' "${CONFIG_FILE}" 2>/dev/null)"
    echo "  -> createPostgresUser: $(jq -r '.database.embeddedPostgres.createPostgresUser' "${CONFIG_FILE}" 2>/dev/null)"
fi

# ── Env laden ──
ENV_FILE="${INSTANCE_DIR}/.env"
if [ -f "${ENV_FILE}" ]; then
    set -a
    . "${ENV_FILE}"
    set +a
fi
export LOG_LEVEL="${LOG_LEVEL}"

echo "========================================="
echo " Paperclip AI Add-on v1.1.3"
echo " Log Level: ${LOG_LEVEL}"
echo " Data Dir:  ${INSTANCE_DIR}"
echo " Port:      3100"
echo "========================================="

cd "${PAPERCLIP_HOME}"
exec paperclipai run
