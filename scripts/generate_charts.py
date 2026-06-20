#!/usr/bin/env python3
"""Generate all charts for the report as PNG files."""

import csv
import os
import sys
from collections import Counter, defaultdict

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "output")
FIG_DIR = os.path.join(OUTPUT_DIR, "figures")
os.makedirs(FIG_DIR, exist_ok=True)
APPROVAL_PATH = os.path.join(PROJECT_ROOT, "data", "data_approval.csv")
plt = None
fm = None
np = None
FONT = None

def approved_value(value):
    return str(value).strip().lower() in {"true", "1", "yes", "y", "approved"}

def enforce_data_approval():
    if "--allow-unconfirmed-data" in sys.argv:
        print("WARNING: --allow-unconfirmed-data enabled. Generated charts are for debugging only.")
        return
    required = {
        "worldcup_2026_groups.csv",
        "worldcup_2026_schedule.csv",
        "worldcup_2026_results_asof_2026-06-15.csv",
        "historical_matches.csv",
        "annex_c_full_mapping",
    }
    if not os.path.exists(APPROVAL_PATH):
        raise SystemExit(f"Data approval file not found: {APPROVAL_PATH}")
    with open(APPROVAL_PATH, encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))
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

# --- Font setup for Chinese ---
def get_chinese_font():
    for name in ["PingFang SC", "Heiti SC", "STHeiti", "SimHei", "Arial Unicode MS"]:
        matches = [f for f in fm.fontManager.ttflist if name in f.name]
        if matches:
            return fm.FontProperties(fname=matches[0].fname)
    return fm.FontProperties()

def setup_plotting():
    global plt, fm, np, FONT
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as _plt
    import matplotlib.font_manager as _fm
    import numpy as _np

    plt = _plt
    fm = _fm
    np = _np
    FONT = get_chinese_font()
    plt.rcParams["axes.unicode_minus"] = False

def read_csv(filename):
    path = os.path.join(OUTPUT_DIR, filename) if not os.path.isabs(filename) else filename
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))

def read_history():
    path = os.path.join(PROJECT_ROOT, "data", "historical_matches.csv")
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))

# ========== Chart 1: Goal distribution histogram ==========
def chart_goal_distribution():
    history = read_history()
    home_goals = [int(r["home_score"]) for r in history]
    away_goals = [int(r["away_score"]) for r in history]
    all_single = home_goals + away_goals  # each team's goals per match
    total_goals = [h + a for h, a in zip(home_goals, away_goals)]

    fig, axes = plt.subplots(1, 2, figsize=(11, 4.5))

    axes[0].hist(all_single, bins=range(0, 12), edgecolor="black", color="#4472C4", alpha=0.8, align="left")
    axes[0].set_title("单队单场进球数分布", fontproperties=FONT, fontsize=13)
    axes[0].set_xlabel("进球数", fontproperties=FONT)
    axes[0].set_ylabel("频次", fontproperties=FONT)
    axes[0].axvline(np.mean(all_single), color="red", linestyle="--", label=f"均值={np.mean(all_single):.2f}")
    axes[0].legend(prop=FONT)

    axes[1].hist(total_goals, bins=range(0, 16), edgecolor="black", color="#70AD47", alpha=0.8, align="left")
    axes[1].set_title("每场比赛总进球数分布", fontproperties=FONT, fontsize=13)
    axes[1].set_xlabel("进球数", fontproperties=FONT)
    axes[1].set_ylabel("频次", fontproperties=FONT)
    axes[1].axvline(np.mean(total_goals), color="red", linestyle="--", label=f"均值={np.mean(total_goals):.2f}")
    axes[1].legend(prop=FONT)

    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig3_1_goal_distribution.png"), dpi=200)
    plt.close()
    print("  fig3_1_goal_distribution.png")

# ========== Chart 2: Matches per year (line chart) ==========
def chart_matches_per_year():
    history = read_history()
    years = [r["date"][:4] for r in history]
    cnt = Counter(years)
    sorted_years = sorted(cnt.keys())
    counts = [cnt[y] for y in sorted_years]

    fig, ax = plt.subplots(figsize=(10, 4.5))
    ax.plot(sorted_years, counts, marker="o", color="#4472C4", linewidth=2, markersize=5)
    ax.fill_between(sorted_years, counts, alpha=0.15, color="#4472C4")
    ax.set_title("各年度比赛数量趋势", fontproperties=FONT, fontsize=14)
    ax.set_xlabel("年份", fontproperties=FONT)
    ax.set_ylabel("比赛场次", fontproperties=FONT)
    ax.set_xticks(sorted_years[::2])
    ax.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig2_1_matches_per_year.png"), dpi=200)
    plt.close()
    print("  fig2_1_matches_per_year.png")

