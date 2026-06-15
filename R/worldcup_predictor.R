#!/usr/bin/env Rscript

# 2026 World Cup probability model and Monte Carlo simulator in R.
# Dependencies: base R only.

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) return(args[[pos + 1]])
  default
}

has_flag <- function(flag) flag %in% args

project_root <- normalizePath(".", mustWork = TRUE)
groups_path <- get_arg("--groups", file.path(project_root, "data/worldcup_2026_groups.csv"))
schedule_path <- get_arg("--schedule", file.path(project_root, "data/worldcup_2026_schedule.csv"))
history_path <- get_arg("--history", file.path(project_root, "data/historical_matches.csv"))
elo_path <- get_arg("--elo", file.path(project_root, "data/team_elo.csv"))
results_path <- get_arg("--results", file.path(project_root, "data/worldcup_2026_results_asof_2026-06-15.csv"))
output_dir <- get_arg("--output", file.path(project_root, "output"))
simulations <- as.integer(get_arg("--simulations", "10000"))
seed <- as.integer(get_arg("--seed", "20260615"))
allow_generated_group_schedule <- has_flag("--allow-generated-group-schedule")

date_cutoff <- as.Date("2026-06-10")
train_end <- as.Date("2024-12-31")
test_start <- as.Date("2025-01-01")
hosts <- c("美国", "加拿大", "墨西哥")
form_window <- 10
ci_z <- 1.96
stage_order <- c("group_exit", "round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion")

normalize_team <- function(x) {
  x <- trimws(gsub("\\s+", " ", x))
  replacements <- c(
    "Mexico" = "墨西哥",
    "South Africa" = "南非",
    "South Korea" = "韩国",
    "Korea Republic" = "韩国",
    "Czechia" = "捷克",
    "Czech Republic" = "捷克",
    "Canada" = "加拿大",
    "Bosnia and Herzegovina" = "波黑",
    "Bosnia-Herzegovina" = "波黑",
    "Bosnia & Herzegovina" = "波黑",
    "Qatar" = "卡塔尔",
    "Switzerland" = "瑞士",
    "Brazil" = "巴西",
    "Morocco" = "摩洛哥",
    "Haiti" = "海地",
    "Scotland" = "苏格兰",
    "United States" = "美国",
    "USA" = "美国",
    "U.S." = "美国",
    "United States of America" = "美国",
    "Paraguay" = "巴拉圭",
    "Australia" = "澳大利亚",
    "Turkiye" = "土耳其",
    "Türkiye" = "土耳其",
    "Turkey" = "土耳其",
    "Germany" = "德国",
    "Curacao" = "库拉索",
    "Curaçao" = "库拉索",
    "Ivory Coast" = "科特迪瓦",
    "Côte d'Ivoire" = "科特迪瓦",
    "Cote d'Ivoire" = "科特迪瓦",
    "Ecuador" = "厄瓜多尔",
    "Netherlands" = "荷兰",
    "Japan" = "日本",
    "Sweden" = "瑞典",
    "Tunisia" = "突尼斯",
    "Belgium" = "比利时",
    "Egypt" = "埃及",
    "Iran" = "伊朗",
    "New Zealand" = "新西兰",
    "Spain" = "西班牙",
    "Cape Verde" = "佛得角",
    "Cape Verde Islands" = "佛得角",
    "Saudi Arabia" = "沙特阿拉伯",
    "沙特" = "沙特阿拉伯",
    "Uruguay" = "乌拉圭",
    "France" = "法国",
    "Senegal" = "塞内加尔",
    "Iraq" = "伊拉克",
    "Norway" = "挪威",
    "Argentina" = "阿根廷",
    "Algeria" = "阿尔及利亚",
    "Austria" = "奥地利",
    "Jordan" = "约旦",
    "Portugal" = "葡萄牙",
    "DR Congo" = "民主刚果",
    "Congo DR" = "民主刚果",
    "Democratic Republic of the Congo" = "民主刚果",
    "刚果(金)" = "民主刚果",
    "刚果民主共和国" = "民主刚果",
    "Uzbekistan" = "乌兹别克斯坦",
    "Colombia" = "哥伦比亚",
    "England" = "英格兰",
    "Croatia" = "克罗地亚",
    "Ghana" = "加纳",
    "Panama" = "巴拿马"
  )
  ifelse(x %in% names(replacements), replacements[x], x)
}

