#!/usr/bin/env bash
# Backup do Firestore: agenda backups gerenciados (diário + semanal) e, opcionalmente,
# faz um export manual para o bucket.
#
# Uso:
#   PROJECT=qio-app BUCKET=qio-app-backups ./ops/backup-firestore.sh [--dry-run] <modo>
# Modos:
#   schedule  cria as agendas (diária 7d e semanal 8w) no banco (padrão)
#   export    export manual para gs://BUCKET/firestore/<timestamp> (requer BUCKET)
#   list      lista agendas e backups existentes
# Variáveis:
#   PROJECT           id do projeto (obrigatório)
#   BUCKET            bucket do export manual, sem gs:// (obrigatório no modo export)
#   DATABASE          padrão '(default)'
#   DAILY_RETENTION   padrão 7d (máximo 14w)
#   WEEKLY_RETENTION  padrão 8w (máximo 14w)
#   WEEKLY_DAY        padrão SUN
#   ENABLE_PITR       true para habilitar point-in-time recovery (7 dias; tem custo)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ops/lib.sh
source "$HERE/lib.sh"

usage() {
  sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args "$@"
MODE="${ARGS[0]:-schedule}"

require_var PROJECT
DATABASE="${DATABASE:-(default)}"
DAILY_RETENTION="${DAILY_RETENTION:-7d}"
WEEKLY_RETENTION="${WEEKLY_RETENTION:-8w}"
WEEKLY_DAY="${WEEKLY_DAY:-SUN}"
ENABLE_PITR="${ENABLE_PITR:-false}"

require_cmd gcloud

case "$MODE" in
  schedule)
    run gcloud firestore backups schedules create \
      --project="$PROJECT" --database="$DATABASE" \
      --recurrence=daily --retention="$DAILY_RETENTION"
    run gcloud firestore backups schedules create \
      --project="$PROJECT" --database="$DATABASE" \
      --recurrence=weekly --day-of-week="$WEEKLY_DAY" --retention="$WEEKLY_RETENTION"
    if [[ "$ENABLE_PITR" == true ]]; then
      run gcloud firestore databases update \
        --project="$PROJECT" --database="$DATABASE" --enable-pitr
    fi
    run gcloud firestore backups schedules list \
      --project="$PROJECT" --database="$DATABASE"
    ;;
  export)
    require_var BUCKET
    STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
    run gcloud firestore export "gs://$BUCKET/firestore/$STAMP" \
      --project="$PROJECT" --database="$DATABASE" --async
    echo "acompanhe: gcloud firestore operations list --project=$PROJECT --database='$DATABASE'"
    ;;
  list)
    run gcloud firestore backups schedules list \
      --project="$PROJECT" --database="$DATABASE"
    run gcloud firestore backups list --project="$PROJECT" \
      --format="table(name, database, state)"
    ;;
  *)
    usage
    die "modo desconhecido: $MODE"
    ;;
esac
