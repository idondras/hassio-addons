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
cat > "${INSTANCE_DIR}/config.json" << EOF
{
  "database": {
    "provider": "embedded-postgres",
    "embeddedPostgres": {
      "dataDir": "${INSTANCE_DIR}/db",
      "port": 54329,
      "autoBackup": {
        "enabled": true,
        "intervalMinutes": 60,
        "retentionDays": 30,
        "backupDir": "${INSTANCE_DIR}/data/backups"
      }
    }
  },
  "logging": {
    "provider": "file",
    "file": {
      "directory": "${INSTANCE_DIR}/logs"
    }
  },
  "server": {
    "host": "0.0.0.0",
    "port": 3100,
    "deploymentMode": "local_trusted",
    "deploymentExposure": "private",
    "serveUi": true,
    "auth": {
      "baseUrlMode": "auto",
      "enableSignUp": true
    }
  },
  "storage": {
    "provider": "local_disk",
    "localDisk": {
      "baseDir": "${INSTANCE_DIR}/data/storage"
    }
  },
  "secrets": {
    "provider": "local_encrypted",
    "localEncrypted": {
      "keyFile": "${MASTER_KEY}",
      "strict": false
    }
  },
  "telemetry": {
    "enabled": ${TELEMETRY}
  }
}
EOF

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