truthy <- function(x) tolower(trimws(as.character(x))) %in% c("true", "1", "yes", "y")

tournament_weight <- function(tournament) {
  lower <- tolower(tournament)
  ifelse(grepl("world cup", lower) & !grepl("qualification|qualifier", lower), 1.45,
    ifelse(grepl("continental|euro|copa|africa cup", lower), 1.25,
      ifelse(grepl("qualification|qualifier|nations league", lower), 1.10,
        ifelse(grepl("friendly", lower), 0.65, 1.0)
      )
    )
  )
}

read_csv_safe <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
}

load_groups <- function(path) {
  df <- read_csv_safe(path)
  df$team <- normalize_team(df$team)
  split_df <- split(df[order(df$slot), ], df$group)
  lapply(split_df[LETTERS[1:12]], function(x) x$team)
}

load_history <- function(path) {
  if (!file.exists(path)) stop("historical_matches.csv not found; prepare real historical match data first.", call. = FALSE)
  df <- read_csv_safe(path)
  df$date <- as.Date(df$date)
  df <- df[!is.na(df$date) & df$date <= date_cutoff, ]
  df$home_team <- normalize_team(df$home_team)
  df$away_team <- normalize_team(df$away_team)
  df$home_score <- as.integer(df$home_score)
  df$away_score <- as.integer(df$away_score)
  df$neutral <- truthy(df$neutral)
  df[order(df$date), ]
}

load_elo <- function(path) {
  if (!file.exists(path)) return(setNames(numeric(0), character(0)))
  df <- read_csv_safe(path)
  value_col <- intersect(c("elo", "rating", "score"), names(df))[1]
  if (is.na(value_col) || !"team" %in% names(df)) return(setNames(numeric(0), character(0)))
  teams <- normalize_team(df$team)
  values <- as.numeric(df[[value_col]])
  setNames(values, teams)
}

load_schedule <- function(path, groups) {
  if (file.exists(path)) {
    df <- read_csv_safe(path)
    df$team_1 <- normalize_team(df$team_1)
    df$team_2 <- normalize_team(df$team_2)
    df$match_date <- as.Date(df$match_date)
    return(df[order(df$match_date, df$match_id), ])
  }
  if (!allow_generated_group_schedule) {
    stop("worldcup_2026_schedule.csv not found. Provide official schedule or use --allow-generated-group-schedule for dry run.", call. = FALSE)
  }
  rows <- list()
  pairings <- list(c(1, 2), c(3, 4), c(1, 3), c(2, 4), c(1, 4), c(2, 3))
  id <- 1
  for (g in names(groups)) {
    teams <- groups[[g]]
    for (i in seq_along(pairings)) {
      p <- pairings[[i]]
      rows[[length(rows) + 1]] <- data.frame(
        match_id = sprintf("G%03d", id),
        stage = "group",
        group = g,
        match_date = as.Date(sprintf("2026-06-%02d", 10 + i)),
        team_1 = teams[p[1]],
        team_2 = teams[p[2]],
        venue = "official_schedule_required",
        host_country = "official_schedule_required",
        team_1_slot = sprintf("%s%d", g, p[1]),
        team_2_slot = sprintf("%s%d", g, p[2]),
        stringsAsFactors = FALSE
      )
      id <- id + 1
    }
  }
  do.call(rbind, rows)
}

load_results <- function(path) {
  if (!file.exists(path)) return(data.frame())
  df <- read_csv_safe(path)
  df$team_1 <- normalize_team(df$team_1)
  df$team_2 <- normalize_team(df$team_2)
  df$team_1_score <- as.integer(df$team_1_score)
  df$team_2_score <- as.integer(df$team_2_score)
  df
}