# ========== Chart 3: Tournament type pie chart ==========
def chart_tournament_types():
    history = read_history()
    types = []
    for r in history:
        t = r["tournament"].strip()
        lower = t.lower()
        if "friendly" in lower:
            types.append("友谊赛")
        elif "world cup" in lower and ("qualif" in lower or "Qualif" in lower):
            types.append("世界杯预选赛")
        elif "world cup" in lower:
            types.append("世界杯")
        elif "euro" in lower or "copa" in lower or "africa" in lower or "asian" in lower or "gold cup" in lower:
            types.append("洲际杯赛")
        elif "nations league" in lower:
            types.append("国家联赛")
        elif "qualif" in lower:
            types.append("预选赛")
        else:
            types.append("其他")

    cnt = Counter(types)
    labels = sorted(cnt.keys(), key=lambda x: -cnt[x])
    sizes = [cnt[l] for l in labels]
    colors = ["#4472C4", "#ED7D31", "#70AD47", "#FFC000", "#5B9BD5", "#A5A5A5", "#FF6B6B"]

    total = sum(sizes)
    percentages = [value / total * 100 for value in sizes]
    legend_labels = [f"{label}  {pct:.1f}%" for label, pct in zip(labels, percentages)]

    fig, ax = plt.subplots(figsize=(9, 5.4))
    wedges, texts, autotexts = ax.pie(
        sizes,
        autopct=lambda pct: f"{pct:.1f}%" if pct >= 5 else "",
        colors=colors[:len(labels)],
        startangle=90,
        pctdistance=0.72,
        wedgeprops={"width": 0.58, "edgecolor": "white", "linewidth": 1.2},
    )
    for t in autotexts:
        t.set_fontsize(10)
    ax.text(0, 0, f"{total:,}\n场比赛", ha="center", va="center",
            fontproperties=FONT, fontsize=12, color="#444444")
    ax.legend(wedges, legend_labels, loc="center left", bbox_to_anchor=(1, 0.5),
              prop=FONT, fontsize=10)
    ax.set_title("历史比赛赛事类型分布", fontproperties=FONT, fontsize=14)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig2_2_tournament_types.png"), dpi=200, bbox_inches="tight")
    plt.close()
    print("  fig2_2_tournament_types.png")

# ========== Chart 4: Win rate by Elo diff (line chart) ==========
def chart_elo_vs_winrate():
    history = read_history()
    # Simple Elo calculation
    elo = defaultdict(lambda: 1500.0)
    records = []  # (elo_diff, result)
    for r in history:
        h, a = r["home_team"], r["away_team"]
        hs, as_ = int(r["home_score"]), int(r["away_score"])
        diff = elo[h] - elo[a]
        result = 1 if hs > as_ else (0.5 if hs == as_ else 0)
        records.append((diff, result))
        # Update Elo
        exp = 1 / (1 + 10 ** (-diff / 400))
        k = 20
        elo[h] += k * (result - exp)
        elo[a] -= k * (result - exp)

    # Bin by elo_diff
    bins = list(range(-600, 601, 50))
    bin_wins = defaultdict(list)
    for diff, res in records:
        for i in range(len(bins) - 1):
            if bins[i] <= diff < bins[i + 1]:
                bin_wins[i].append(res)
                break

    x_vals, y_vals = [], []
    for i in range(len(bins) - 1):
        if len(bin_wins[i]) >= 20:
            x_vals.append((bins[i] + bins[i + 1]) / 2)
            y_vals.append(np.mean(bin_wins[i]))

    fig, ax = plt.subplots(figsize=(9, 5))
    ax.plot(x_vals, y_vals, marker="o", color="#4472C4", linewidth=2, markersize=4)
    ax.axhline(0.5, color="gray", linestyle="--", alpha=0.5)
    ax.axvline(0, color="gray", linestyle="--", alpha=0.5)
    ax.set_title("Elo 分差与先列队胜率关系（历史数据）", fontproperties=FONT, fontsize=14)
    ax.set_xlabel("Elo 分差（先列队 - 后列队）", fontproperties=FONT)
    ax.set_ylabel("先列队胜率", fontproperties=FONT)
    ax.set_ylim(0, 1)
    ax.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig3_2_elo_vs_winrate.png"), dpi=200)
    plt.close()
    print("  fig3_2_elo_vs_winrate.png")

