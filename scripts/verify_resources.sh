#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-validate}"

case "$MODE" in
  formal|validate) ;;
  *)
    echo "用法: $0 [formal|validate]" >&2
    exit 2
    ;;
esac

command -v Rscript >/dev/null 2>&1 || { echo "缺少 Rscript" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "缺少 python3" >&2; exit 1; }

REQUIRED=(
  backend/R/worldcup_predictor.R
  backend/R/validate_inputs.R
  backend/R/test_route_outputs.R
  backend/R/make_charts.R
  backend/data/historical_matches.csv
  backend/data/worldcup_2026_groups.csv
  backend/data/worldcup_2026_schedule.csv
  backend/data/worldcup_2026_results_asof_2026-06-20.csv
  backend/data/data_approval.csv
  frontend/index.html
  frontend/app.js
  frontend/styles.css
  frontend/data/team_route_nodes.csv
  frontend/data/bracket_slot_probabilities.csv
  frontend/data/group_position_probabilities.csv
  frontend/data/team_stage_probabilities.csv
  frontend/data/current_group_status.csv
  frontend/data/run_metadata.csv
  frontend/data/data_quality_audit.csv
  frontend/data/poisson_fit_statistics.csv
  frontend/data/poisson_model_comparison.csv
  frontend/data/rolling_origin_validation.csv
  frontend/data/logistic_metrics.csv
  frontend/data/worldcup_2026_schedule.csv
)

for path in "${REQUIRED[@]}"; do
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "缺少必要资源: $path" >&2
    exit 1
  fi
done

if [[ "$MODE" == "formal" && ! -f "$ROOT/backend/data/annex_c_full_mapping.csv" ]]; then
  echo "正式模式缺少: backend/data/annex_c_full_mapping.csv" >&2
  exit 1
fi

cd "$ROOT/backend"
if [[ "$MODE" == "formal" ]]; then
  Rscript R/validate_inputs.R
else
  Rscript R/validate_inputs.R --allow-unconfirmed-data
fi

echo "资源检查通过（${MODE}）。"