infer_elo <- function(matches, external_elo) {
  teams <- sort(unique(c(matches$home_team, matches$away_team, names(external_elo))))
  ratings <- setNames(rep(1500, length(teams)), teams)
  if (length(external_elo) > 0) {
    common <- intersect(names(external_elo), names(ratings))
    ratings[common] <- external_elo[common]
  }
  for (i in seq_len(nrow(matches))) {
    h <- matches$home_team[i]
    a <- matches$away_team[i]
    hs <- matches$home_score[i]
    as <- matches$away_score[i]
    home_adv <- ifelse(matches$neutral[i], 0, 55)
    expected <- 1 / (1 + 10 ^ (-((ratings[h] + home_adv - ratings[a]) / 400)))
    actual <- ifelse(hs > as, 1, ifelse(hs == as, 0.5, 0))
    margin_factor <- max(1, log(abs(hs - as) + 1) + 1)
    k <- 18 * tournament_weight(matches$tournament[i]) * margin_factor
    delta <- k * (actual - expected)
    ratings[h] <- ratings[h] + delta
    ratings[a] <- ratings[a] - delta
  }
  ratings
}

form_features <- function(forms, team) {
  mat <- forms[[team]]
  if (is.null(mat) || nrow(mat) == 0) return(c(win_rate = 0.33, gf = 1.25, ga = 1.25, gd = 0))
  c(
    win_rate = mean(mat[, "gf"] > mat[, "ga"]),
    gf = mean(mat[, "gf"]),
    ga = mean(mat[, "ga"]),
    gd = mean(mat[, "gf"] - mat[, "ga"])
  )
}

add_form <- function(forms, team, gf, ga) {
  mat <- forms[[team]]
  row <- matrix(c(gf, ga), ncol = 2)
  colnames(row) <- c("gf", "ga")
  if (is.null(mat)) mat <- row else mat <- rbind(mat, row)
  if (nrow(mat) > form_window) mat <- mat[(nrow(mat) - form_window + 1):nrow(mat), , drop = FALSE]
  forms[[team]] <- mat
  forms
}

build_samples <- function(matches, ratings) {
  default_rating <- mean(ratings)
  forms <- list()
  out <- list()
  for (i in seq_len(nrow(matches))) {
    h <- matches$home_team[i]
    a <- matches$away_team[i]
    hf <- form_features(forms, h)
    af <- form_features(forms, a)
    h_elo <- ifelse(h %in% names(ratings), ratings[h], default_rating)
    a_elo <- ifelse(a %in% names(ratings), ratings[a], default_rating)
    out[[length(out) + 1]] <- data.frame(
      date = matches$date[i],
      home_team = h,
      away_team = a,
      home_score = matches$home_score[i],
      away_score = matches$away_score[i],
      weight = tournament_weight(matches$tournament[i]),
      intercept = 1,
      elo_diff = as.numeric((h_elo - a_elo) / 400),
      recent_win_rate_diff = hf["win_rate"] - af["win_rate"],
      home_attack_vs_away_defense = hf["gf"] - af["ga"],
      away_attack_vs_home_defense = af["gf"] - hf["ga"],
      recent_goal_diff_diff = hf["gd"] - af["gd"],
      home_field = ifelse(matches$neutral[i], 0, 1),
      host_country_diff = ifelse(h %in% hosts, 1, 0) - ifelse(a %in% hosts, 1, 0),
      tournament_importance = tournament_weight(matches$tournament[i]) - 1,
      stringsAsFactors = FALSE
    )
    forms <- add_form(forms, h, matches$home_score[i], matches$away_score[i])
    forms <- add_form(forms, a, matches$away_score[i], matches$home_score[i])
  }
  do.call(rbind, out)
}

