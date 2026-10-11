#!/usr/bin/env bash
# Sobe os emuladores do Qio com o universo demo (issue #236). Só emulator:
# nunca usa credenciais nem toca o projeto de produção.
#
# Uso: ops/demo-up.sh [--reuse] [-- <args do seed, ex.: --days 90 --reset>]
#   --reuse  reaproveita .demo-data/export (pula o seed) se ele existir
#
# Portas (env): DEMO_PORT_AUTH=9099 DEMO_PORT_FIRESTORE=8080 DEMO_PORT_DATABASE=9000
#   DEMO_PORT_STORAGE=9199 DEMO_PORT_FUNCTIONS=5001 DEMO_PORT_HUB=4400
#   DEMO_PORT_LOGGING=4500 DEMO_PORT_EVENTARC=9299 DEMO_PORT_FIRESTORE_WS=9150. DEMO_HOST (padrão localhost),
#   DEMO_DATA_DIR (padrão .demo-data), DEMO_EXPORT_ON_EXIT=1 persiste ao sair.
# O app Flutter e a web do cliente usam as portas padrão; mude só para testes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export CI=true
export GIT_TERMINAL_PROMPT=0

PROJECT="${DEMO_PROJECT_ID:-qio-app}"
HOST="${DEMO_HOST:-localhost}"
DATA_DIR="${DEMO_DATA_DIR:-$ROOT/.demo-data}"
EXPORT_DIR="$DATA_DIR/export"
CONFIG="$ROOT/.firebase.demo.generated.json"
PIDFILE="$DATA_DIR/emulators.pid"

PORT_AUTH="${DEMO_PORT_AUTH:-9099}"
PORT_FIRESTORE="${DEMO_PORT_FIRESTORE:-8080}"
PORT_DATABASE="${DEMO_PORT_DATABASE:-9000}"
PORT_STORAGE="${DEMO_PORT_STORAGE:-9199}"
PORT_FUNCTIONS="${DEMO_PORT_FUNCTIONS:-5001}"
PORT_HUB="${DEMO_PORT_HUB:-4400}"
PORT_LOGGING="${DEMO_PORT_LOGGING:-4500}"
PORT_EVENTARC="${DEMO_PORT_EVENTARC:-9299}"
PORT_FS_WS="${DEMO_PORT_FIRESTORE_WS:-9150}"

REUSE=0
SEED_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --reuse) REUSE=1 ;;
    --) shift; SEED_ARGS=("$@"); break ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

for tool in firebase node java; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Faltando '$tool' no PATH." >&2; exit 1; }
done
[ -d functions/node_modules ] || { echo "Rode 'npm ci' em functions/ antes (o seed e as functions emuladas precisam das dependências)." >&2; exit 1; }

port_busy() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
  else
    (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
  fi
}

check_ports() {
  local busy=0
  for entry in "auth:$PORT_AUTH" "firestore:$PORT_FIRESTORE" "database:$PORT_DATABASE" "storage:$PORT_STORAGE" \
    "functions:$PORT_FUNCTIONS" "hub:$PORT_HUB" "logging:$PORT_LOGGING" "eventarc:$PORT_EVENTARC" "firestore-ws:$PORT_FS_WS"; do
    local name="${entry%%:*}" port="${entry##*:}"
    if port_busy "$port"; then
      echo "Porta $port ($name) já está em uso:" >&2
      lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | sed 's/^/  /' >&2 || true
      busy=1
    fi
  done
  if [ "$busy" -ne 0 ]; then
    echo "Libere as portas ou defina outras (DEMO_PORT_AUTH, DEMO_PORT_FIRESTORE, DEMO_PORT_DATABASE, DEMO_PORT_STORAGE, DEMO_PORT_FUNCTIONS, DEMO_PORT_HUB, DEMO_PORT_LOGGING, DEMO_PORT_EVENTARC, DEMO_PORT_FIRESTORE_WS). Este script não encerra processos de terceiros." >&2
    exit 1
  fi
}

