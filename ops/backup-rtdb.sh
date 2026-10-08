#!/usr/bin/env bash
# Backup do Realtime Database em JSON local (e, se BUCKET definido, copia para o bucket).
# O RTDB é espelho/estado transitório; o caminho recomendado é o backup automático do
# console (Blaze). Este script é o complemento manual (ex.: antes de mudar as rules).
#
# Uso:
#   PROJECT=qio-app [BUCKET=qio-app-backups] [OUT_DIR=./backups] ./ops/backup-rtdb.sh [--dry-run]
# Variáveis:
#   PROJECT   id do projeto (obrigatório)
#   BUCKET    se definido, copia o arquivo (gzip) para gs://BUCKET/rtdb/
#   OUT_DIR   pasta local de saída (padrão ./backups, fora do git)
#   INSTANCE  instância RTDB (padrão: a default do projeto)
# Requer firebase-tools logado (firebase login ou GOOGLE_APPLICATION_CREDENTIALS).
# O arquivo contém PII (nome/telefone das entries): não commite nem compartilhe.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ops/lib.sh
source "$HERE/lib.sh"

usage() {
  sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args "$@"
require_var PROJECT
OUT_DIR="${OUT_DIR:-./backups}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="$OUT_DIR/rtdb-$PROJECT-$STAMP.json"

require_cmd firebase
[[ -z "${BUCKET:-}" ]] || require_cmd gcloud

run mkdir -p "$OUT_DIR"
GET=(firebase database:get / --project "$PROJECT" --output "$FILE")
[[ -z "${INSTANCE:-}" ]] || GET+=(--instance "$INSTANCE")
run "${GET[@]}"

if [[ "$DRY_RUN" != true ]]; then
  [[ -s "$FILE" ]] || die "backup vazio: $FILE"
fi

run gzip -f "$FILE"

if [[ -n "${BUCKET:-}" ]]; then
  run gcloud storage cp "$FILE.gz" "gs://$BUCKET/rtdb/" --project="$PROJECT"
fi
echo "backup: $FILE.gz"
