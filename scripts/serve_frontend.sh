#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-8000}"

REQUIRED=(
  index.html
  app.js
  styles.css
  data/team_route_nodes.csv
  data/bracket_slot_probabilities.csv
  data/group_position_probabilities.csv
  data/team_stage_probabilities.csv
  data/current_group_status.csv
  data/run_metadata.csv
  data/data_quality_audit.csv
  data/poisson_fit_statistics.csv
  data/poisson_model_comparison.csv
  data/rolling_origin_validation.csv
  data/logistic_metrics.csv
  data/worldcup_2026_schedule.csv
)

for path in "${REQUIRED[@]}"; do
  if [[ ! -f "$ROOT/frontend/$path" ]]; then
    echo "缺少网页资源: frontend/$path" >&2
    exit 1
  fi
done

cd "$ROOT/frontend"
echo "网页地址: http://127.0.0.1:$PORT/"
python3 -m http.server "$PORT" --bind 127.0.0.1
