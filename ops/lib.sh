#!/usr/bin/env bash
# Funções comuns dos scripts de ops. Use com: source "$(dirname "$0")/lib.sh"

DRY_RUN=false
ARGS=()

parse_args() {
  local a
  for a in "$@"; do
    case "$a" in
      --dry-run) DRY_RUN=true ;;
      -h|--help) usage; exit 0 ;;
      *) ARGS+=("$a") ;;
    esac
  done
}

die() {
  echo "erro: $*" >&2
  exit 1
}

require_var() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "defina a variável $name (veja --help)"
}

require_cmd() {
  local c="$1"
  if command -v "$c" >/dev/null 2>&1; then
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    echo "aviso: '$c' não encontrado (ignorado em --dry-run)" >&2
    return 0
  fi
  die "comando '$c' não encontrado no PATH"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}
