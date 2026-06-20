#!/usr/bin/env python3
"""2026 World Cup probability model and Monte Carlo simulator.

This script is intentionally dependency-light: it uses only the Python standard
library so the project can be submitted and rerun in ordinary course-work
environments.

Inputs
------
Required:
  data/worldcup_2026_groups.csv
  data/worldcup_2026_schedule.csv
  data/historical_matches.csv

Optional:
  data/team_elo.csv
  data/worldcup_2026_results_asof_2026-06-17.csv

Outputs
-------
  output/team_stage_probabilities.csv
  output/champion_probabilities.csv
  output/final_four_probabilities.csv
  output/group_advancement_probabilities.csv
  output/model_metrics.csv
  output/asof_results_impact.csv

The implementation follows the report's modeling contract:
  - historical matches after 2026-06-10 are excluded;
  - rolling-form features are computed only from matches before each match;
  - Poisson goal model drives the tournament simulation;
  - observed 2026 group-stage results, if supplied, are used only for in-tournament
    state updates, not for training.
"""

from __future__ import annotations

import argparse
import csv
import math
import random
from collections import defaultdict, deque
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path
from statistics import mean
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GROUPS = PROJECT_ROOT / "data/worldcup_2026_groups.csv"
DEFAULT_SCHEDULE = PROJECT_ROOT / "data/worldcup_2026_schedule.csv"
DEFAULT_HISTORY = PROJECT_ROOT / "data/historical_matches.csv"
DEFAULT_ELO = PROJECT_ROOT / "data/team_elo.csv"
DEFAULT_RESULTS = PROJECT_ROOT / "data/worldcup_2026_results_asof_2026-06-17.csv"
DEFAULT_OUTPUT = PROJECT_ROOT / "output"
DEFAULT_APPROVAL = PROJECT_ROOT / "data/data_approval.csv"

DATE_CUTOFF = date(2026, 6, 10)
TRAIN_END = date(2024, 12, 31)
TEST_START = date(2025, 1, 1)
HOSTS = {"United States", "Canada", "Mexico"}
RANDOM_SEED = 20260615
DEFAULT_SIMULATIONS = 10_000
FORM_WINDOW = 10
MAX_GOALS = 10
LEARNING_RATE = 0.00025
RIDGE = 0.0005
EPOCHS = 450
CI_Z = 1.96


GROUP_STAGE_ORDER = ["group", "Group", "GROUP"]
STAGE_ORDER = [
    "group_exit",
    "round_of_32",
    "round_of_16",
    "quarter_final",
    "semi_final",
    "final",
    "champion",
]
STAGE_LABELS = {
    "group_exit": "小组未出线",
    "round_of_32": "32强",
    "round_of_16": "16强",
    "quarter_final": "8强",
    "semi_final": "四强",
    "final": "决赛",
    "champion": "冠军",
}


@dataclass
class TeamForm:
    matches: deque[tuple[int, int]] = field(default_factory=lambda: deque(maxlen=FORM_WINDOW))

    def features(self) -> tuple[float, float, float, float]:
        if not self.matches:
            return 0.33, 1.25, 1.25, 0.0
        wins = sum(1 for goals_for, goals_against in self.matches if goals_for > goals_against)
        goals_for_avg = mean(goals_for for goals_for, _ in self.matches)
        goals_against_avg = mean(goals_against for _, goals_against in self.matches)
        goal_diff_avg = mean(goals_for - goals_against for goals_for, goals_against in self.matches)
        return wins / len(self.matches), goals_for_avg, goals_against_avg, goal_diff_avg

    def add(self, goals_for: int, goals_against: int) -> None:
        self.matches.append((goals_for, goals_against))


@dataclass
class MatchSample:
    match_date: date
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    tournament: str
    country: str
    neutral: bool
    features: list[float]
    weight: float


@dataclass
class Model:
    coefficients_home: list[float]
    coefficients_away: list[float]
    feature_names: list[str]
    team_strength: dict[str, float]
    global_home_goals: float
    global_away_goals: float