fit_models <- function(samples) {
  train <- samples[samples$date <= train_end, ]
  if (nrow(train) == 0) stop("No training samples available.", call. = FALSE)
  formula_home <- home_score ~ elo_diff + recent_win_rate_diff + home_attack_vs_away_defense +
    away_attack_vs_home_defense + recent_goal_diff_diff + home_field +
    host_country_diff + tournament_importance
  formula_away <- away_score ~ elo_diff + recent_win_rate_diff + home_attack_vs_away_defense +
    away_attack_vs_home_defense + recent_goal_diff_diff + home_field +
    host_country_diff + tournament_importance
  list(
    home = glm(formula_home, data = train, family = poisson(), weights = weight),
    away = glm(formula_away, data = train, family = poisson(), weights = weight)
  )
}

predict_goals <- function(models, ratings, team_1, team_2, neutral = TRUE, tournament_weight_value = 1.45) {
  default_rating <- mean(ratings)
  elo_1 <- ifelse(team_1 %in% names(ratings), ratings[team_1], default_rating)
  elo_2 <- ifelse(team_2 %in% names(ratings), ratings[team_2], default_rating)
  row <- data.frame(
    elo_diff = as.numeric((elo_1 - elo_2) / 400),
    recent_win_rate_diff = 0,
    home_attack_vs_away_defense = 0,
    away_attack_vs_home_defense = 0,
    recent_goal_diff_diff = 0,
    home_field = ifelse(neutral, 0, 1),
    host_country_diff = ifelse(team_1 %in% hosts, 1, 0) - ifelse(team_2 %in% hosts, 1, 0),
    tournament_importance = tournament_weight_value - 1
  )
  lambda_1 <- as.numeric(predict(models$home, newdata = row, type = "response"))
  lambda_2 <- as.numeric(predict(models$away, newdata = row, type = "response"))
  c(max(0.15, min(5.5, lambda_1)), max(0.15, min(5.5, lambda_2)))
}

wdl_probs <- function(lambda_1, lambda_2, max_goals = 10) {
  p1 <- dpois(0:max_goals, lambda_1)
  p2 <- dpois(0:max_goals, lambda_2)
  p1 <- p1 / sum(p1)
  p2 <- p2 / sum(p2)
  win <- draw <- loss <- 0
  for (g1 in 0:max_goals) {
    for (g2 in 0:max_goals) {
      p <- p1[g1 + 1] * p2[g2 + 1]
      if (g1 > g2) win <- win + p else if (g1 == g2) draw <- draw + p else loss <- loss + p
    }
  }
  c(H = win, D = draw, A = loss) / (win + draw + loss)
}

evaluate_model <- function(models, ratings, samples) {
  test <- samples[samples$date >= test_start & samples$date <= date_cutoff, ]
  if (nrow(test) == 0) test <- samples[samples$date <= train_end, ]
  correct <- 0
  brier <- c()
  logloss <- c()
  confusion <- matrix(0, nrow = 3, ncol = 3, dimnames = list(c("H", "D", "A"), c("H", "D", "A")))
  for (i in seq_len(nrow(test))) {
    lambdas <- predict_goals(models, ratings, test$home_team[i], test$away_team[i], neutral = test$home_field[i] == 0)
    probs <- wdl_probs(lambdas[1], lambdas[2])
    pred <- names(which.max(probs))
    actual <- ifelse(test$home_score[i] > test$away_score[i], "H", ifelse(test$home_score[i] == test$away_score[i], "D", "A"))
    correct <- correct + as.integer(pred == actual)
    confusion[actual, pred] <- confusion[actual, pred] + 1
    brier <- c(brier, sum((probs - as.numeric(names(probs) == actual)) ^ 2))
    logloss <- c(logloss, -log(max(probs[actual], 1e-12)))
  }
  rows <- data.frame(
    metric = c("samples", "accuracy", "brier_score", "log_loss"),
    value = c(nrow(test), correct / nrow(test), mean(brier), mean(logloss))
  )
  for (a in rownames(confusion)) {
    for (p in colnames(confusion)) {
      rows <- rbind(rows, data.frame(metric = sprintf("confusion_%s_pred_%s", a, p), value = confusion[a, p]))
    }
  }
  rows
}

