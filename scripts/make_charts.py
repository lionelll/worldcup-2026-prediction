#!/usr/bin/env python3
"""Generate SVG charts from worldcup_predictor.py CSV outputs.

No external plotting library is required. The charts are intentionally simple
and suitable for insertion into the course report after model results are
generated.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = PROJECT_ROOT / "output"
DEFAULT_APPROVAL = PROJECT_ROOT / "data" / "data_approval.csv"


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def approved_value(value: str) -> bool:
    return str(value).strip().lower() in {"true", "1", "yes", "y", "approved"}


def enforce_data_approval(path: Path, allow_unconfirmed: bool) -> None:
    if allow_unconfirmed:
        print("WARNING: --allow-unconfirmed-data enabled. Generated charts are for debugging only.")
        return
    required = {
        "worldcup_2026_groups.csv",
        "worldcup_2026_schedule.csv",
        "worldcup_2026_results_asof_2026-06-15.csv",
        "historical_matches.csv",
        "annex_c_full_mapping",
    }
    if not path.exists():
        raise SystemExit(f"Data approval file not found: {path}")
    rows = read_csv(path)
    approval = {row.get("file", ""): approved_value(row.get("approved", "")) for row in rows}
    missing = sorted(required - set(approval))
    pending = sorted(name for name in required if not approval.get(name, False))
    if missing or pending:
        blocked = missing + pending
        raise SystemExit(
            "Data source confirmation required before formal chart generation: "
            + ", ".join(blocked)
            + ". Use --allow-unconfirmed-data only for debugging."
        )


def svg_text(x: float, y: float, text: str, size: int = 12, anchor: str = "start", weight: str = "normal") -> str:
    escaped = (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    return f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" font-family="Arial, sans-serif" text-anchor="{anchor}" font-weight="{weight}">{escaped}</text>'


def bar_chart(rows: list[dict[str, str]], value_field: str, title: str, out_path: Path, color: str = "#2E74B5") -> None:
    width, height = 900, 520
    margin_left, margin_right, margin_top, margin_bottom = 170, 60, 60, 70
    plot_w = width - margin_left - margin_right
    plot_h = height - margin_top - margin_bottom
    values = [float(row[value_field]) for row in rows]
    max_value = max(values) if values else 1.0
    bar_h = plot_h / max(len(rows), 1) * 0.62
    gap = plot_h / max(len(rows), 1) * 0.38
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="white"/>',
        svg_text(width / 2, 34, title, 20, "middle", "bold"),
        f'<line x1="{margin_left}" y1="{margin_top + plot_h}" x2="{margin_left + plot_w}" y2="{margin_top + plot_h}" stroke="#888"/>',
    ]
    for idx, row in enumerate(rows):
        y = margin_top + idx * (bar_h + gap)
        value = float(row[value_field])
        bar_w = 0 if max_value == 0 else plot_w * value / max_value
        team = row["team"]
        parts.append(svg_text(margin_left - 10, y + bar_h * 0.68, team, 12, "end"))
        parts.append(f'<rect x="{margin_left}" y="{y:.1f}" width="{bar_w:.1f}" height="{bar_h:.1f}" fill="{color}" rx="2"/>')
        parts.append(svg_text(margin_left + bar_w + 8, y + bar_h * 0.68, f"{value * 100:.1f}%", 12))
        if "ci_lower" in row and "ci_upper" in row:
            low = float(row["ci_lower"])
            high = float(row["ci_upper"])
            x_low = margin_left + (plot_w * low / max_value if max_value else 0)
            x_high = margin_left + (plot_w * high / max_value if max_value else 0)
            y_mid = y + bar_h / 2
            parts.append(f'<line x1="{x_low:.1f}" y1="{y_mid:.1f}" x2="{x_high:.1f}" y2="{y_mid:.1f}" stroke="#222" stroke-width="1.4"/>')
            parts.append(f'<line x1="{x_low:.1f}" y1="{y_mid - 5:.1f}" x2="{x_low:.1f}" y2="{y_mid + 5:.1f}" stroke="#222" stroke-width="1.4"/>')
            parts.append(f'<line x1="{x_high:.1f}" y1="{y_mid - 5:.1f}" x2="{x_high:.1f}" y2="{y_mid + 5:.1f}" stroke="#222" stroke-width="1.4"/>')
    parts.append("</svg>")
    out_path.write_text("\n".join(parts), encoding="utf-8")


def progression_chart(rows: list[dict[str, str]], out_path: Path, top_n: int = 8) -> None:
    stages = ["round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion"]
    labels = ["出线", "16强", "8强", "四强", "决赛", "夺冠"]
    ordered = sorted(rows, key=lambda row: float(row["champion"]), reverse=True)[:top_n]
    width, height = 980, 560
    margin_left, margin_right, margin_top, margin_bottom = 90, 190, 70, 80
    plot_w = width - margin_left - margin_right
    plot_h = height - margin_top - margin_bottom
    colors = ["#2E74B5", "#70AD47", "#ED7D31", "#A64D79", "#5B9BD5", "#FFC000", "#4472C4", "#9E480E"]
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="white"/>',
        svg_text(width / 2, 34, "热门球队晋级概率阶梯图", 20, "middle", "bold"),
    ]
    for idx, label in enumerate(labels):
        x = margin_left + plot_w * idx / (len(labels) - 1)
        parts.append(f'<line x1="{x:.1f}" y1="{margin_top}" x2="{x:.1f}" y2="{margin_top + plot_h}" stroke="#E6E8EB"/>')
        parts.append(svg_text(x, margin_top + plot_h + 30, label, 12, "middle"))
    for tick in [0, 0.25, 0.5, 0.75, 1.0]:
        y = margin_top + plot_h * (1 - tick)
        parts.append(f'<line x1="{margin_left}" y1="{y:.1f}" x2="{margin_left + plot_w}" y2="{y:.1f}" stroke="#F0F1F3"/>')
        parts.append(svg_text(margin_left - 8, y + 4, f"{tick * 100:.0f}%", 11, "end"))
    for team_idx, row in enumerate(ordered):
        color = colors[team_idx % len(colors)]
        points = []
        for idx, stage in enumerate(stages):
            x = margin_left + plot_w * idx / (len(stages) - 1)
            y = margin_top + plot_h * (1 - float(row[stage]))
            points.append((x, y))
        path = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
        parts.append(f'<polyline points="{path}" fill="none" stroke="{color}" stroke-width="2.2"/>')
        for x, y in points:
            parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.5" fill="{color}"/>')
        legend_y = margin_top + team_idx * 24
        parts.append(f'<rect x="{margin_left + plot_w + 35}" y="{legend_y - 10}" width="12" height="12" fill="{color}"/>')
        parts.append(svg_text(margin_left + plot_w + 54, legend_y, row["team"], 12))
    parts.append("</svg>")
    out_path.write_text("\n".join(parts), encoding="utf-8")


def funnel_chart(rows: list[dict[str, str]], out_path: Path) -> None:
    ordered = sorted(rows, key=lambda row: float(row["champion"]), reverse=True)
    if not ordered:
        return
    row = ordered[0]
    stages = [
        ("round_of_32", "出线"),
        ("round_of_16", "16强"),
        ("quarter_final", "8强"),
        ("semi_final", "四强"),
        ("final", "决赛"),
        ("champion", "夺冠"),
    ]
    width, height = 760, 500
    center = width / 2
    top_y = 75
    layer_h = 55
    max_w = 560
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="white"/>',
        svg_text(width / 2, 34, f"{row['team']} 单队晋级漏斗图", 20, "middle", "bold"),
    ]
    for idx, (stage, label) in enumerate(stages):
        value = float(row[stage])
        w = max(18, max_w * value)
        y = top_y + idx * (layer_h + 8)
        parts.append(f'<rect x="{center - w / 2:.1f}" y="{y:.1f}" width="{w:.1f}" height="{layer_h}" fill="#2E74B5" opacity="{0.88 - idx * 0.08:.2f}" rx="4"/>')
        parts.append(svg_text(center, y + 34, f"{label} {value * 100:.1f}%", 14, "middle", "bold"))
    parts.append("</svg>")
    out_path.write_text("\n".join(parts), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate SVG charts from model outputs.")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--approval", default=str(DEFAULT_APPROVAL))
    parser.add_argument("--allow-unconfirmed-data", action="store_true")
    args = parser.parse_args()
    enforce_data_approval(Path(args.approval), args.allow_unconfirmed_data)
    output = Path(args.output)
    chart_dir = output / "figures"
    chart_dir.mkdir(parents=True, exist_ok=True)

    champion = read_csv(output / "champion_probabilities.csv")
    final_four = read_csv(output / "final_four_probabilities.csv")
    stages = read_csv(output / "team_stage_probabilities.csv")
    bar_chart(champion, "probability", "冠军概率 Top 10", chart_dir / "champion_probability_top10.svg", "#2E74B5")
    bar_chart(final_four, "probability", "四强概率 Top 10", chart_dir / "final_four_probability_top10.svg", "#70AD47")
    progression_chart(stages, chart_dir / "advancement_progression.svg")
    funnel_chart(stages, chart_dir / "top_team_funnel.svg")
    print(f"Charts written to {chart_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
