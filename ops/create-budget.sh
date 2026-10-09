#!/usr/bin/env bash
# Cria o orçamento mensal com alertas em 50%, 90% e 100% do gasto real.
#
# Uso:
#   PROJECT=qio-app BILLING_ACCOUNT=XXXXXX-XXXXXX-XXXXXX ./ops/create-budget.sh [--dry-run]
# Variáveis:
#   PROJECT          id do projeto filtrado pelo orçamento (obrigatório)
#   BILLING_ACCOUNT  id da conta de faturamento (obrigatório)
#   AMOUNT           valor mensal (padrão 20)
#   CURRENCY         moeda; deve ser a da conta de faturamento (padrão BRL)
#   DISPLAY_NAME     padrão "qio mensal"
# Requer a API billingbudgets.googleapis.com e o papel Billing Account Costs Manager
# (ou Administrator) na conta. O e-mail de alerta vai aos administradores da conta.
# Orçamento só ALERTA; não limita nem desliga o gasto.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ops/lib.sh
source "$HERE/lib.sh"

usage() {
  sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args "$@"
require_var PROJECT
require_var BILLING_ACCOUNT
AMOUNT="${AMOUNT:-20}"
CURRENCY="${CURRENCY:-BRL}"
DISPLAY_NAME="${DISPLAY_NAME:-qio mensal}"

[[ "$AMOUNT" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "AMOUNT inválido: $AMOUNT"
[[ "$CURRENCY" =~ ^[A-Z]{3}$ ]] || die "CURRENCY inválida: $CURRENCY"

require_cmd gcloud

run gcloud billing budgets create \
  --billing-account="$BILLING_ACCOUNT" \
  --display-name="$DISPLAY_NAME" \
  --budget-amount="${AMOUNT}${CURRENCY}" \
  --calendar-period=month \
  --filter-projects="projects/$PROJECT" \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0