empty_standings <- function(groups) {
  standings <- list()
  for (g in names(groups)) {
    standings[[g]] <- data.frame(
      team = groups[[g]], played = 0, points = 0, goals_for = 0, goals_against = 0,
      stringsAsFactors = FALSE
    )
  }
  standings
}

apply_match <- function(table, team_1, team_2, score_1, score_2) {
  i <- match(team_1, table$team)
  j <- match(team_2, table$team)
  table$played[c(i, j)] <- table$played[c(i, j)] + 1
  table$goals_for[i] <- table$goals_for[i] + score_1
  table$goals_against[i] <- table$goals_against[i] + score_2
  table$goals_for[j] <- table$goals_for[j] + score_2
  table$goals_against[j] <- table$goals_against[j] + score_1
  if (score_1 > score_2) table$points[i] <- table$points[i] + 3
  if (score_1 < score_2) table$points[j] <- table$points[j] + 3
  if (score_1 == score_2) table$points[c(i, j)] <- table$points[c(i, j)] + 1
  table
}

rank_group <- function(table) {
  table$goal_diff <- table$goals_for - table$goals_against
  table$rand <- runif(nrow(table))
  table[order(-table$points, -table$goal_diff, -table$goals_for, table$rand), ]
}

observed_lookup <- function(results) {
  keys <- character(0)
  values <- list()
  if (nrow(results) == 0) return(list(keys = keys, values = values))
  for (i in seq_len(nrow(results))) {
    k1 <- paste(results$group[i], results$team_1[i], results$team_2[i], sep = "||")
    k2 <- paste(results$group[i], results$team_2[i], results$team_1[i], sep = "||")
    keys <- c(keys, k1, k2)
    values[[k1]] <- c(results$team_1_score[i], results$team_2_score[i])
    values[[k2]] <- c(results$team_2_score[i], results$team_1_score[i])
  }
  list(keys = keys, values = values)
}

get_observed <- function(lookup, group, team_1, team_2) {
  key <- paste(group, team_1, team_2, sep = "||")
  if (key %in% lookup$keys) return(lookup$values[[key]])
  NULL
}

simulate_score <- function(lambda_1, lambda_2) c(rpois(1, lambda_1), rpois(1, lambda_2))

knockout_pairs <- function(teams) {
  n <- length(teams)
  data.frame(team_1 = teams[1:(n / 2)], team_2 = rev(teams)[1:(n / 2)], stringsAsFactors = FALSE)
}

simulate_knockout_match <- function(models, ratings, team_1, team_2) {
  lambdas <- predict_goals(models, ratings, team_1, team_2, neutral = TRUE)
  score <- simulate_score(lambdas[1], lambdas[2])
  if (score[1] > score[2]) return(team_1)
  if (score[2] > score[1]) return(team_2)
  ifelse(runif(1) <= lambdas[1] / sum(lambdas), team_1, team_2)
}

stage_rank <- setNames(seq_along(stage_order), stage_order)

mark_reached <- function(reached, team, stage) {
  if (!is.na(team) && team %in% names(reached) && stage_rank[[stage]] > stage_rank[[reached[[team]]]]) {
    reached[[team]] <- stage
  }
  reached
}

resolve_group_slot <- function(slot_expr, rankings, best_thirds, used_third_groups) {
  slot_expr <- trimws(slot_expr)
  choices <- trimws(strsplit(slot_expr, "/", fixed = TRUE)[[1]])
  is_third_slot <- grepl("3$", choices)

  if (length(choices) > 1 || any(is_third_slot)) {
    allowed_groups <- sub("3$", "", choices[is_third_slot])
    remaining <- best_thirds[!(best_thirds$group %in% used_third_groups), , drop = FALSE]
    candidates <- remaining[remaining$group %in% allowed_groups, , drop = FALSE]
    if (nrow(candidates) == 0) candidates <- remaining
    if (nrow(candidates) == 0) stop(sprintf("Cannot resolve third-place slot: %s", slot_expr), call. = FALSE)
    chosen_group <- candidates$group[1]
    return(list(team = candidates$team[1], used = c(used_third_groups, chosen_group)))
  }

  group <- substr(slot_expr, 1, 1)
  rank <- as.integer(substr(slot_expr, 2, 2))
  if (!group %in% names(rankings) || is.na(rank)) {
    stop(sprintf("Cannot resolve knockout slot: %s", slot_expr), call. = FALSE)
  }
  list(team = rankings[[group]]$team[rank], used = used_third_groups)
}

