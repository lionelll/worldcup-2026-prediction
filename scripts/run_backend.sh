#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-formal}"

case "$MODE" in
  formal|validate) ;;
  *)
    echo "用法: $0 [formal|validate]" >&2
    exit 2
    ;;
esac

cd "$ROOT/backend"

if [[ "$MODE" == "formal" ]]; then
  Rscript R/validate_inputs.R
  Rscript R/worldcup_predictor.R
  Rscript R/make_charts.R
else
  Rscript R/validate_inputs.R --allow-unconfirmed-data
  Rscript R/worldcup_predictor.R --allow-unconfirmed-data
  Rscript R/make_charts.R --allow-unconfirmed-data
fi

Rscript R/test_route_outputs.R --output output
"$ROOT/scripts/sync_frontend_data.sh"
echo "后端计算、输出校验和前端数据同步完成。"
