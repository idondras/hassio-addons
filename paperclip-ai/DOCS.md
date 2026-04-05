# Paperclip AI — Home Assistant Add-on

## Installation

### 1. Dateien auf HA kopieren

Kopiere den Ordner `ha-addons` auf deinen Home Assistant Host.
Am einfachsten per **Samba-Share** (HA Add-on "Samba share" installieren):

```
\\<HA-IP>\addons\
```

Kopiere den gesamten `paperclip-ai`-Ordner dorthin, sodass die Struktur so aussieht:

```
/addons/paperclip-ai/
  config.yaml
  Dockerfile
  run.sh
  DOCS.md
```

### 2. Add-on installieren

1. **Einstellungen** > **Add-ons** > **Add-on Store**
2. Oben rechts: drei Punkte > **Repositories verwalten**
3. Falls der Ordner unter `/addons/` liegt, wird er automatisch erkannt — kein Repo hinzufuegen noetig
4. **Paperclip AI** sollte unter "Lokale Add-ons" erscheinen
5. Klicke darauf und dann **Installieren**

### 3. Starten

1. Nach der Installation: **Starten** klicken
2. Die UI ist ueber die HA-Seitenleiste erreichbar (Ingress)
3. Logs im Add-on-Tab pruefen

## Konfiguration

| Option     | Standard | Beschreibung                    |
|------------|----------|---------------------------------|
| telemetry  | false    | Telemetrie an/aus               |
| log_level  | info     | Log-Level (trace/debug/info/warn/error/fatal) |

## Daten

Alle Daten werden persistent unter `/data/paperclip/` gespeichert:

- `db/` — PostgreSQL-Datenbank
- `data/storage/` — Datei-Uploads
- `data/backups/` — Automatische DB-Backups (stundlich, 30 Tage)
- `logs/` — Server-Logs
- `secrets/` — Verschluesselungs-Keys

Die Daten werden bei HA-Backups mit gesichert.

## Ports

- **3100** — Web UI (standardmaessig nur via Ingress erreichbar)

## Troubleshooting

- **Add-on startet nicht**: Logs im Add-on-Tab pruefen
- **UI nicht erreichbar**: Sicherstellen, dass der Container laeuft (Add-on-Tab > Logs)
- **Datenbank-Fehler**: Add-on stoppen, unter `/data/paperclip/instances/default/db/` pruefen ob genug Speicher frei ist