resolve_bracket_side <- function(slot_expr, rankings, best_thirds, used_third_groups, winners, losers) {
  slot_expr <- trimws(slot_expr)
  if (grepl("^W[0-9]{2,}$", slot_expr)) {
    key <- sub("^W", "", slot_expr)
    return(list(team = winners[[key]], used = used_third_groups))
  }
  if (grepl("^L[0-9]{2,}$", slot_expr)) {
    key <- sub("^L", "", slot_expr)
    return(list(team = losers[[key]], used = used_third_groups))
  }
  resolve_group_slot(slot_expr, rankings, best_thirds, used_third_groups)
}

simulate_official_knockout <- function(models, ratings, schedule, rankings, best_thirds, reached) {
  bracket <- schedule[tolower(schedule$stage) != "group", ]
  if (nrow(bracket) == 0) return(reached)
  match_number <- as.integer(gsub("[^0-9]", "", bracket$match_id))
  bracket <- bracket[order(bracket$match_date, match_number), ]
  winners <- list()
  losers <- list()
  used_third_groups <- character(0)
  next_stage <- c(
    round_of_32 = "round_of_16",
    round_of_16 = "quarter_final",
    quarter_final = "semi_final",
    semi_final = "final",
    final = "champion"
  )

  for (i in seq_len(nrow(bracket))) {
    row <- bracket[i, ]
    left <- resolve_bracket_side(row$team_1_slot, rankings, best_thirds, used_third_groups, winners, losers)
    used_third_groups <- left$used
    right <- resolve_bracket_side(row$team_2_slot, rankings, best_thirds, used_third_groups, winners, losers)
    used_third_groups <- right$used

    winner <- simulate_knockout_match(models, ratings, left$team, right$team)
    loser <- ifelse(winner == left$team, right$team, left$team)
    key <- as.character(as.integer(gsub("[^0-9]", "", row$match_id)))
    winners[[key]] <- winner
    losers[[key]] <- loser

    stage <- tolower(row$stage)
    if (stage %in% names(next_stage)) {
      reached <- mark_reached(reached, winner, next_stage[[stage]])
    }
  }
  reached
}

simulate_tournament <- function(models, ratings, groups, schedule, results, simulations) {
  teams <- unlist(groups, use.names = FALSE)
  counts <- matrix(0, nrow = length(teams), ncol = length(stage_order), dimnames = list(teams, stage_order))
  group_matches <- schedule[tolower(schedule$stage) == "group", ]
  lookup <- observed_lookup(results)
  for (s in seq_len(simulations)) {
    standings <- empty_standings(groups)
    reached <- setNames(rep("group_exit", length(teams)), teams)
    for (i in seq_len(nrow(group_matches))) {
      row <- group_matches[i, ]
      obs <- get_observed(lookup, row$group, row$team_1, row$team_2)
      if (is.null(obs)) {
        lambdas <- predict_goals(models, ratings, row$team_1, row$team_2, neutral = TRUE)
        score <- simulate_score(lambdas[1], lambdas[2])
      } else {
        score <- obs
      }
      standings[[row$group]] <- apply_match(standings[[row$group]], row$team_1, row$team_2, score[1], score[2])
    }
    rankings <- lapply(standings, rank_group)
    thirds <- do.call(rbind, lapply(names(rankings), function(g) cbind(group = g, rankings[[g]][3, ])))
    thirds$points <- as.integer(thirds$points)
    thirds$goals_for <- as.integer(thirds$goals_for)
    thirds$goals_against <- as.integer(thirds$goals_against)
    thirds$goal_diff <- thirds$goals_for - thirds$goals_against
    thirds$rand <- runif(nrow(thirds))
    best_thirds <- thirds[order(-thirds$points, -thirds$goal_diff, -thirds$goals_for, thirds$rand), ][1:8, ]
    qualified <- unique(c(unlist(lapply(rankings, function(x) x$team[1:2])), best_thirds$team))
    reached[qualified] <- "round_of_32"

    if (any(tolower(schedule$stage) != "group")) {
      reached <- simulate_official_knockout(models, ratings, schedule, rankings, best_thirds, reached)
    } else {
      current <- c(unlist(lapply(rankings, function(x) x$team[1:2])), best_thirds$team)[1:32]
      for (stage in c("round_of_16", "quarter_final", "semi_final", "final", "champion")) {
        pairs <- knockout_pairs(current)
        winners <- mapply(function(a, b) simulate_knockout_match(models, ratings, a, b), pairs$team_1, pairs$team_2)
        reached[winners] <- stage
        current <- winners
      }
    }
    for (team in teams) {
      idx <- match(reached[team], stage_order)
      counts[team, 1:idx] <- counts[team, 1:idx] + 1
    }
  }
  as.data.frame(counts / simulations)
}

