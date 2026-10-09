#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?alvo obrigatório}"
DRY_RUN="${2:-true}"
PROJECT="${FIREBASE_PROJECT:-qio-app}"

flags=(--project "$PROJECT" --non-interactive)
if [ "$DRY_RUN" = "true" ]; then
  flags+=(--dry-run)
fi

deploy() {
  echo "::group::firebase deploy --only $1 (dry_run=$DRY_RUN)"
  firebase deploy --only "$1" "${flags[@]}"
  echo "::endgroup::"
}

case "$TARGET" in
  functions) deploy functions ;;
  rules-rtdb) deploy database ;;
  rules-firestore) deploy firestore:rules ;;
  rules-storage) deploy storage ;;
  indexes) deploy firestore:indexes ;;
  hosting) deploy hosting ;;
  all-ordered)
    deploy firestore:indexes
    deploy functions
    echo "::notice::Backfill (functions/scripts/backfill-*.js) é manual: rode agora, se necessário (docs/deploy.md)."
    deploy hosting
    deploy database
    deploy firestore:rules
    deploy storage
    ;;
  *)
    echo "::error::Alvo desconhecido: $TARGET"
    exit 1
    ;;
esac
