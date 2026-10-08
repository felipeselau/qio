#!/usr/bin/env bash
# Restaura um backup do Firestore em um NOVO banco, para validar o backup.
# Nunca restaura sobre o banco de produção: o destino é sempre um banco novo e o
# script recusa o nome '(default)'.
#
# Uso:
#   PROJECT=qio-app LOCATION=<região do banco> ./ops/restore-firestore-test.sh [--dry-run] list
#   PROJECT=qio-app LOCATION=<região> BACKUP_ID=<id> ./ops/restore-firestore-test.sh [--dry-run] restore
#   PROJECT=qio-app ./ops/restore-firestore-test.sh status
#   PROJECT=qio-app ./ops/restore-firestore-test.sh delete [--yes]
# Variáveis:
#   PROJECT        projeto que contém o backup (obrigatório)
#   LOCATION       região do backup, ex. southamerica-east1 (obrigatório em list/restore)
#   BACKUP_ID      id do backup (veja 'list')
#   DEST_DATABASE  banco novo de destino (padrão restore-test)
# 'delete' apaga o banco de teste e pede para digitar o nome (salvo --yes).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ops/lib.sh
source "$HERE/lib.sh"

usage() {
  sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args "$@"
MODE="${ARGS[0]:-}"
YES=false
[[ "${ARGS[1]:-}" == "--yes" ]] && YES=true

require_var PROJECT
DEST_DATABASE="${DEST_DATABASE:-restore-test}"
[[ "$DEST_DATABASE" != "(default)" ]] || die "DEST_DATABASE não pode ser '(default)'"

require_cmd gcloud

case "$MODE" in
  list)
    require_var LOCATION
    run gcloud firestore backups list --project="$PROJECT" --location="$LOCATION" \
      --format="table(name, database, state)"
    ;;
  restore)
    require_var LOCATION
    require_var BACKUP_ID
    run gcloud firestore databases restore --project="$PROJECT" \
      --source-backup="projects/$PROJECT/locations/$LOCATION/backups/$BACKUP_ID" \
      --destination-database="$DEST_DATABASE"
    echo "acompanhe: $0 status"
    echo "depois valide com o checklist de docs/backup.md e rode: $0 delete"
    ;;
  status)
    run gcloud firestore operations list --project="$PROJECT" --database="$DEST_DATABASE"
    ;;
  delete)
    if [[ "$YES" != true && "$DRY_RUN" != true ]]; then
      read -r -p "Apagar o banco '$DEST_DATABASE' em $PROJECT? Digite o nome para confirmar: " ans
      [[ "$ans" == "$DEST_DATABASE" ]] || die "confirmação não confere"
    fi
    run gcloud firestore databases delete --project="$PROJECT" --database="$DEST_DATABASE"
    ;;
  *)
    usage
    die "modo desconhecido: '${MODE}' (use list|restore|status|delete)"
    ;;
esac
