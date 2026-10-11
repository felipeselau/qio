#!/usr/bin/env bash
# Para os emuladores iniciados por ops/demo-up.sh (só o PID registrado por ele).
# Com --clean também apaga .demo-data/ e a config gerada.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${DEMO_DATA_DIR:-$ROOT/.demo-data}"
PIDFILE="$DATA_DIR/emulators.pid"

if [ -f "$PIDFILE" ]; then
  pid="$(cat "$PIDFILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill -INT "$pid"
    for _ in $(seq 1 60); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.5
    done
    echo "Emuladores (PID $pid) parados."
  else
    echo "PID $pid não está mais ativo."
  fi
  rm -f "$PIDFILE"
else
  echo "Nenhum $PIDFILE: nada para parar (o script não encerra processos de terceiros)."
fi

if [ "${1:-}" = "--clean" ]; then
  rm -rf "$DATA_DIR" "$ROOT/.firebase.demo.generated.json"
  echo "Dados demo removidos."
fi