@dataclass
class TeamStanding:
    team: str
    played: int = 0
    points: int = 0
    goals_for: int = 0
    goals_against: int = 0

    @property
    def goal_diff(self) -> int:
        return self.goals_for - self.goals_against


def parse_date(value: str) -> date:
    return datetime.strptime(value.strip(), "%Y-%m-%d").date()


def truthy(value: str) -> bool:
    return value.strip().lower() in {"true", "1", "yes", "y"}


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: Iterable[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def normalize_team(value: str) -> str:
    replacements = {
        "USA": "United States",
        "U.S.": "United States",
        "United States of America": "United States",
        "Korea Republic": "South Korea",
        "Czech Republic": "Czechia",
        "Türkiye": "Turkiye",
        "Turkey": "Turkiye",
        "Côte d'Ivoire": "Ivory Coast",
        "Cote d'Ivoire": "Ivory Coast",
        "Curaçao": "Curacao",
        "Cape Verde Islands": "Cape Verde",
        "DR Congo": "DR Congo",
        "Congo DR": "DR Congo",
        "Democratic Republic of the Congo": "DR Congo",
        "Bosnia-Herzegovina": "Bosnia and Herzegovina",
    }
    cleaned = " ".join(value.strip().split())
    return replacements.get(cleaned, cleaned)


def tournament_weight(tournament: str) -> float:
    lower = tournament.lower()
    if "world cup" in lower and "qualification" not in lower and "qualifier" not in lower:
        return 1.45
    if "continental" in lower or "euro" in lower or "copa" in lower or "africa cup" in lower:
        return 1.25
    if "qualification" in lower or "qualifier" in lower or "nations league" in lower:
        return 1.10
    if "friendly" in lower:
        return 0.65
    return 1.0


def load_groups(path: Path) -> dict[str, list[str]]:
    groups: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for row in read_csv(path):
        groups[row["group"].strip()].append((row["slot"].strip(), normalize_team(row["team"])))
    return {
        group: [team for _, team in sorted(entries, key=lambda item: item[0])]
        for group, entries in sorted(groups.items())
    }


def load_schedule(path: Path) -> list[dict[str, str]]:
    rows = read_csv(path)
    for row in rows:
        row["team_1"] = normalize_team(row["team_1"])
        row["team_2"] = normalize_team(row["team_2"])
    return sorted(rows, key=lambda row: (parse_date(row["match_date"]), row["match_id"]))


def load_results(path: Path | None) -> dict[tuple[str, str, str], tuple[int, int]]:
    if path is None or not path.exists():
        return {}
    observed: dict[tuple[str, str, str], tuple[int, int]] = {}
    for row in read_csv(path):
        group = row["group"].strip()
        team_1 = normalize_team(row["team_1"])
        team_2 = normalize_team(row["team_2"])
        score_1 = int(row["team_1_score"])
        score_2 = int(row["team_2_score"])
        observed[(group, team_1, team_2)] = (score_1, score_2)
        observed[(group, team_2, team_1)] = (score_2, score_1)
    return observed


def load_elo(path: Path | None) -> dict[str, float]:
    if path is None or not path.exists():
        return {}
    rows = read_csv(path)
    scores: dict[str, float] = {}
    for row in rows:
        team = normalize_team(row.get("team", ""))
        value = row.get("elo") or row.get("rating") or row.get("score")
        if team and value:
            scores[team] = float(value)
    return scores


def load_history(path: Path) -> list[dict[str, object]]:
    matches: list[dict[str, object]] = []
    for row in read_csv(path):
        match_date = parse_date(row["date"])
        if match_date > DATE_CUTOFF:
            continue
        matches.append(
            {
                "date": match_date,
                "home_team": normalize_team(row["home_team"]),
                "away_team": normalize_team(row["away_team"]),
                "home_score": int(row["home_score"]),
                "away_score": int(row["away_score"]),
                "tournament": row["tournament"].strip(),
                "country": row["country"].strip(),
                "neutral": truthy(row["neutral"]),
            }
        )
    return sorted(matches, key=lambda row: row["date"])


def infer_team_strength(matches: list[dict[str, object]], external_elo: dict[str, float]) -> dict[str, float]:
    teams = sorted({m["home_team"] for m in matches} | {m["away_team"] for m in matches} | set(external_elo))
    ratings = {team: float(external_elo.get(team, 1500.0)) for team in teams}
    k_base = 18.0

    for match in matches:
        home = str(match["home_team"])
        away = str(match["away_team"])
        home_score = int(match["home_score"])
        away_score = int(match["away_score"])
        neutral = bool(match["neutral"])
        home_advantage = 0.0 if neutral else 55.0
        expected_home = 1.0 / (1.0 + 10 ** (-(ratings[home] + home_advantage - ratings[away]) / 400.0))
        actual_home = 1.0 if home_score > away_score else 0.5 if home_score == away_score else 0.0
        margin_factor = max(1.0, math.log(abs(home_score - away_score) + 1.0) + 1.0)
        k = k_base * tournament_weight(str(match["tournament"])) * margin_factor
        delta = k * (actual_home - expected_home)
        ratings[home] += delta
        ratings[away] -= delta

    return ratings


def build_samples(matches: list[dict[str, object]], team_strength: dict[str, float]) -> list[MatchSample]:
    forms: dict[str, TeamForm] = defaultdict(TeamForm)
    samples: list[MatchSample] = []
    default_strength = mean(team_strength.values()) if team_strength else 1500.0

    for match in matches:
        home = str(match["home_team"])
        away = str(match["away_team"])
        home_form = forms[home].features()
        away_form = forms[away].features()
        home_elo = team_strength.get(home, default_strength)
        away_elo = team_strength.get(away, default_strength)
        neutral = bool(match["neutral"])
        host_home = 1.0 if home in HOSTS else 0.0
        host_away = 1.0 if away in HOSTS else 0.0
        features = [
            1.0,
            (home_elo - away_elo) / 400.0,
            home_form[0] - away_form[0],
            home_form[1] - away_form[2],
            away_form[1] - home_form[2],
            home_form[3] - away_form[3],
            0.0 if neutral else 1.0,
            host_home - host_away,
            tournament_weight(str(match["tournament"])) - 1.0,
        ]
        samples.append(
            MatchSample(
                match_date=match["date"],  # type: ignore[arg-type]
                home_team=home,
                away_team=away,
                home_score=int(match["home_score"]),
                away_score=int(match["away_score"]),
                tournament=str(match["tournament"]),
                country=str(match["country"]),
                neutral=neutral,
                features=features,
                weight=tournament_weight(str(match["tournament"])),
            )
        )
        forms[home].add(int(match["home_score"]), int(match["away_score"]))
        forms[away].add(int(match["away_score"]), int(match["home_score"]))

    return samples


def fit_poisson(samples: list[MatchSample], target: str) -> list[float]:
    if not samples:
        raise ValueError("no samples available for model fitting")
    n_features = len(samples[0].features)
    coefficients = [0.0] * n_features
    average_goals = mean(sample.home_score if target == "home" else sample.away_score for sample in samples)
    coefficients[0] = math.log(max(average_goals, 0.2))

    for _ in range(EPOCHS):
        gradient = [0.0] * n_features
        for sample in samples:
            y = sample.home_score if target == "home" else sample.away_score
            eta = sum(beta * x for beta, x in zip(coefficients, sample.features))
            eta = max(-3.0, min(3.0, eta))
            mu = math.exp(eta)
            error = (mu - y) * sample.weight
            for idx, value in enumerate(sample.features):
                gradient[idx] += error * value
        for idx in range(n_features):
            penalty = RIDGE * coefficients[idx] if idx else 0.0
            coefficients[idx] -= LEARNING_RATE * ((gradient[idx] / len(samples)) + penalty)
    return coefficients


def predict_goals(model: Model, team_1: str, team_2: str, neutral: bool = True, tournament_weight_value: float = 1.45) -> tuple[float, float]:
    default_strength = mean(model.team_strength.values()) if model.team_strength else 1500.0
    elo_1 = model.team_strength.get(team_1, default_strength)
    elo_2 = model.team_strength.get(team_2, default_strength)
    features = [
        1.0,
        (elo_1 - elo_2) / 400.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0 if neutral else 1.0,
        (1.0 if team_1 in HOSTS else 0.0) - (1.0 if team_2 in HOSTS else 0.0),
        tournament_weight_value - 1.0,
    ]
    eta_1 = sum(beta * x for beta, x in zip(model.coefficients_home, features))
    eta_2 = sum(beta * x for beta, x in zip(model.coefficients_away, features))
    lambda_1 = max(0.15, min(5.5, math.exp(max(-3.0, min(3.0, eta_1)))))
    lambda_2 = max(0.15, min(5.5, math.exp(max(-3.0, min(3.0, eta_2)))))
    return lambda_1, lambda_2


def poisson_pmf(lam: float, max_goals: int = MAX_GOALS) -> list[float]:
    probs = []
    for goals in range(max_goals + 1):
        probs.append(math.exp(-lam) * (lam ** goals) / math.factorial(goals))
    total = sum(probs)
    return [prob / total for prob in probs]


def sample_from_distribution(probs: list[float], rng: random.Random) -> int:
    threshold = rng.random()
    cumulative = 0.0
    for idx, prob in enumerate(probs):
        cumulative += prob
        if threshold <= cumulative:
            return idx
    return len(probs) - 1


def simulate_score(lambda_1: float, lambda_2: float, rng: random.Random) -> tuple[int, int]:
    return sample_from_distribution(poisson_pmf(lambda_1), rng), sample_from_distribution(poisson_pmf(lambda_2), rng)


def win_draw_loss_prob(lambda_1: float, lambda_2: float) -> tuple[float, float, float]:
    p1 = poisson_pmf(lambda_1)
    p2 = poisson_pmf(lambda_2)
    win = draw = loss = 0.0
    for g1, prob1 in enumerate(p1):
        for g2, prob2 in enumerate(p2):
            prob = prob1 * prob2
            if g1 > g2:
                win += prob
            elif g1 == g2:
                draw += prob
            else:
                loss += prob
    total = win + draw + loss
    return win / total, draw / total, loss / total


def train_model(history_path: Path, elo_path: Path | None) -> tuple[Model, list[dict[str, object]], list[dict[str, object]]]:
    matches = load_history(history_path)
    if not matches:
        raise ValueError("historical match file has no usable rows")
    external_elo = load_elo(elo_path)
    strength = infer_team_strength(matches, external_elo)
    samples = build_samples(matches, strength)
    train = [sample for sample in samples if sample.match_date <= TRAIN_END]
    test = [sample for sample in samples if TEST_START <= sample.match_date <= DATE_CUTOFF]
    if not train:
        raise ValueError("no training samples in 2010-01-01..2024-12-31")

    feature_names = [
        "intercept",
        "elo_diff",
        "recent_win_rate_diff",
        "home_attack_vs_away_defense",
        "away_attack_vs_home_defense",
        "recent_goal_diff_diff",
        "home_field",
        "host_country_diff",
        "tournament_importance",
    ]
    model = Model(
        coefficients_home=fit_poisson(train, "home"),
        coefficients_away=fit_poisson(train, "away"),
        feature_names=feature_names,
        team_strength=strength,
        global_home_goals=mean(sample.home_score for sample in train),
        global_away_goals=mean(sample.away_score for sample in train),
    )
    metrics = evaluate_model(model, test or train)
    coefficient_rows = coefficients_to_rows(model)
    return model, metrics, coefficient_rows


def evaluate_model(model: Model, samples: list[MatchSample]) -> list[dict[str, object]]:
    if not samples:
        return []
    correct = 0
    brier_values = []
    log_losses = []
    score_errors = []
    matrix: dict[tuple[str, str], int] = defaultdict(int)

    for sample in samples:
        lambda_home, lambda_away = predict_goals(model, sample.home_team, sample.away_team, neutral=sample.neutral)
        p_home, p_draw, p_away = win_draw_loss_prob(lambda_home, lambda_away)
        probs = {"H": p_home, "D": p_draw, "A": p_away}
        predicted = max(probs, key=probs.get)
        actual = "H" if sample.home_score > sample.away_score else "D" if sample.home_score == sample.away_score else "A"
        correct += int(predicted == actual)
        matrix[(actual, predicted)] += 1
        brier_values.append(sum((probs[label] - (1.0 if label == actual else 0.0)) ** 2 for label in ["H", "D", "A"]))
        log_losses.append(-math.log(max(probs[actual], 1e-12)))
        score_errors.append(abs(lambda_home - sample.home_score) + abs(lambda_away - sample.away_score))

    rows: list[dict[str, object]] = [
        {"metric": "samples", "value": len(samples)},
        {"metric": "accuracy", "value": round(correct / len(samples), 6)},
        {"metric": "brier_score", "value": round(mean(brier_values), 6)},
        {"metric": "log_loss", "value": round(mean(log_losses), 6)},
        {"metric": "mean_absolute_score_error", "value": round(mean(score_errors), 6)},
    ]
    for actual in ["H", "D", "A"]:
        for predicted in ["H", "D", "A"]:
            rows.append({"metric": f"confusion_{actual}_pred_{predicted}", "value": matrix[(actual, predicted)]})
    return rows


def coefficients_to_rows(model: Model) -> list[dict[str, object]]:
    rows = []
    for name, home_coef, away_coef in zip(model.feature_names, model.coefficients_home, model.coefficients_away):
        rows.append(
            {
                "feature": name,
                "home_goal_coefficient": round(home_coef, 6),
                "away_goal_coefficient": round(away_coef, 6),
            }
        )
    return rows


def generate_round_robin_schedule(groups: dict[str, list[str]]) -> list[dict[str, str]]:
    """Fallback group schedule when the official match-by-match CSV is not present.

    This is only used for code dry-runs. The report submission should replace it
    with FIFA's official schedule CSV.
    """

    rows: list[dict[str, str]] = []
    match_id = 1
    pairings = [(0, 1), (2, 3), (0, 2), (1, 3), (0, 3), (1, 2)]
    for group, teams in groups.items():
        for sequence, (left, right) in enumerate(pairings, start=1):
            rows.append(
                {
                    "match_id": f"G{match_id:03d}",
                    "stage": "group",
                    "group": group,
                    "match_date": f"2026-06-{10 + sequence:02d}",
                    "team_1": teams[left],
                    "team_2": teams[right],
                    "venue": "official_schedule_required",
                    "host_country": "official_schedule_required",
                    "team_1_slot": f"{group}{left + 1}",
                    "team_2_slot": f"{group}{right + 1}",
                }
            )
            match_id += 1
    return rows


def empty_standings(groups: dict[str, list[str]]) -> dict[str, dict[str, TeamStanding]]:
    return {group: {team: TeamStanding(team=team) for team in teams} for group, teams in groups.items()}


def apply_match(standings: dict[str, TeamStanding], team_1: str, team_2: str, score_1: int, score_2: int) -> None:
    standings[team_1].played += 1
    standings[team_2].played += 1
    standings[team_1].goals_for += score_1
    standings[team_1].goals_against += score_2
    standings[team_2].goals_for += score_2
    standings[team_2].goals_against += score_1
    if score_1 > score_2:
        standings[team_1].points += 3
    elif score_1 < score_2:
        standings[team_2].points += 3
    else:
        standings[team_1].points += 1
        standings[team_2].points += 1


def sorted_group(standings: dict[str, TeamStanding], rng: random.Random) -> list[TeamStanding]:
    randomized = list(standings.values())
    rng.shuffle(randomized)
    return sorted(randomized, key=lambda team: (team.points, team.goal_diff, team.goals_for), reverse=True)


def select_best_thirds(thirds: list[tuple[str, TeamStanding]], rng: random.Random) -> list[tuple[str, TeamStanding]]:
    randomized = list(thirds)
    rng.shuffle(randomized)
    return sorted(randomized, key=lambda item: (item[1].points, item[1].goal_diff, item[1].goals_for), reverse=True)[:8]


def build_knockout_teams(group_rankings: dict[str, list[TeamStanding]], best_thirds: list[tuple[str, TeamStanding]]) -> list[str]:
    teams = []
    for group in sorted(group_rankings):
        teams.append(group_rankings[group][0].team)
        teams.append(group_rankings[group][1].team)
    teams.extend(team.team for _, team in best_thirds)
    return teams[:32]


def knockout_pairs(teams: list[str], rng: random.Random) -> list[tuple[str, str]]:
    # Deterministic bracket placeholder: pair from ends to avoid purely random pairing.
    ordered = list(teams)
    return [(ordered[idx], ordered[-idx - 1]) for idx in range(len(ordered) // 2)]


def simulate_knockout_match(model: Model, team_1: str, team_2: str, rng: random.Random) -> str:
    lambda_1, lambda_2 = predict_goals(model, team_1, team_2, neutral=True)
    score_1, score_2 = simulate_score(lambda_1, lambda_2, rng)
    if score_1 > score_2:
        return team_1
    if score_2 > score_1:
        return team_2
    advance_probability = lambda_1 / max(lambda_1 + lambda_2, 1e-9)
    return team_1 if rng.random() <= advance_probability else team_2


def simulate_tournament(
    model: Model,
    groups: dict[str, list[str]],
    schedule: list[dict[str, str]],
    observed_results: dict[tuple[str, str, str], tuple[int, int]],
    simulations: int,
    seed: int,
) -> dict[str, dict[str, int]]:
    rng = random.Random(seed)
    stage_counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    all_teams = [team for teams in groups.values() for team in teams]

    group_matches = [row for row in schedule if row["stage"].lower() == "group"]
    if not group_matches:
        group_matches = generate_round_robin_schedule(groups)

    for _ in range(simulations):
        standings_by_group = empty_standings(groups)
        reached = {team: "group_exit" for team in all_teams}

        for match in group_matches:
            group = match["group"].strip()
            team_1 = normalize_team(match["team_1"])
            team_2 = normalize_team(match["team_2"])
            observed = observed_results.get((group, team_1, team_2))
            if observed:
                score_1, score_2 = observed
            else:
                lambda_1, lambda_2 = predict_goals(model, team_1, team_2, neutral=True)
                score_1, score_2 = simulate_score(lambda_1, lambda_2, rng)
            apply_match(standings_by_group[group], team_1, team_2, score_1, score_2)

        group_rankings = {group: sorted_group(standing, rng) for group, standing in standings_by_group.items()}
        third_candidates = [(group, ranking[2]) for group, ranking in group_rankings.items()]
        best_thirds = select_best_thirds(third_candidates, rng)
        qualified = set()
        for ranking in group_rankings.values():
            qualified.add(ranking[0].team)
            qualified.add(ranking[1].team)
        qualified.update(team.team for _, team in best_thirds)
        for team in qualified:
            reached[team] = "round_of_32"

        current = build_knockout_teams(group_rankings, best_thirds)
        round_specs = [
            ("round_of_16", 16),
            ("quarter_final", 8),
            ("semi_final", 4),
            ("final", 2),
            ("champion", 1),
        ]
        for stage_name, target_count in round_specs:
            winners = []
            for team_1, team_2 in knockout_pairs(current, rng):
                winners.append(simulate_knockout_match(model, team_1, team_2, rng))
            for team in winners:
                reached[team] = stage_name
            current = winners[:target_count]

        for team, stage in reached.items():
            for stage_key in STAGE_ORDER:
                if STAGE_ORDER.index(stage) >= STAGE_ORDER.index(stage_key):
                    stage_counts[team][stage_key] += 1

    return stage_counts


def probabilities_from_counts(stage_counts: dict[str, dict[str, int]], simulations: int) -> list[dict[str, object]]:
    rows = []
    for team in sorted(stage_counts):
        row: dict[str, object] = {"team": team}
        for stage in STAGE_ORDER:
            row[stage] = round(stage_counts[team].get(stage, 0) / simulations, 6)
        rows.append(row)
    return rows


def probability_ci(probability: float, simulations: int) -> tuple[float, float]:
    standard_error = math.sqrt(max(probability * (1.0 - probability), 0.0) / max(simulations, 1))
    lower = max(0.0, probability - CI_Z * standard_error)
    upper = min(1.0, probability + CI_Z * standard_error)
    return round(lower, 6), round(upper, 6)


def top_probability_rows(prob_rows: list[dict[str, object]], field: str, n: int = 10) -> list[dict[str, object]]:
    ordered = sorted(prob_rows, key=lambda row: float(row[field]), reverse=True)[:n]
    rows = []
    for idx, row in enumerate(ordered):
        probability = float(row[field])
        lower, upper = probability_ci(probability, int(row.get("_simulations", DEFAULT_SIMULATIONS)))
        rows.append({"rank": idx + 1, "team": row["team"], "probability": probability, "ci_lower": lower, "ci_upper": upper})
    return rows


def group_advancement_rows(groups: dict[str, list[str]], prob_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    by_team = {row["team"]: row for row in prob_rows}
    rows = []
    for group, teams in groups.items():
        for team in teams:
            row = by_team.get(team, {})
            rows.append(
                {
                    "group": group,
                    "team": team,
                    "round_of_32_probability": row.get("round_of_32", 0.0),
                    "round_of_16_probability": row.get("round_of_16", 0.0),
                    "champion_probability": row.get("champion", 0.0),
                }
            )
    return rows


def observed_impact_rows(groups: dict[str, list[str]], observed_results: dict[tuple[str, str, str], tuple[int, int]]) -> list[dict[str, object]]:
    if not observed_results:
        return []
    standings_by_group = empty_standings(groups)
    seen = set()
    for (group, team_1, team_2), (score_1, score_2) in observed_results.items():
        key = tuple(sorted([group, team_1, team_2]))
        if key in seen:
            continue
        seen.add(key)
        if group in standings_by_group and team_1 in standings_by_group[group] and team_2 in standings_by_group[group]:
            apply_match(standings_by_group[group], team_1, team_2, score_1, score_2)
    rows = []
    for group, standings in standings_by_group.items():
        for team, standing in standings.items():
            rows.append(
                {
                    "group": group,
                    "team": team,
                    "played": standing.played,
                    "points": standing.points,
                    "goals_for": standing.goals_for,
                    "goals_against": standing.goals_against,
                    "goal_diff": standing.goal_diff,
                }
            )
    return rows


def approved_value(value: str) -> bool:
    return str(value).strip().lower() in {"true", "1", "yes", "y", "approved"}


def enforce_data_approval(args: argparse.Namespace) -> None:
    if args.allow_unconfirmed_data:
        print("WARNING: --allow-unconfirmed-data enabled. Results are for debugging only, not for the formal report.")
        return

    required = {
        Path(args.groups).name,
        Path(args.history).name,
        "worldcup_2026_results_asof_2026-06-15.csv",
        "annex_c_full_mapping",
    }
    schedule_path = Path(args.schedule)
    if schedule_path.exists() or not args.allow_generated_group_schedule:
        required.add(schedule_path.name)
    elo_path = Path(args.elo) if args.elo else None
    if elo_path and elo_path.exists():
        required.add(elo_path.name)

    approval_path = Path(args.approval)
    if not approval_path.exists():
        raise SystemExit(f"Data approval file not found: {approval_path}")
    with approval_path.open(encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    approval = {row.get("file", ""): approved_value(row.get("approved", "")) for row in rows}
    missing = sorted(required - set(approval))
    pending = sorted(name for name in required if not approval.get(name, False))
    if missing or pending:
        blocked = missing + pending
        raise SystemExit(
            "Data source confirmation required before formal modeling: "
            + ", ".join(blocked)
            + ". Use --allow-unconfirmed-data only for debugging."
        )


def run(args: argparse.Namespace) -> None:
    enforce_data_approval(args)
    output_dir = Path(args.output)
    ensure_dir(output_dir)

    groups = load_groups(Path(args.groups))
    schedule_path = Path(args.schedule)
    if schedule_path.exists():
        schedule = load_schedule(schedule_path)
    elif args.allow_generated_group_schedule:
        schedule = generate_round_robin_schedule(groups)
    else:
        raise FileNotFoundError(
            f"{schedule_path} not found. Provide the official schedule CSV or use --allow-generated-group-schedule for a dry run."
        )

    observed_results = load_results(Path(args.results) if args.results else None)
    model, metrics, coefficient_rows = train_model(Path(args.history), Path(args.elo) if args.elo else None)
    stage_counts = simulate_tournament(model, groups, schedule, observed_results, args.simulations, args.seed)
    probability_rows = probabilities_from_counts(stage_counts, args.simulations)
    for row in probability_rows:
        row["_simulations"] = args.simulations

    write_csv(output_dir / "team_stage_probabilities.csv", probability_rows, ["team", *STAGE_ORDER])
    write_csv(output_dir / "champion_probabilities.csv", top_probability_rows(probability_rows, "champion"), ["rank", "team", "probability", "ci_lower", "ci_upper"])
    write_csv(output_dir / "final_four_probabilities.csv", top_probability_rows(probability_rows, "semi_final"), ["rank", "team", "probability", "ci_lower", "ci_upper"])
    write_csv(output_dir / "group_advancement_probabilities.csv", group_advancement_rows(groups, probability_rows), ["group", "team", "round_of_32_probability", "round_of_16_probability", "champion_probability"])
    write_csv(output_dir / "model_metrics.csv", metrics, ["metric", "value"])
    write_csv(output_dir / "model_coefficients.csv", coefficient_rows, ["feature", "home_goal_coefficient", "away_goal_coefficient"])
    impact_rows = observed_impact_rows(groups, observed_results)
    if impact_rows:
        write_csv(output_dir / "asof_results_impact.csv", impact_rows, ["group", "team", "played", "points", "goals_for", "goals_against", "goal_diff"])

    print(f"Simulation complete: {args.simulations} runs")
    print(f"Output directory: {output_dir}")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the 2026 World Cup prediction pipeline.")
    parser.add_argument("--groups", default=str(DEFAULT_GROUPS))
    parser.add_argument("--schedule", default=str(PROJECT_ROOT / "data/worldcup_2026_schedule.csv"))
    parser.add_argument("--history", default=str(DEFAULT_HISTORY))
    parser.add_argument("--elo", default=str(DEFAULT_ELO))
    parser.add_argument("--results", default=str(DEFAULT_RESULTS))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--approval", default=str(DEFAULT_APPROVAL))
    parser.add_argument("--simulations", type=int, default=DEFAULT_SIMULATIONS)
    parser.add_argument("--seed", type=int, default=RANDOM_SEED)
    parser.add_argument("--allow-generated-group-schedule", action="store_true", help="Use generated group round-robin fixtures if official schedule CSV is absent. Dry-run only.")
    parser.add_argument("--allow-unconfirmed-data", action="store_true", help="Run with unconfirmed data for code debugging only.")
    return parser


if __name__ == "__main__":
    run(build_arg_parser().parse_args())