# ========== Chart 5: Feature correlation heatmap ==========
def chart_correlation_heatmap():
    history = read_history()
    elo = defaultdict(lambda: 1500.0)
    form = defaultdict(list)  # team -> list of (gf, ga)

    data = {"elo_diff": [], "recent_wr_diff": [], "recent_gd_diff": [],
            "home_field": [], "result": []}

    for r in history:
        h, a = r["home_team"], r["away_team"]
        hs, as_ = int(r["home_score"]), int(r["away_score"])
        neutral = r.get("neutral", "FALSE").strip().upper() in ("TRUE", "1", "YES")

        # Features
        diff = elo[h] - elo[a]
        h_form = form[h][-10:] if form[h] else [(1, 1)]
        a_form = form[a][-10:] if form[a] else [(1, 1)]
        h_wr = np.mean([1 if g > l else 0 for g, l in h_form])
        a_wr = np.mean([1 if g > l else 0 for g, l in a_form])
        h_gd = np.mean([g - l for g, l in h_form])
        a_gd = np.mean([g - l for g, l in a_form])

        data["elo_diff"].append(diff)
        data["recent_wr_diff"].append(h_wr - a_wr)
        data["recent_gd_diff"].append(h_gd - a_gd)
        data["home_field"].append(0 if neutral else 1)
        data["result"].append(1 if hs > as_ else (0 if hs == as_ else -1))

        # Update
        exp = 1 / (1 + 10 ** (-diff / 400))
        actual = 1 if hs > as_ else (0.5 if hs == as_ else 0)
        elo[h] += 20 * (actual - exp)
        elo[a] -= 20 * (actual - exp)
        form[h].append((hs, as_))
        form[a].append((as_, hs))

    keys = ["elo_diff", "recent_wr_diff", "recent_gd_diff", "home_field", "result"]
    labels = ["Elo分差", "近期胜率差", "近期净胜球差", "主场优势", "比赛结果"]
    matrix = np.array([data[k] for k in keys])
    corr = np.corrcoef(matrix)

    fig, ax = plt.subplots(figsize=(7, 6))
    im = ax.imshow(corr, cmap="RdBu_r", vmin=-1, vmax=1)
    ax.set_xticks(range(len(labels)))
    ax.set_yticks(range(len(labels)))
    ax.set_xticklabels(labels, fontproperties=FONT, fontsize=10, rotation=30, ha="right")
    ax.set_yticklabels(labels, fontproperties=FONT, fontsize=10)
    for i in range(len(labels)):
        for j in range(len(labels)):
            ax.text(j, i, f"{corr[i, j]:.2f}", ha="center", va="center", fontsize=10,
                    color="white" if abs(corr[i, j]) > 0.5 else "black")
    ax.set_title("特征变量相关性热力图", fontproperties=FONT, fontsize=14)
    fig.colorbar(im, ax=ax, shrink=0.8)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig3_3_correlation_heatmap.png"), dpi=200)
    plt.close()
    print("  fig3_3_correlation_heatmap.png")

# ========== Chart 6: Champion probability bar chart ==========
def chart_champion_bar():
    champ = read_csv("champion_probabilities.csv")
    teams = [r["team"] for r in champ]
    probs = [float(r["probability"]) * 100 for r in champ]
    ci_lo = [float(r["ci_lower"]) * 100 for r in champ]
    ci_hi = [float(r["ci_upper"]) * 100 for r in champ]
    errors = [[p - lo for p, lo in zip(probs, ci_lo)], [hi - p for p, hi in zip(probs, ci_hi)]]

    fig, ax = plt.subplots(figsize=(10, 5.5))
    colors = ["#FFD700", "#C0C0C0", "#CD7F32"] + ["#4472C4"] * 7
    bars = ax.bar(range(len(teams)), probs, color=colors, edgecolor="black", linewidth=0.5)
    ax.errorbar(range(len(teams)), probs, yerr=errors, fmt="none", ecolor="black", capsize=4)
    ax.set_xticks(range(len(teams)))
    ax.set_xticklabels(teams, fontproperties=FONT, fontsize=11)
    ax.set_ylabel("夺冠概率 (%)", fontproperties=FONT, fontsize=12)
    ax.set_title("2026 世界杯冠军概率 Top 10（含95%置信区间）", fontproperties=FONT, fontsize=14)
    for i, (bar, p) in enumerate(zip(bars, probs)):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.5, f"{p:.1f}%",
                ha="center", fontsize=9)
    ax.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig6_1_champion_bar.png"), dpi=200)
    plt.close()
    print("  fig6_1_champion_bar.png")