prob_ci <- function(p, n) {
  se <- sqrt(p * (1 - p) / n)
  c(max(0, p - ci_z * se), min(1, p + ci_z * se))
}

write_outputs <- function(prob, groups, metrics, models, simulations) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  prob$team <- rownames(prob)
  prob <- prob[, c("team", stage_order)]
  write.csv(prob, file.path(output_dir, "team_stage_probabilities.csv"), row.names = FALSE)
  champion <- prob[order(-prob$champion), c("team", "champion")][1:10, ]
  ci <- t(sapply(champion$champion, prob_ci, n = simulations))
  champion <- data.frame(rank = 1:nrow(champion), team = champion$team, probability = champion$champion, ci_lower = ci[, 1], ci_upper = ci[, 2])
  write.csv(champion, file.path(output_dir, "champion_probabilities.csv"), row.names = FALSE)
  four <- prob[order(-prob$semi_final), c("team", "semi_final")][1:10, ]
  ci4 <- t(sapply(four$semi_final, prob_ci, n = simulations))
  four <- data.frame(rank = 1:nrow(four), team = four$team, probability = four$semi_final, ci_lower = ci4[, 1], ci_upper = ci4[, 2])
  write.csv(four, file.path(output_dir, "final_four_probabilities.csv"), row.names = FALSE)
  group_rows <- do.call(rbind, lapply(names(groups), function(g) {
    data.frame(group = g, team = groups[[g]], stringsAsFactors = FALSE)
  }))
  group_rows <- merge(group_rows, prob[, c("team", "round_of_32", "round_of_16", "champion")], by = "team", all.x = TRUE)
  write.csv(group_rows, file.path(output_dir, "group_advancement_probabilities.csv"), row.names = FALSE)
  write.csv(metrics, file.path(output_dir, "model_metrics.csv"), row.names = FALSE)
  coef_rows <- data.frame(
    feature = names(coef(models$home)),
    home_goal_coefficient = as.numeric(coef(models$home)),
    away_goal_coefficient = as.numeric(coef(models$away))
  )
  write.csv(coef_rows, file.path(output_dir, "model_coefficients.csv"), row.names = FALSE)
}

set.seed(seed)
groups <- load_groups(groups_path)
schedule <- load_schedule(schedule_path, groups)
history <- load_history(history_path)
external_elo <- load_elo(elo_path)
ratings <- infer_elo(history, external_elo)
samples <- build_samples(history, ratings)
models <- fit_models(samples)
metrics <- evaluate_model(models, ratings, samples)
results <- load_results(results_path)
prob <- simulate_tournament(models, ratings, groups, schedule, results, simulations)
write_outputs(prob, groups, metrics, models, simulations)

cat(sprintf("Simulation complete: %s runs\n", simulations))
cat(sprintf("Output directory: %s\n", output_dir))
