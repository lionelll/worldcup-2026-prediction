#!/usr/bin/env python3
"""Validate input CSV files for the 2026 World Cup prediction report.

The validator enforces the two fixed execution parameters:
1. World Cup schedule data must use the real schedule schema.
2. Historical training data must be real match-result data cut off at 2026-06-10.
"""

from __future__ import annotations

import argparse
import csv
from datetime import date, datetime
from pathlib import Path
from typing import Iterable


SCHEDULE_REQUIRED = [
    "match_id",
    "stage",
    "group",
    "match_date",
    "team_1",
    "team_2",
    "venue",
    "host_country",
    "team_1_slot",
    "team_2_slot",
]

HISTORY_REQUIRED = [
    "date",
    "home_team",
    "away_team",
    "home_score",
    "away_score",
    "tournament",
    "country",
    "neutral",
]

GROUPS_REQUIRED = ["group", "slot", "team"]

CUTOFF = date(2026, 6, 10)
TRAIN_START = date(2010, 1, 1)
TRAIN_END = date(2024, 12, 31)
TEST_START = date(2025, 1, 1)
TEST_END = CUTOFF


def parse_date(value: str, field: str, row_number: int) -> date:
    try:
        return datetime.strptime(value.strip(), "%Y-%m-%d").date()
    except ValueError as exc:
        raise ValueError(f"row {row_number}: invalid {field} '{value}', expected YYYY-MM-DD") from exc


def read_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise ValueError(f"{path} has no header row")
        rows = list(reader)
        return list(reader.fieldnames), rows


def require_columns(path: Path, columns: Iterable[str], required: list[str]) -> None:
    missing = [column for column in required if column not in columns]
    if missing:
        raise ValueError(f"{path} is missing required columns: {', '.join(missing)}")


def validate_schedule(path: Path) -> None:
    columns, rows = read_rows(path)
    require_columns(path, columns, SCHEDULE_REQUIRED)
    if not rows:
        raise ValueError(f"{path} contains no schedule rows")

    stages = set()
    groups = set()
    for idx, row in enumerate(rows, start=2):
        match_date = parse_date(row["match_date"], "match_date", idx)
        if match_date < date(2026, 1, 1):
            raise ValueError(f"row {idx}: match_date predates 2026")
        stages.add(row["stage"].strip())
        if row["group"].strip():
            groups.add(row["group"].strip())
        for field in ["match_id", "stage", "team_1", "team_2", "venue", "host_country"]:
            if not row[field].strip():
                raise ValueError(f"row {idx}: {field} must not be empty")

    if "group" not in stages:
        raise ValueError("schedule must include group-stage rows with stage='group'")
    expected_groups = set("ABCDEFGHIJKL")
    if groups and not groups.issubset(expected_groups):
        invalid = ", ".join(sorted(groups - expected_groups))
        raise ValueError(f"schedule contains invalid group labels: {invalid}")


def validate_groups(path: Path) -> None:
    columns, rows = read_rows(path)
    require_columns(path, columns, GROUPS_REQUIRED)
    if len(rows) != 48:
        raise ValueError(f"{path} must contain exactly 48 teams, found {len(rows)}")

    expected_groups = set("ABCDEFGHIJKL")
    group_counts: dict[str, int] = {}
    teams: set[str] = set()
    for idx, row in enumerate(rows, start=2):
        group = row["group"].strip()
        slot = row["slot"].strip()
        team = row["team"].strip()
        if group not in expected_groups:
            raise ValueError(f"row {idx}: invalid group '{group}'")
        if not slot.startswith(group):
            raise ValueError(f"row {idx}: slot '{slot}' must start with group '{group}'")
        if not team:
            raise ValueError(f"row {idx}: team must not be empty")
        if team in teams:
            raise ValueError(f"row {idx}: duplicate team '{team}'")
        teams.add(team)
        group_counts[group] = group_counts.get(group, 0) + 1

    missing_groups = expected_groups - set(group_counts)
    if missing_groups:
        raise ValueError(f"missing groups: {', '.join(sorted(missing_groups))}")
    bad_groups = {group: count for group, count in group_counts.items() if count != 4}
    if bad_groups:
        details = ", ".join(f"{group}={count}" for group, count in sorted(bad_groups.items()))
        raise ValueError(f"each group must contain 4 teams; invalid counts: {details}")


def validate_history(path: Path) -> None:
    columns, rows = read_rows(path)
    require_columns(path, columns, HISTORY_REQUIRED)
    if not rows:
        raise ValueError(f"{path} contains no historical match rows")

    train_count = 0
    test_count = 0
    for idx, row in enumerate(rows, start=2):
        match_date = parse_date(row["date"], "date", idx)
        if match_date > CUTOFF:
            raise ValueError(f"row {idx}: match date {match_date} is after cutoff {CUTOFF}")
        if TRAIN_START <= match_date <= TRAIN_END:
            train_count += 1
        if TEST_START <= match_date <= TEST_END:
            test_count += 1
        for field in ["home_team", "away_team", "tournament", "country"]:
            if not row[field].strip():
                raise ValueError(f"row {idx}: {field} must not be empty")
        for field in ["home_score", "away_score"]:
            try:
                score = int(row[field])
            except ValueError as exc:
                raise ValueError(f"row {idx}: {field} must be an integer") from exc
            if score < 0:
                raise ValueError(f"row {idx}: {field} must be non-negative")
        neutral = row["neutral"].strip().lower()
        if neutral not in {"true", "false", "1", "0", "yes", "no"}:
            raise ValueError(f"row {idx}: neutral must be boolean-like")

    if train_count == 0:
        raise ValueError("history data has no training rows in 2010-01-01..2024-12-31")
    if test_count == 0:
        raise ValueError("history data has no test rows in 2025-01-01..2026-06-10")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--groups", type=Path, default=Path("data/worldcup_2026_groups.csv"))
    parser.add_argument("--schedule", type=Path, default=Path("data/worldcup_2026_schedule.csv"))
    parser.add_argument("--history", type=Path, default=Path("data/historical_matches.csv"))
    args = parser.parse_args()

    validate_groups(args.groups)
    validate_schedule(args.schedule)
    validate_history(args.history)
    print("Input validation passed.")
    print(f"Groups: {args.groups}")
    print(f"Schedule: {args.schedule}")
    print(f"History: {args.history}")
    print(f"Date cutoff: {CUTOFF.isoformat()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