# ========== Chart 7: Final four probability bar chart ==========
def chart_final_four_bar():
    four = read_csv("final_four_probabilities.csv")
    teams = [r["team"] for r in four]
    probs = [float(r["probability"]) * 100 for r in four]

    fig, ax = plt.subplots(figsize=(10, 5))
    bars = ax.barh(range(len(teams) - 1, -1, -1), probs, color="#5B9BD5", edgecolor="black", linewidth=0.5)
    ax.set_yticks(range(len(teams) - 1, -1, -1))
    ax.set_yticklabels(teams, fontproperties=FONT, fontsize=11)
    ax.set_xlabel("四强概率 (%)", fontproperties=FONT, fontsize=12)
    ax.set_title("2026 世界杯四强概率 Top 10", fontproperties=FONT, fontsize=14)
    for i, (bar, p) in enumerate(zip(bars, probs)):
        ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height() / 2, f"{p:.1f}%",
                va="center", fontsize=9)
    ax.grid(axis="x", alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig6_2_final_four_bar.png"), dpi=200)
    plt.close()
    print("  fig6_2_final_four_bar.png")

# ========== Chart 8: Top 5 teams progression funnel ==========
def chart_progression_funnel():
    stages_data = read_csv("team_stage_probabilities.csv")
    stage_cols = ["round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion"]
    stage_labels = ["32强", "16强", "8强", "4强", "决赛", "冠军"]

    # Top 5 by champion prob
    sorted_teams = sorted(stages_data, key=lambda x: -float(x["champion"]))[:5]

    fig, ax = plt.subplots(figsize=(10, 5.5))
    x = np.arange(len(stage_cols))
    width = 0.15
    colors = ["#4472C4", "#ED7D31", "#70AD47", "#FFC000", "#5B9BD5"]

    for i, team in enumerate(sorted_teams):
        vals = [float(team[s]) * 100 for s in stage_cols]
        ax.bar(x + i * width, vals, width, label=team["team"], color=colors[i], edgecolor="black", linewidth=0.3)

    ax.set_xticks(x + width * 2)
    ax.set_xticklabels(stage_labels, fontproperties=FONT, fontsize=11)
    ax.set_ylabel("晋级概率 (%)", fontproperties=FONT, fontsize=12)
    ax.set_title("Top 5 球队各阶段晋级概率", fontproperties=FONT, fontsize=14)
    ax.legend(prop=FONT, fontsize=10)
    ax.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig6_3_progression_funnel.png"), dpi=200)
    plt.close()
    print("  fig6_3_progression_funnel.png")

# ========== Chart 9: Single team funnel (line chart) ==========
def chart_single_team_funnel():
    stages_data = read_csv("team_stage_probabilities.csv")
    stage_cols = ["round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion"]
    stage_labels = ["32强", "16强", "8强", "4强", "决赛", "冠军"]

    sorted_teams = sorted(stages_data, key=lambda x: -float(x["champion"]))[:5]

    fig, ax = plt.subplots(figsize=(10, 5.5))
    colors = ["#4472C4", "#ED7D31", "#70AD47", "#FFC000", "#5B9BD5"]
    markers = ["o", "s", "D", "^", "v"]

    for i, team in enumerate(sorted_teams):
        vals = [float(team[s]) * 100 for s in stage_cols]
        ax.plot(stage_labels, vals, marker=markers[i], label=team["team"], color=colors[i],
                linewidth=2, markersize=7)

    ax.set_ylabel("晋级概率 (%)", fontproperties=FONT, fontsize=12)
    ax.set_title("热门球队晋级概率阶梯图", fontproperties=FONT, fontsize=14)
    ax.legend(prop=FONT, fontsize=10)
    ax.set_xticklabels(stage_labels, fontproperties=FONT)
    ax.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig6_4_team_funnel_line.png"), dpi=200)
    plt.close()
    print("  fig6_4_team_funnel_line.png")

# ========== Chart 10: Model coefficient bar chart ==========
def chart_coefficients():
    coefs = read_csv("model_coefficients.csv")
    features = []
    home_vals = []
    away_vals = []
    names = {
        "(Intercept)": "截距", "elo_diff": "Elo分差", "recent_win_rate_diff": "近期胜率差",
        "home_attack_vs_away_defense": "攻防对比(主)", "away_attack_vs_home_defense": "攻防对比(客)",
        "recent_goal_diff_diff": "净胜球差", "home_field": "主场优势",
        "host_country_diff": "东道主", "tournament_importance": "赛事权重",
    }
    for r in coefs:
        if r["feature"] == "(Intercept)":
            continue
        features.append(names.get(r["feature"], r["feature"]))
        home_vals.append(float(r["home_goal_coefficient"]))
        away_vals.append(float(r["away_goal_coefficient"]))

    fig, ax = plt.subplots(figsize=(10, 5))
    x = np.arange(len(features))
    w = 0.35
    ax.bar(x - w/2, home_vals, w, label="主队进球系数", color="#4472C4", edgecolor="black", linewidth=0.3)
    ax.bar(x + w/2, away_vals, w, label="客队进球系数", color="#ED7D31", edgecolor="black", linewidth=0.3)
    ax.set_xticks(x)
    ax.set_xticklabels(features, fontproperties=FONT, fontsize=9, rotation=20, ha="right")
    ax.set_ylabel("系数值", fontproperties=FONT, fontsize=12)
    ax.set_title("泊松回归模型系数对比", fontproperties=FONT, fontsize=14)
    ax.legend(prop=FONT)
    ax.axhline(0, color="black", linewidth=0.5)
    ax.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig5_1_coefficients.png"), dpi=200)
    plt.close()
    print("  fig5_1_coefficients.png")

# ========== Chart 11: Confusion matrix heatmap ==========
def chart_confusion_matrix():
    metrics = read_csv("model_metrics.csv")
    conf = {}
    for r in metrics:
        if r["metric"].startswith("confusion_"):
            conf[r["metric"]] = int(float(r["value"]))

    matrix = np.array([
        [conf.get("confusion_H_pred_H", 0), conf.get("confusion_H_pred_D", 0), conf.get("confusion_H_pred_A", 0)],
        [conf.get("confusion_D_pred_H", 0), conf.get("confusion_D_pred_D", 0), conf.get("confusion_D_pred_A", 0)],
        [conf.get("confusion_A_pred_H", 0), conf.get("confusion_A_pred_D", 0), conf.get("confusion_A_pred_A", 0)],
    ])
    labels = ["主胜(H)", "平局(D)", "客胜(A)"]

    fig, ax = plt.subplots(figsize=(6, 5))
    im = ax.imshow(matrix, cmap="Blues")
    ax.set_xticks(range(3))
    ax.set_yticks(range(3))
    ax.set_xticklabels([f"预测{l}" for l in labels], fontproperties=FONT, fontsize=10)
    ax.set_yticklabels([f"实际{l}" for l in labels], fontproperties=FONT, fontsize=10)
    for i in range(3):
        for j in range(3):
            ax.text(j, i, str(matrix[i, j]), ha="center", va="center", fontsize=14,
                    color="white" if matrix[i, j] > matrix.max() * 0.6 else "black")
    ax.set_title("混淆矩阵热力图", fontproperties=FONT, fontsize=14)
    fig.colorbar(im, ax=ax, shrink=0.8)
    plt.tight_layout()
    plt.savefig(os.path.join(FIG_DIR, "fig5_2_confusion_matrix.png"), dpi=200)
    plt.close()
    print("  fig5_2_confusion_matrix.png")

if __name__ == "__main__":
    enforce_data_approval()
    setup_plotting()
    print("Generating charts...")
    chart_matches_per_year()
    chart_tournament_types()
    chart_goal_distribution()
    chart_elo_vs_winrate()
    chart_correlation_heatmap()
    chart_coefficients()
    chart_confusion_matrix()
    chart_champion_bar()
    chart_final_four_bar()
    chart_progression_funnel()
    chart_single_team_funnel()
    print(f"All charts saved to {FIG_DIR}")
