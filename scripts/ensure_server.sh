#!/usr/bin/env bash
# Verifica que Open Carrusel responda en api_url (config.json).
# Si no responde, lo levanta en background y espera hasta 90 s.
# Sale 0 si está listo, 1 si no levanta.

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${CAROUSEL_CONFIG:-$SKILL_DIR/config.json}"
[ -f "$CONFIG" ] || CONFIG="$SKILL_DIR/config.example.json"

# En Windows `python3` suele ser el atajo de la Microsoft Store, que no corre:
# se usa el primer intérprete que de verdad ejecuta.
PY=""
for c in python3 python py; do "$c" -c '' 2>/dev/null && PY=$c && break; done
[ -n "$PY" ] || { echo "ERROR: no hay Python que corra (probé python3, python, py)" >&2; exit 1; }

# tr quita el \r que Python escribe en Windows; si no, la ruta acaba en \r y no existe.
read -r API_URL OC_DIR < <("$PY" - "$CONFIG" <<'PY' | tr -d '\r'
import json, os, sys
cfg = json.load(open(sys.argv[1]))
api = cfg.get("api_url", "http://localhost:3000").rstrip("/")
oc = os.path.expanduser(cfg.get("open_carrusel_dir", "~/open-carrusel"))
print(api, oc)
PY
)

if curl -sf -o /dev/null --max-time 2 "$API_URL/api/brand" 2>/dev/null; then
  echo "ready (already up) $API_URL"
  exit 0
fi

if [ ! -d "$OC_DIR" ]; then
  echo "ERROR: $OC_DIR no existe. Clonar Open Carrusel: git clone https://github.com/Hainrixz/open-carrusel $OC_DIR" >&2
  exit 1
fi

if [ ! -d "$OC_DIR/node_modules" ]; then
  echo "ERROR: $OC_DIR/node_modules no existe. Ejecutar 'npm install' en $OC_DIR" >&2
  exit 1
fi

LOG="${TMPDIR:-/tmp}/open-carrusel-dev.log"
echo "Levantando Open Carrusel en background (log: $LOG)..."
cd "$OC_DIR"
nohup npm run dev > "$LOG" 2>&1 &
SERVER_PID=$!
disown $SERVER_PID 2>/dev/null || true

for _ in $(seq 1 45); do
  if curl -sf -o /dev/null --max-time 2 "$API_URL/api/brand" 2>/dev/null; then
    echo "ready (started, pid=$SERVER_PID) $API_URL"
    exit 0
  fi
  sleep 2
done

echo "ERROR: el server no respondió en 90 s. Revisar $LOG" >&2
exit 1
