#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$ROOT/backend/output"
TARGET="$ROOT/frontend/data"

FILES=(
  team_route_nodes.csv
  bracket_slot_probabilities.csv
  group_position_probabilities.csv
  team_stage_probabilities.csv
  current_group_status.csv
  run_metadata.csv
  data_quality_audit.csv
  poisson_fit_statistics.csv
  poisson_model_comparison.csv
  rolling_origin_validation.csv
  logistic_metrics.csv
)

mkdir -p "$TARGET"
for file in "${FILES[@]}"; do
  if [[ ! -f "$OUTPUT/$file" ]]; then
    echo "缺少后端输出: backend/output/$file" >&2
    exit 1
  fi
  cp "$OUTPUT/$file" "$TARGET/$file"
done

SCHEDULE="$ROOT/backend/data/worldcup_2026_schedule.csv"
if [[ ! -f "$SCHEDULE" ]]; then
  echo "缺少赛程文件: backend/data/worldcup_2026_schedule.csv" >&2
  exit 1
fi
cp "$SCHEDULE" "$TARGET/worldcup_2026_schedule.csv"

echo "前端数据已同步。"