write_config() {
  mkdir -p "$DATA_DIR"
  PORT_AUTH="$PORT_AUTH" PORT_FIRESTORE="$PORT_FIRESTORE" PORT_DATABASE="$PORT_DATABASE" \
    PORT_STORAGE="$PORT_STORAGE" PORT_FUNCTIONS="$PORT_FUNCTIONS" PORT_HUB="$PORT_HUB" \
    PORT_LOGGING="$PORT_LOGGING" PORT_EVENTARC="$PORT_EVENTARC" PORT_FS_WS="$PORT_FS_WS" DEMO_HOST_SET="${DEMO_HOST:-}" \
    node -e '
const fs = require("fs");
const cfg = JSON.parse(fs.readFileSync("firebase.json", "utf8"));
const host = process.env.DEMO_HOST_SET;
const port = (name) => Number(process.env[name]);
const em = {
  auth: { port: port("PORT_AUTH") },
  firestore: { port: port("PORT_FIRESTORE"), websocketPort: port("PORT_FS_WS") },
  database: { port: port("PORT_DATABASE") },
  storage: { port: port("PORT_STORAGE") },
  functions: { port: port("PORT_FUNCTIONS") },
  hub: { port: port("PORT_HUB") },
  logging: { port: port("PORT_LOGGING") },
  eventarc: { port: port("PORT_EVENTARC") },
  ui: { enabled: false },
  singleProjectMode: true,
};
if (host) for (const k of Object.keys(em)) if (em[k] && typeof em[k] === "object" && "port" in em[k]) em[k].host = host;
cfg.emulators = em;
fs.writeFileSync(process.argv[1], JSON.stringify(cfg, null, 2));
' "$CONFIG"
}

wait_port() {
  local port="$1" name="$2" tries=0
  until port_busy "$port"; do
    tries=$((tries + 1))
    if [ "$tries" -gt 240 ]; then
      echo "Timeout aguardando $name na porta $port. Veja $DATA_DIR/*.log" >&2
      return 1
    fi
    sleep 0.5
  done
}

SEED_PID=""
stop_seed_emulators() {
  if [ -n "$SEED_PID" ] && kill -0 "$SEED_PID" 2>/dev/null; then
    kill -INT "$SEED_PID" 2>/dev/null || true
    for _ in $(seq 1 60); do
      kill -0 "$SEED_PID" 2>/dev/null || break
      sleep 0.5
    done
    kill -0 "$SEED_PID" 2>/dev/null && kill -TERM "$SEED_PID" 2>/dev/null || true
  fi
  SEED_PID=""
}
trap stop_seed_emulators EXIT

check_ports
write_config

FB=(firebase --project "$PROJECT" --config "$CONFIG" --non-interactive)

if [ "$REUSE" -eq 1 ] && [ -d "$EXPORT_DIR" ]; then
  echo "Reaproveitando $EXPORT_DIR (sem seed)."
else
  rm -rf "$EXPORT_DIR"
  echo "Fase 1: subindo auth/firestore/database/storage para o seed..."
  "${FB[@]}" emulators:start --only auth,firestore,database,storage >"$DATA_DIR/emulators-seed.log" 2>&1 &
  SEED_PID=$!
  wait_port "$PORT_AUTH" auth
  wait_port "$PORT_FIRESTORE" firestore
  wait_port "$PORT_DATABASE" database
  wait_port "$PORT_STORAGE" storage
  wait_port "$PORT_HUB" hub

  echo "Rodando o seed..."
  FIRESTORE_EMULATOR_HOST="$HOST:$PORT_FIRESTORE" \
    FIREBASE_AUTH_EMULATOR_HOST="$HOST:$PORT_AUTH" \
    FIREBASE_DATABASE_EMULATOR_HOST="$HOST:$PORT_DATABASE" \
    DEMO_PROJECT_ID="$PROJECT" \
    node functions/scripts/demo/index.js ${SEED_ARGS[@]+"${SEED_ARGS[@]}"}

  echo "Exportando para $EXPORT_DIR..."
  "${FB[@]}" emulators:export "$EXPORT_DIR" --force
  stop_seed_emulators
  for port in "$PORT_AUTH" "$PORT_FIRESTORE" "$PORT_DATABASE" "$PORT_STORAGE" "$PORT_HUB"; do
    tries=0
    while port_busy "$port" && [ "$tries" -lt 60 ]; do tries=$((tries + 1)); sleep 0.5; done
  done
fi

EXTRA=()
[ "${DEMO_EXPORT_ON_EXIT:-0}" = "1" ] && EXTRA+=(--export-on-exit "$EXPORT_DIR")

trap - EXIT
echo $$ >"$PIDFILE"
echo "Fase 2: emuladores completos (inclui functions) com --import. Ctrl-C para parar."
echo "Contas e roteiro: docs/demo/README.md"
exec "${FB[@]}" emulators:start --only auth,firestore,database,storage,functions --import "$EXPORT_DIR" ${EXTRA[@]+"${EXTRA[@]}"}
