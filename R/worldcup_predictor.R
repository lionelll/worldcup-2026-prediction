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
results_path <- get_arg("--results", file.path(project_root, "data/worldcup_2026_results_asof_2026-06-20.csv"))
annex_path <- get_arg("--annex-c", file.path(project_root, "data/annex_c_full_mapping.csv"))
approval_path <- get_arg("--approval", file.path(project_root, "data/data_approval.csv"))
output_dir <- get_arg("--output", file.path(project_root, "output"))
simulations <- as.integer(get_arg("--simulations", "10000"))
seed <- as.integer(get_arg("--seed", "20260615"))
allow_generated_group_schedule <- has_flag("--allow-generated-group-schedule")
allow_unconfirmed_data <- has_flag("--allow-unconfirmed-data")

date_cutoff <- as.Date("2026-06-10")
train_end <- as.Date("2024-12-31")
test_start <- as.Date("2025-01-01")
calibration_end <- as.Date("2025-12-31")
validation_start <- as.Date("2026-01-01")
hosts <- c("美国", "加拿大", "墨西哥")
form_window <- 10
ci_z <- 1.96
stage_order <- c("group_exit", "round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion")
knockout_stage_order <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final")

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

approved_value <- function(x) {
  tolower(trimws(as.character(x))) %in% c("true", "1", "yes", "y", "approved")
}

check_data_approval <- function(path, required_files) {
  if (allow_unconfirmed_data) {
    warning("--allow-unconfirmed-data is enabled. Results are for code debugging only, not for the formal report.", call. = FALSE)
    return(invisible(TRUE))
  }
  if (!file.exists(path)) {
    stop(sprintf("Data approval file not found: %s. Confirm data sources before running the formal model.", path), call. = FALSE)
  }
  df <- read_csv_safe(path)
  required_cols <- c("file", "approved")
  missing <- setdiff(required_cols, names(df))
  if (length(missing) > 0) {
    stop(sprintf("%s is missing required columns: %s", path, paste(missing, collapse = ", ")), call. = FALSE)
  }
  missing_rows <- setdiff(required_files, df$file)
  if (length(missing_rows) > 0) {
    stop(sprintf("Data approval is missing rows for: %s", paste(missing_rows, collapse = ", ")), call. = FALSE)
  }
  pending <- df[df$file %in% required_files & !approved_value(df$approved), , drop = FALSE]
  if (nrow(pending) > 0) {
    stop(sprintf(
      "Data source confirmation required before formal modeling: %s. Review data/DATA_STATUS.md and set approved=true only after user confirmation. Use --allow-unconfirmed-data for code debugging only.",
      paste(pending$file, collapse = ", ")
    ), call. = FALSE)
  }
  invisible(TRUE)
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

audit_history_data <- function(path) {
  raw <- read_csv_safe(path)
  required <- c("date", "home_team", "away_team", "home_score", "away_score", "tournament", "country", "neutral")
  missing_columns <- setdiff(required, names(raw))
  if (length(missing_columns) > 0) {
    stop(sprintf("%s is missing required columns: %s", path, paste(missing_columns, collapse = ", ")), call. = FALSE)
  }
  parsed_dates <- suppressWarnings(as.Date(raw$date))
  home_scores <- suppressWarnings(as.numeric(raw$home_score))
  away_scores <- suppressWarnings(as.numeric(raw$away_score))
  missing_counts <- vapply(required, function(name) sum(is.na(raw[[name]]) | trimws(as.character(raw[[name]])) == ""), numeric(1))
  duplicate_key <- duplicated(raw[, c("date", "home_team", "away_team", "home_score", "away_score", "tournament")])
  invalid_score <- is.na(home_scores) | is.na(away_scores) | home_scores < 0 | away_scores < 0 |
    home_scores != floor(home_scores) | away_scores != floor(away_scores)
  total_goals <- home_scores + away_scores
  high_score <- !invalid_score & total_goals >= 10
  retained <- !is.na(parsed_dates) & parsed_dates <= date_cutoff & !invalid_score
  summary_rows <- data.frame(
    section = "summary",
    item = c(
      "raw_rows", "retained_rows", "rows_after_cutoff", "duplicate_match_keys",
      "invalid_dates", "invalid_scores", "high_score_matches_total_ge_10"
    ),
    value = c(
      nrow(raw), sum(retained), sum(!is.na(parsed_dates) & parsed_dates > date_cutoff),
      sum(duplicate_key), sum(is.na(parsed_dates)), sum(invalid_score), sum(high_score)
    ),
    rate = c(
      1, mean(retained), mean(!is.na(parsed_dates) & parsed_dates > date_cutoff),
      mean(duplicate_key), mean(is.na(parsed_dates)), mean(invalid_score), mean(high_score)
    ),
    treatment = c(
      "input", "used by feature builder", "excluded by date boundary", "reported; not automatically deleted",
      "excluded", "excluded", "flagged for sensitivity review; not automatically deleted"
    ),
    stringsAsFactors = FALSE
  )
  missing_rows <- data.frame(
    section = "missingness",
    item = paste0("missing_", names(missing_counts)),
    value = as.numeric(missing_counts),
    rate = as.numeric(missing_counts) / max(1, nrow(raw)),
    treatment = "required field; missing rows are reported before modelling",
    stringsAsFactors = FALSE
  )
  rbind(summary_rows, missing_rows)
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
  df$match_date <- as.Date(df$match_date)
  df$team_1 <- normalize_team(df$team_1)
  df$team_2 <- normalize_team(df$team_2)
  df$team_1_score <- as.integer(df$team_1_score)
  df$team_2_score <- as.integer(df$team_2_score)
  if (!"match_id" %in% names(df)) df$match_id <- ""
  if (!"stage" %in% names(df)) df$stage <- ifelse(df$group == "", "", "group")
  if (!"winner" %in% names(df)) df$winner <- ""
  if (!"decided_by" %in% names(df)) df$decided_by <- "90min"
  df$winner <- normalize_team(df$winner)
  df$.source_order <- seq_len(nrow(df))
  df[order(df$match_date, df$.source_order), ]
}

canonical_third_groups <- function(x) {
  chars <- unlist(strsplit(toupper(gsub("[^A-L]", "", x)), ""))
  paste(sort(unique(chars)), collapse = "")
}

load_annex_mapping <- function(path) {
  if (!file.exists(path)) {
    if (!allow_unconfirmed_data) {
      stop(sprintf(
        "Official Annex C mapping file not found: %s. Do not generate formal knockout paths without the verified mapping.",
        path
      ), call. = FALSE)
    }
    warning("Annex C mapping is absent. Debug simulation will use candidate-slot matching and is not a formal prediction.", call. = FALSE)
    return(data.frame())
  }
  df <- read_csv_safe(path)
  required <- c("qualified_groups", "match_id", "third_group")
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop(sprintf("%s is missing columns: %s", path, paste(missing, collapse = ", ")), call. = FALSE)
  }
  df$qualified_groups <- vapply(df$qualified_groups, canonical_third_groups, character(1))
  df$match_id <- toupper(trimws(df$match_id))
  df$third_group <- toupper(trimws(df$third_group))
  combinations <- unique(df$qualified_groups)
  if (length(combinations) != choose(12, 8)) {
    stop(sprintf("Annex C must contain 495 unique third-place combinations; found %s.", length(combinations)), call. = FALSE)
  }
  counts <- table(df$qualified_groups)
  if (any(counts != 8)) stop("Every Annex C combination must assign exactly eight third-place teams.", call. = FALSE)
  for (key in combinations) {
    rows <- df[df$qualified_groups == key, , drop = FALSE]
    if (anyDuplicated(rows$match_id) || anyDuplicated(rows$third_group)) {
      stop(sprintf("Annex C combination %s contains duplicate match or group assignments.", key), call. = FALSE)
    }
    if (!setequal(strsplit(key, "")[[1]], rows$third_group)) {
      stop(sprintf("Annex C combination %s does not assign the same eight qualified groups.", key), call. = FALSE)
    }
  }
  df
}

update_elo <- function(ratings, home_team, away_team, home_score, away_score,
                       neutral = TRUE, tournament = "FIFA World Cup") {
  default_rating <- ifelse(length(ratings) > 0, mean(ratings), 1500)
  if (!home_team %in% names(ratings)) ratings[home_team] <- default_rating
  if (!away_team %in% names(ratings)) ratings[away_team] <- default_rating
  home_adv <- ifelse(neutral, 0, 55)
  expected <- 1 / (1 + 10 ^ (-((ratings[home_team] + home_adv - ratings[away_team]) / 400)))
  actual <- ifelse(home_score > away_score, 1, ifelse(home_score == away_score, 0.5, 0))
  margin_factor <- max(1, log(abs(home_score - away_score) + 1) + 1)
  k <- 18 * tournament_weight(tournament) * margin_factor
  delta <- k * (actual - expected)
  ratings[home_team] <- ratings[home_team] + delta
  ratings[away_team] <- ratings[away_team] - delta
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

build_samples_and_state <- function(matches, external_elo) {
  teams <- sort(unique(c(matches$home_team, matches$away_team, names(external_elo))))
  ratings <- setNames(rep(1500, length(teams)), teams)
  forms <- list()
  out <- list()
  for (i in seq_len(nrow(matches))) {
    h <- matches$home_team[i]
    a <- matches$away_team[i]
    hf <- form_features(forms, h)
    af <- form_features(forms, a)
    h_elo <- ratings[h]
    a_elo <- ratings[a]
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
    ratings <- update_elo(
      ratings, h, a, matches$home_score[i], matches$away_score[i],
      neutral = matches$neutral[i], tournament = matches$tournament[i]
    )
    forms <- add_form(forms, h, matches$home_score[i], matches$away_score[i])
    forms <- add_form(forms, a, matches$away_score[i], matches$home_score[i])
  }
  if (length(external_elo) > 0) {
    common <- intersect(names(external_elo), names(ratings))
    ratings[common] <- external_elo[common]
  }
  list(samples = do.call(rbind, out), ratings = ratings, forms = forms)
}

model_formulas <- function(model_name) {
  rhs <- switch(model_name,
    elo = "elo_diff",
    context = "elo_diff + home_field + host_country_diff + tournament_importance",
    form = paste(
      "elo_diff + home_field + host_country_diff + tournament_importance",
      "+ recent_win_rate_diff + recent_goal_diff_diff"
    ),
    full = paste(
      "elo_diff + home_field + host_country_diff + tournament_importance",
      "+ recent_win_rate_diff + recent_goal_diff_diff",
      "+ home_attack_vs_away_defense + away_attack_vs_home_defense"
    ),
    stop(sprintf("Unknown model specification: %s", model_name), call. = FALSE)
  )
  list(
    home = as.formula(paste("home_score ~", rhs)),
    away = as.formula(paste("away_score ~", rhs))
  )
}

fit_models <- function(samples, model_name = "full", training_end = train_end) {
  train <- samples[samples$date <= training_end, ]
  if (nrow(train) == 0) stop("No training samples available.", call. = FALSE)
  formulas <- model_formulas(model_name)
  models <- list(
    home = glm(formulas$home, data = train, family = poisson(), weights = weight),
    away = glm(formulas$away, data = train, family = poisson(), weights = weight)
  )
  attr(models, "model_name") <- model_name
  models
}

predict_goals <- function(models, ratings, forms, team_1, team_2, neutral = TRUE, tournament_weight_value = 1.45) {
  default_rating <- mean(ratings)
  elo_1 <- ifelse(team_1 %in% names(ratings), ratings[team_1], default_rating)
  elo_2 <- ifelse(team_2 %in% names(ratings), ratings[team_2], default_rating)
  form_1 <- form_features(forms, team_1)
  form_2 <- form_features(forms, team_2)
  row <- data.frame(
    elo_diff = as.numeric((elo_1 - elo_2) / 400),
    recent_win_rate_diff = form_1["win_rate"] - form_2["win_rate"],
    home_attack_vs_away_defense = form_1["gf"] - form_2["ga"],
    away_attack_vs_home_defense = form_2["gf"] - form_1["ga"],
    recent_goal_diff_diff = form_1["gd"] - form_2["gd"],
    home_field = ifelse(neutral, 0, 1),
    host_country_diff = ifelse(team_1 %in% hosts, 1, 0) - ifelse(team_2 %in% hosts, 1, 0),
    tournament_importance = tournament_weight_value - 1
  )
  lambda_1 <- as.numeric(predict(models$home, newdata = row, type = "response"))
  lambda_2 <- as.numeric(predict(models$away, newdata = row, type = "response"))
  c(max(0.15, min(5.5, lambda_1)), max(0.15, min(5.5, lambda_2)))
}

predict_goals_from_sample <- function(models, row) {
  lambda_1 <- as.numeric(predict(models$home, newdata = row, type = "response"))
  lambda_2 <- as.numeric(predict(models$away, newdata = row, type = "response"))
  c(max(0.15, min(5.5, lambda_1)), max(0.15, min(5.5, lambda_2)))
}

wdl_probs <- function(lambda_1, lambda_2, draw_multiplier = 1, max_goals = 10) {
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
  probs <- c(H = win, D = draw * draw_multiplier, A = loss)
  probs / sum(probs)
}

fit_draw_calibration <- function(models, samples) {
  calibration <- samples[samples$date >= test_start & samples$date <= calibration_end, ]
  if (nrow(calibration) == 0) return(1)
  base_probs <- t(vapply(seq_len(nrow(calibration)), function(i) {
    lambdas <- predict_goals_from_sample(models, calibration[i, ])
    wdl_probs(lambdas[1], lambdas[2], draw_multiplier = 1)
  }, numeric(3)))
  actual <- ifelse(
    calibration$home_score > calibration$away_score, "H",
    ifelse(calibration$home_score == calibration$away_score, "D", "A")
  )
  loss <- function(log_multiplier) {
    multiplier <- exp(log_multiplier)
    adjusted <- base_probs
    adjusted[, "D"] <- adjusted[, "D"] * multiplier
    adjusted <- adjusted / rowSums(adjusted)
    -mean(log(pmax(adjusted[cbind(seq_len(nrow(adjusted)), match(actual, colnames(adjusted)))], 1e-12)))
  }
  exp(optimize(loss, interval = log(c(0.5, 2.5)))$minimum)
}

evaluate_model <- function(models, samples, draw_multiplier) {
  test <- samples[samples$date >= validation_start & samples$date <= date_cutoff, ]
  if (nrow(test) == 0) test <- samples[samples$date <= train_end, ]
  correct <- 0
  brier <- c()
  logloss <- c()
  confusion <- matrix(0, nrow = 3, ncol = 3, dimnames = list(c("H", "D", "A"), c("H", "D", "A")))
  predicted_draw_probability <- c()
  for (i in seq_len(nrow(test))) {
    lambdas <- predict_goals_from_sample(models, test[i, ])
    probs <- wdl_probs(lambdas[1], lambdas[2], draw_multiplier)
    pred <- names(which.max(probs))
    actual <- ifelse(test$home_score[i] > test$away_score[i], "H", ifelse(test$home_score[i] == test$away_score[i], "D", "A"))
    correct <- correct + as.integer(pred == actual)
    confusion[actual, pred] <- confusion[actual, pred] + 1
    brier <- c(brier, sum((probs - as.numeric(names(probs) == actual)) ^ 2))
    logloss <- c(logloss, -log(max(probs[actual], 1e-12)))
    predicted_draw_probability <- c(predicted_draw_probability, probs["D"])
  }
  rows <- data.frame(
    metric = c(
      "samples", "accuracy", "brier_score", "log_loss", "actual_draw_rate",
      "mean_predicted_draw_probability", "draw_calibration_multiplier"
    ),
    value = c(
      nrow(test), correct / nrow(test), mean(brier), mean(logloss),
      mean(test$home_score == test$away_score), mean(predicted_draw_probability), draw_multiplier
    )
  )
  for (a in rownames(confusion)) {
    for (p in colnames(confusion)) {
      rows <- rbind(rows, data.frame(metric = sprintf("confusion_%s_pred_%s", a, p), value = confusion[a, p]))
    }
  }
  rows
}

evaluate_probability_rows <- function(models, test, draw_multiplier = 1) {
  if (nrow(test) == 0) return(c(samples = 0, accuracy = NA, brier_score = NA, log_loss = NA))
  probabilities <- t(vapply(seq_len(nrow(test)), function(i) {
    lambdas <- predict_goals_from_sample(models, test[i, ])
    wdl_probs(lambdas[1], lambdas[2], draw_multiplier)
  }, numeric(3)))
  actual <- ifelse(test$home_score > test$away_score, "H", ifelse(test$home_score == test$away_score, "D", "A"))
  actual_index <- match(actual, colnames(probabilities))
  predicted <- colnames(probabilities)[max.col(probabilities, ties.method = "first")]
  one_hot <- outer(actual, colnames(probabilities), "==") * 1
  c(
    samples = nrow(test),
    accuracy = mean(predicted == actual),
    brier_score = mean(rowSums((probabilities - one_hot) ^ 2)),
    log_loss = -mean(log(pmax(probabilities[cbind(seq_len(nrow(test)), actual_index)], 1e-12)))
  )
}

run_model_comparison <- function(samples) {
  model_names <- c("elo", "context", "form", "full")
  final_test <- samples[samples$date >= validation_start & samples$date <= date_cutoff, , drop = FALSE]
  rows <- lapply(model_names, function(model_name) {
    candidate <- fit_models(samples, model_name)
    candidate_draw <- fit_draw_calibration(candidate, samples)
    scores <- evaluate_probability_rows(candidate, final_test, candidate_draw)
    data.frame(
      model = model_name,
      parameters = length(coef(candidate$home)) + length(coef(candidate$away)),
      home_aic = AIC(candidate$home), away_aic = AIC(candidate$away),
      home_bic = BIC(candidate$home), away_bic = BIC(candidate$away),
      home_residual_deviance = deviance(candidate$home),
      away_residual_deviance = deviance(candidate$away),
      validation_samples = scores["samples"], validation_accuracy = scores["accuracy"],
      validation_brier = scores["brier_score"], validation_log_loss = scores["log_loss"],
      draw_multiplier = candidate_draw,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

run_rolling_validation <- function(samples) {
  folds <- data.frame(
    fold = c("2019-2020", "2021-2022", "2023-2024"),
    train_end = as.Date(c("2018-12-31", "2020-12-31", "2022-12-31")),
    validation_start = as.Date(c("2019-01-01", "2021-01-01", "2023-01-01")),
    validation_end = as.Date(c("2020-12-31", "2022-12-31", "2024-12-31")),
    stringsAsFactors = FALSE
  )
  model_names <- c("elo", "context", "form", "full")
  rows <- list()
  for (model_name in model_names) {
    for (i in seq_len(nrow(folds))) {
      candidate <- fit_models(samples, model_name, folds$train_end[i])
      test <- samples[samples$date >= folds$validation_start[i] & samples$date <= folds$validation_end[i], , drop = FALSE]
      scores <- evaluate_probability_rows(candidate, test, draw_multiplier = 1)
      rows[[length(rows) + 1]] <- data.frame(
        model = model_name, fold = folds$fold[i], train_end = folds$train_end[i],
        validation_start = folds$validation_start[i], validation_end = folds$validation_end[i],
        samples = scores["samples"], accuracy = scores["accuracy"],
        brier_score = scores["brier_score"], log_loss = scores["log_loss"],
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

choose_model <- function(rolling_rows) {
  means <- aggregate(cbind(log_loss, brier_score) ~ model, rolling_rows, mean)
  means[order(means$log_loss, means$brier_score, match(means$model, c("elo", "context", "form", "full"))), ][1, "model"]
}

coefficient_inference <- function(models) {
  rows <- lapply(c("home", "away"), function(outcome) {
    table <- coef(summary(models[[outcome]]))
    data.frame(
      outcome = outcome, term = rownames(table), estimate = table[, 1], std_error = table[, 2],
      z_value = table[, 3], p_value = table[, 4],
      significance = ifelse(table[, 4] < 0.001, "***", ifelse(table[, 4] < 0.01, "**", ifelse(table[, 4] < 0.05, "*", ifelse(table[, 4] < 0.1, ".", "")))),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

glm_fit_statistics <- function(models) {
  rows <- lapply(c("home", "away"), function(outcome) {
    model <- models[[outcome]]
    pearson <- residuals(model, type = "pearson")
    dispersion <- sum(pearson ^ 2, na.rm = TRUE) / model$df.residual
    data.frame(
      outcome = outcome, samples = nobs(model), parameters = length(coef(model)),
      null_deviance = model$null.deviance, null_df = model$df.null,
      residual_deviance = model$deviance, residual_df = model$df.residual,
      aic = AIC(model), bic = BIC(model), pearson_dispersion = dispersion,
      mcfadden_like_deviance_reduction = 1 - model$deviance / model$null.deviance,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

poisson_diagnostics <- function(models) {
  rows <- lapply(c("home", "away"), function(outcome) {
    model <- models[[outcome]]
    data.frame(
      outcome = outcome, observation = seq_len(nobs(model)), fitted = fitted(model),
      deviance_residual = residuals(model, type = "deviance"),
      pearson_residual = residuals(model, type = "pearson"),
      cooks_distance = cooks.distance(model),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

goal_calibration_rows <- function(models) {
  rows <- lapply(c("home", "away"), function(outcome) {
    model <- models[[outcome]]
    actual <- model$y
    predicted <- fitted(model)
    breaks <- unique(quantile(predicted, probs = seq(0, 1, 0.1), na.rm = TRUE))
    if (length(breaks) < 3) breaks <- seq(min(predicted), max(predicted) + 1e-9, length.out = 11)
    bin <- cut(predicted, breaks = breaks, include.lowest = TRUE, labels = FALSE)
    aggregate_rows <- lapply(sort(unique(bin)), function(index) {
      keep <- bin == index
      data.frame(
        outcome = outcome, bin = index, samples = sum(keep),
        mean_predicted_goals = mean(predicted[keep]), mean_observed_goals = mean(actual[keep]),
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, aggregate_rows)
  })
  do.call(rbind, rows)
}

feature_summary_rows <- function(samples) {
  train <- samples[samples$date <= train_end, , drop = FALSE]
  features <- c(
    "elo_diff", "recent_win_rate_diff", "home_attack_vs_away_defense",
    "away_attack_vs_home_defense", "recent_goal_diff_diff", "home_field",
    "host_country_diff", "tournament_importance", "home_score", "away_score"
  )
  rows <- lapply(features, function(feature) {
    values <- as.numeric(train[[feature]])
    values <- values[is.finite(values)]
    data.frame(
      feature = feature, n = length(values), mean = mean(values), sd = sd(values),
      min = min(values), q1 = unname(quantile(values, 0.25)), median = median(values),
      q3 = unname(quantile(values, 0.75)), max = max(values),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

fit_logistic_baseline <- function(samples) {
  train <- samples[samples$date <= train_end, , drop = FALSE]
  test <- samples[samples$date >= validation_start & samples$date <= date_cutoff, , drop = FALSE]
  train$first_team_win <- as.integer(train$home_score > train$away_score)
  test$first_team_win <- as.integer(test$home_score > test$away_score)
  formula <- update(model_formulas("full")$home, first_team_win ~ .)
  model <- glm(formula, data = train, family = binomial())
  probability <- pmin(1 - 1e-12, pmax(1e-12, as.numeric(predict(model, newdata = test, type = "response"))))
  actual <- test$first_team_win
  predicted <- as.integer(probability >= 0.5)
  ranks <- rank(probability, ties.method = "average")
  positives <- sum(actual == 1)
  negatives <- sum(actual == 0)
  auc <- ifelse(positives > 0 && negatives > 0,
    (sum(ranks[actual == 1]) - positives * (positives + 1) / 2) / (positives * negatives), NA_real_)
  metrics <- data.frame(
    metric = c("samples", "accuracy", "brier_score", "log_loss", "auc", "threshold",
      "confusion_actual_0_pred_0", "confusion_actual_0_pred_1", "confusion_actual_1_pred_0", "confusion_actual_1_pred_1"),
    value = c(
      nrow(test), mean(predicted == actual), mean((probability - actual) ^ 2),
      -mean(actual * log(probability) + (1 - actual) * log(1 - probability)), auc, 0.5,
      sum(actual == 0 & predicted == 0), sum(actual == 0 & predicted == 1),
      sum(actual == 1 & predicted == 0), sum(actual == 1 & predicted == 1)
    ),
    stringsAsFactors = FALSE
  )
  thresholds <- sort(unique(c(0, probability, 1)), decreasing = TRUE)
  roc <- do.call(rbind, lapply(thresholds, function(threshold) {
    class <- probability >= threshold
    data.frame(
      threshold = threshold,
      tpr = ifelse(positives > 0, sum(class & actual == 1) / positives, NA),
      fpr = ifelse(negatives > 0, sum(class & actual == 0) / negatives, NA),
      stringsAsFactors = FALSE
    )
  }))
  table <- coef(summary(model))
  inference <- data.frame(
    term = rownames(table), estimate = table[, 1], std_error = table[, 2],
    z_value = table[, 3], p_value = table[, 4],
    significance = ifelse(table[, 4] < 0.001, "***", ifelse(table[, 4] < 0.01, "**", ifelse(table[, 4] < 0.05, "*", ""))),
    stringsAsFactors = FALSE
  )
  list(model = model, metrics = metrics, roc = roc, inference = inference)
}

result_neutral_flag <- function(schedule, result_row) {
  group_schedule <- schedule[tolower(schedule$stage) == "group" & schedule$group == result_row$group, ]
  matched <- group_schedule[
    (group_schedule$team_1 == result_row$team_1 & group_schedule$team_2 == result_row$team_2) |
      (group_schedule$team_1 == result_row$team_2 & group_schedule$team_2 == result_row$team_1),
  ]
  if (nrow(matched) == 0 || !"host_country" %in% names(matched)) return(TRUE)
  host_country <- normalize_team(matched$host_country[1])
  !(result_row$team_1 == host_country)
}

compare_observed_results <- function(models, ratings, forms, schedule, results, draw_multiplier) {
  if (nrow(results) == 0) {
    return(list(
      detail = data.frame(), summary = data.frame(), ratings = ratings,
      forms = forms, rating_updates = data.frame()
    ))
  }
  state_ratings <- ratings
  state_forms <- forms
  updated_teams <- unique(c(results$team_1, results$team_2))
  initial_default <- mean(state_ratings)
  initial_ratings <- setNames(
    vapply(updated_teams, function(team) {
      ifelse(team %in% names(state_ratings), state_ratings[team], initial_default)
    }, numeric(1)),
    updated_teams
  )
  rows <- list()
  for (i in seq_len(nrow(results))) {
    row <- results[i, ]
    neutral <- result_neutral_flag(schedule, row)
    lambdas <- predict_goals(models, state_ratings, state_forms, row$team_1, row$team_2, neutral = neutral)
    probs <- wdl_probs(lambdas[1], lambdas[2], draw_multiplier)
    actual <- ifelse(row$team_1_score > row$team_2_score, "H", ifelse(row$team_1_score == row$team_2_score, "D", "A"))
    pred <- names(which.max(probs))
    brier <- sum((probs - as.numeric(names(probs) == actual)) ^ 2)
    logloss <- -log(max(probs[actual], 1e-12))
    score_abs <- abs(lambdas[1] - row$team_1_score) + abs(lambdas[2] - row$team_2_score)
    rows[[length(rows) + 1]] <- data.frame(
      match_date = row$match_date,
      group = row$group,
      team_1 = row$team_1,
      team_2 = row$team_2,
      team_1_score = row$team_1_score,
      team_2_score = row$team_2_score,
      lambda_1 = lambdas[1],
      lambda_2 = lambdas[2],
      p_team_1_win = probs["H"],
      p_draw = probs["D"],
      p_team_2_win = probs["A"],
      predicted_result = pred,
      actual_result = actual,
      correct = pred == actual,
      brier_score = brier,
      log_loss = logloss,
      score_abs_error = score_abs,
      stringsAsFactors = FALSE
    )
    state_ratings <- update_elo(
      state_ratings, row$team_1, row$team_2, row$team_1_score, row$team_2_score,
      neutral = neutral, tournament = "FIFA World Cup"
    )
    state_forms <- add_form(state_forms, row$team_1, row$team_1_score, row$team_2_score)
    state_forms <- add_form(state_forms, row$team_2, row$team_2_score, row$team_1_score)
  }
  detail <- do.call(rbind, rows)
  summary <- data.frame(
    metric = c(
      "matches",
      "correct",
      "accuracy",
      "brier_score",
      "log_loss",
      "mean_score_abs_error",
      "actual_draws",
      "predicted_draws",
      "mean_predicted_draw_probability",
      "draw_calibration_multiplier"
    ),
    value = c(
      nrow(detail),
      sum(detail$correct),
      mean(detail$correct),
      mean(detail$brier_score),
      mean(detail$log_loss),
      mean(detail$score_abs_error),
      sum(detail$actual_result == "D"),
      sum(detail$predicted_result == "D"),
      mean(detail$p_draw),
      draw_multiplier
    )
  )
  final_ratings <- state_ratings[updated_teams]
  rating_updates <- data.frame(
    team = updated_teams,
    elo_before_tournament = as.numeric(initial_ratings[updated_teams]),
    elo_after_observed = as.numeric(final_ratings),
    elo_change = as.numeric(final_ratings - initial_ratings[updated_teams]),
    stringsAsFactors = FALSE
  )
  rating_updates <- rating_updates[order(-rating_updates$elo_change), ]
  list(
    detail = detail, summary = summary, ratings = state_ratings,
    forms = state_forms, rating_updates = rating_updates
  )
}

empty_standings <- function(groups) {
  standings <- list()
  for (g in names(groups)) {
    standings[[g]] <- data.frame(
      team = groups[[g]], played = 0, wins = 0, draws = 0, losses = 0,
      points = 0, goals_for = 0, goals_against = 0,
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
  if (score_1 > score_2) {
    table$wins[i] <- table$wins[i] + 1
    table$losses[j] <- table$losses[j] + 1
    table$points[i] <- table$points[i] + 3
  }
  if (score_1 < score_2) {
    table$wins[j] <- table$wins[j] + 1
    table$losses[i] <- table$losses[i] + 1
    table$points[j] <- table$points[j] + 3
  }
  if (score_1 == score_2) {
    table$draws[c(i, j)] <- table$draws[c(i, j)] + 1
    table$points[c(i, j)] <- table$points[c(i, j)] + 1
  }
  table
}

rank_group <- function(table) {
  table$goal_diff <- table$goals_for - table$goals_against
  table$rand <- runif(nrow(table))
  table[order(-table$points, -table$goal_diff, -table$goals_for, table$rand), ]
}

compute_current_group_status <- function(groups, schedule, results) {
  standings <- empty_standings(groups)
  group_results <- results[tolower(results$stage) == "group" | results$group != "", , drop = FALSE]
  if (nrow(group_results) > 0) {
    for (i in seq_len(nrow(group_results))) {
      row <- group_results[i, ]
      if (!row$group %in% names(standings)) next
      standings[[row$group]] <- apply_match(
        standings[[row$group]], row$team_1, row$team_2,
        row$team_1_score, row$team_2_score
      )
    }
  }

  lookup <- observed_lookup(group_results)
  rows <- list()
  for (group in names(groups)) {
    table <- standings[[group]]
    table$goal_diff <- table$goals_for - table$goals_against
    table$current_rank <- match(
      table$team,
      table$team[order(-table$points, -table$goal_diff, -table$goals_for, table$team)]
    )
    group_schedule <- schedule[tolower(schedule$stage) == "group" & schedule$group == group, , drop = FALSE]
    remaining <- group_schedule[vapply(seq_len(nrow(group_schedule)), function(i) {
      is.null(get_observed(lookup, group, group_schedule$team_1[i], group_schedule$team_2[i]))
    }, logical(1)), , drop = FALSE]

    if (nrow(remaining) == 0) {
      scenarios <- matrix(integer(0), nrow = 1, ncol = 0)
    } else {
      scenarios <- as.matrix(expand.grid(rep(list(c(1L, 0L, -1L)), nrow(remaining))))
    }
    can_finish_top2 <- matrix(FALSE, nrow = nrow(scenarios), ncol = nrow(table))
    forced_outside_top2 <- matrix(FALSE, nrow = nrow(scenarios), ncol = nrow(table))
    for (scenario_index in seq_len(nrow(scenarios))) {
      points <- setNames(table$points, table$team)
      if (nrow(remaining) > 0) {
        for (match_index in seq_len(nrow(remaining))) {
          outcome <- scenarios[scenario_index, match_index]
          team_1 <- remaining$team_1[match_index]
          team_2 <- remaining$team_2[match_index]
          if (outcome == 1L) points[team_1] <- points[team_1] + 3
          if (outcome == -1L) points[team_2] <- points[team_2] + 3
          if (outcome == 0L) points[c(team_1, team_2)] <- points[c(team_1, team_2)] + 1
        }
      }
      for (team_index in seq_len(nrow(table))) {
        team <- table$team[team_index]
        other <- points[names(points) != team]
        can_finish_top2[scenario_index, team_index] <- sum(other >= points[team]) <= 1
        forced_outside_top2[scenario_index, team_index] <- sum(other > points[team]) >= 2
      }
    }
    table$top2_status <- vapply(seq_len(nrow(table)), function(team_index) {
      if (all(can_finish_top2[, team_index])) return("已锁定前二")
      if (all(forced_outside_top2[, team_index])) return("已无缘前二")
      "仍竞争前二"
    }, character(1))
    table$remaining_matches <- 3L - table$played
    table$group <- group
    table$status_basis <- "积分情景穷举；同分净胜球保持未决"
    rows[[length(rows) + 1]] <- table[, c(
      "group", "current_rank", "team", "played", "wins", "draws", "losses",
      "goals_for", "goals_against", "goal_diff", "points", "remaining_matches",
      "top2_status", "status_basis"
    )]
  }
  do.call(rbind, rows)
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

simulate_score <- function(lambda_1, lambda_2, draw_multiplier = 1, max_goals = 10) {
  score <- c(rpois(1, lambda_1), rpois(1, lambda_2))
  base_draw <- exp(-(lambda_1 + lambda_2)) * besselI(2 * sqrt(lambda_1 * lambda_2), 0)
  target_draw <- draw_multiplier * base_draw / (1 - base_draw + draw_multiplier * base_draw)
  if (draw_multiplier > 1 && score[1] != score[2]) {
    convert_probability <- (target_draw - base_draw) / max(1 - base_draw, 1e-12)
    if (runif(1) < convert_probability) {
      goals <- 0:max_goals
      tie_probs <- dpois(goals, lambda_1) * dpois(goals, lambda_2)
      tie_goal <- sample(goals, 1, prob = tie_probs)
      score <- c(tie_goal, tie_goal)
    }
  } else if (draw_multiplier < 1 && score[1] == score[2]) {
    convert_probability <- (base_draw - target_draw) / max(base_draw, 1e-12)
    if (runif(1) < convert_probability) {
      repeat {
        score <- c(rpois(1, lambda_1), rpois(1, lambda_2))
        if (score[1] != score[2]) break
      }
    }
  }
  score
}

knockout_pairs <- function(teams) {
  n <- length(teams)
  data.frame(team_1 = teams[1:(n / 2)], team_2 = rev(teams)[1:(n / 2)], stringsAsFactors = FALSE)
}

simulate_knockout_match <- function(models, ratings, forms, team_1, team_2, draw_multiplier) {
  lambdas <- predict_goals(models, ratings, forms, team_1, team_2, neutral = TRUE)
  score <- simulate_score(lambdas[1], lambdas[2], draw_multiplier)
  if (score[1] > score[2]) winner <- team_1
  else if (score[2] > score[1]) winner <- team_2
  else winner <- ifelse(runif(1) <= lambdas[1] / sum(lambdas), team_1, team_2)
  list(
    winner = winner,
    loser = ifelse(winner == team_1, team_2, team_1),
    score = score,
    lambda_1 = lambdas[1],
    lambda_2 = lambdas[2]
  )
}

stage_rank <- setNames(seq_along(stage_order), stage_order)

mark_reached <- function(reached, team, stage) {
  if (!is.na(team) && team %in% names(reached) && stage_rank[[stage]] > stage_rank[[reached[[team]]]]) {
    reached[[team]] <- stage
  }
  reached
}

resolve_group_slot <- function(slot_expr, rankings, third_assignments, match_id) {
  slot_expr <- trimws(slot_expr)
  choices <- trimws(strsplit(slot_expr, "/", fixed = TRUE)[[1]])
  is_third_slot <- grepl("3$", choices)

  if (length(choices) > 1 || any(is_third_slot)) {
    team <- unname(third_assignments[[toupper(match_id)]])
    if (is.null(team) || is.na(team) || team == "") {
      stop(sprintf("Cannot resolve third-place slot for %s: %s", match_id, slot_expr), call. = FALSE)
    }
    return(team)
  }

  group <- substr(slot_expr, 1, 1)
  rank <- as.integer(substr(slot_expr, 2, 2))
  if (!group %in% names(rankings) || is.na(rank)) {
    stop(sprintf("Cannot resolve knockout slot: %s", slot_expr), call. = FALSE)
  }
  rankings[[group]]$team[rank]
}

resolve_bracket_side <- function(slot_expr, rankings, third_assignments, match_id, winners, losers) {
  slot_expr <- trimws(slot_expr)
  if (grepl("^W[0-9]{2,}$", slot_expr)) {
    key <- sub("^W", "", slot_expr)
    return(winners[[key]])
  }
  if (grepl("^L[0-9]{2,}$", slot_expr)) {
    key <- sub("^L", "", slot_expr)
    return(losers[[key]])
  }
  resolve_group_slot(slot_expr, rankings, third_assignments, match_id)
}

debug_third_assignment <- function(best_thirds, bracket) {
  rows <- bracket[tolower(bracket$stage) == "round_of_32", , drop = FALSE]
  slots <- list()
  for (i in seq_len(nrow(rows))) {
    expressions <- c(rows$team_1_slot[i], rows$team_2_slot[i])
    third_expr <- expressions[grepl("3", expressions)]
    if (length(third_expr) == 0) next
    groups <- sub("3$", "", trimws(strsplit(third_expr[1], "/", fixed = TRUE)[[1]]))
    slots[[toupper(rows$match_id[i])]] <- intersect(groups, best_thirds$group)
  }
  ordered_ids <- names(slots)[order(vapply(slots, length, integer(1)), names(slots))]
  solve_assignment <- function(index, available, assigned) {
    if (index > length(ordered_ids)) return(assigned)
    match_id <- ordered_ids[index]
    candidates <- sort(intersect(slots[[match_id]], available))
    for (group in candidates) {
      result <- solve_assignment(index + 1, setdiff(available, group), c(assigned, setNames(group, match_id)))
      if (!is.null(result)) return(result)
    }
    NULL
  }
  groups <- sort(best_thirds$group)
  assigned_groups <- solve_assignment(1, groups, character(0))
  if (is.null(assigned_groups) || length(assigned_groups) != 8) {
    stop("Candidate third-place slots cannot be matched one-to-one in debug mode.", call. = FALSE)
  }
  group_to_team <- setNames(best_thirds$team, best_thirds$group)
  setNames(unname(group_to_team[assigned_groups]), names(assigned_groups))
}

resolve_third_assignments <- function(best_thirds, bracket, annex_mapping) {
  if (nrow(annex_mapping) == 0) return(debug_third_assignment(best_thirds, bracket))
  key <- canonical_third_groups(paste(best_thirds$group, collapse = ""))
  rows <- annex_mapping[annex_mapping$qualified_groups == key, , drop = FALSE]
  if (nrow(rows) != 8) stop(sprintf("Annex C has no complete assignment for %s.", key), call. = FALSE)
  group_to_team <- setNames(best_thirds$team, best_thirds$group)
  teams <- unname(group_to_team[rows$third_group])
  if (any(is.na(teams))) stop(sprintf("Annex C assignment %s references a non-qualified group.", key), call. = FALSE)
  setNames(teams, rows$match_id)
}

increment_counter <- function(env, key, amount = 1L) {
  current <- if (exists(key, envir = env, inherits = FALSE)) get(key, envir = env, inherits = FALSE) else 0L
  assign(key, current + amount, envir = env)
}

knockout_result_lookup <- function(results) {
  values <- list()
  if (nrow(results) == 0 || !"match_id" %in% names(results)) return(values)
  rows <- results[results$match_id != "" & tolower(results$stage) != "group", , drop = FALSE]
  for (i in seq_len(nrow(rows))) values[[toupper(rows$match_id[i])]] <- rows[i, , drop = FALSE]
  values
}

simulate_official_knockout <- function(
    models, ratings, forms, schedule, rankings, best_thirds, reached, draw_multiplier,
    annex_mapping, knockout_results, route_encounters, route_advances, slot_counts, slot_wins) {
  bracket <- schedule[tolower(schedule$stage) != "group", ]
  if (nrow(bracket) == 0) return(reached)
  match_number <- as.integer(gsub("[^0-9]", "", bracket$match_id))
  bracket <- bracket[order(bracket$match_date, match_number), ]
  winners <- list()
  losers <- list()
  path_prefix <- setNames(rep("ROOT", length(reached)), names(reached))
  third_assignments <- resolve_third_assignments(best_thirds, bracket, annex_mapping)
  next_stage <- c(
    round_of_32 = "round_of_16",
    round_of_16 = "quarter_final",
    quarter_final = "semi_final",
    semi_final = "final",
    final = "champion"
  )

  for (i in seq_len(nrow(bracket))) {
    row <- bracket[i, ]
    match_id <- toupper(row$match_id)
    left <- resolve_bracket_side(row$team_1_slot, rankings, third_assignments, match_id, winners, losers)
    right <- resolve_bracket_side(row$team_2_slot, rankings, third_assignments, match_id, winners, losers)
    if (is.null(left) || is.null(right) || is.na(left) || is.na(right)) {
      stop(sprintf("Cannot resolve participants for %s.", match_id), call. = FALSE)
    }

    observed <- knockout_results[[match_id]]
    if (!is.null(observed)) {
      expected <- sort(c(left, right))
      actual <- sort(c(observed$team_1[1], observed$team_2[1]))
      if (!identical(expected, actual)) {
        stop(sprintf("Observed participants for %s do not match the resolved bracket.", match_id), call. = FALSE)
      }
      winner <- observed$winner[1]
      if (winner == "") {
        if (observed$team_1_score[1] == observed$team_2_score[1]) {
          stop(sprintf("Knockout result %s is tied but has no winner field.", match_id), call. = FALSE)
        }
        winner <- ifelse(observed$team_1_score[1] > observed$team_2_score[1], observed$team_1[1], observed$team_2[1])
      }
      loser <- ifelse(winner == left, right, left)
    } else {
      outcome <- simulate_knockout_match(models, ratings, forms, left, right, draw_multiplier)
      winner <- outcome$winner
      loser <- outcome$loser
    }
    key <- as.character(as.integer(gsub("[^0-9]", "", row$match_id)))
    winners[[key]] <- winner
    losers[[key]] <- loser

    stage <- tolower(row$stage)
    for (side in c("team_1", "team_2")) {
      team <- ifelse(side == "team_1", left, right)
      opponent <- ifelse(side == "team_1", right, left)
      slot_key <- paste(match_id, stage, side, team, sep = "||")
      increment_counter(slot_counts, slot_key)
      if (winner == team) increment_counter(slot_wins, slot_key)
      if (stage %in% knockout_stage_order) {
        parent <- path_prefix[[team]]
        route_key <- paste(team, parent, stage, match_id, opponent, sep = "||")
        increment_counter(route_encounters, route_key)
        if (winner == team) increment_counter(route_advances, route_key)
      }
    }
    if (stage %in% knockout_stage_order) {
      path_prefix[[winner]] <- paste(path_prefix[[winner]], match_id, ifelse(winner == left, right, left), sep = ">")
    }
    if (stage %in% names(next_stage)) {
      reached <- mark_reached(reached, winner, next_stage[[stage]])
    }
  }
  reached
}

counter_rows <- function(env, field_names, value_name) {
  keys <- ls(env, all.names = TRUE)
  if (length(keys) == 0) return(data.frame())
  pieces <- strsplit(keys, "||", fixed = TRUE)
  values <- vapply(keys, function(key) get(key, envir = env, inherits = FALSE), numeric(1))
  rows <- as.data.frame(do.call(rbind, pieces), stringsAsFactors = FALSE)
  names(rows) <- field_names
  rows[[value_name]] <- values
  rows
}

build_route_rows <- function(encounters, advances, simulations) {
  rows <- counter_rows(encounters, c("team", "parent_prefix", "stage", "match_id", "opponent"), "encounter_count")
  if (nrow(rows) == 0) return(rows)
  advance_keys <- paste(rows$team, rows$parent_prefix, rows$stage, rows$match_id, rows$opponent, sep = "||")
  rows$advance_count <- vapply(advance_keys, function(key) {
    if (exists(key, envir = advances, inherits = FALSE)) get(key, envir = advances, inherits = FALSE) else 0
  }, numeric(1))
  context_keys <- paste(rows$team, rows$parent_prefix, rows$stage, sep = "||")
  context_totals <- tapply(rows$encounter_count, context_keys, sum)
  rows$context_count <- as.numeric(context_totals[context_keys])
  rows$node_id <- paste(rows$parent_prefix, rows$match_id, rows$opponent, sep = ">")
  rows$opponent_probability <- rows$encounter_count / rows$context_count
  rows$matchup_advance_probability <- rows$advance_count / rows$encounter_count
  rows$path_probability <- rows$encounter_count / simulations
  rows$advancement_contribution <- rows$advance_count / simulations
  rows$low_sample <- rows$encounter_count < 30
  rows[order(rows$team, match(rows$stage, knockout_stage_order), rows$parent_prefix, -rows$opponent_probability), ]
}

build_slot_rows <- function(slot_counts, slot_wins, simulations) {
  rows <- counter_rows(slot_counts, c("match_id", "stage", "side", "team"), "slot_count")
  if (nrow(rows) == 0) return(rows)
  keys <- paste(rows$match_id, rows$stage, rows$side, rows$team, sep = "||")
  rows$win_count <- vapply(keys, function(key) {
    if (exists(key, envir = slot_wins, inherits = FALSE)) get(key, envir = slot_wins, inherits = FALSE) else 0
  }, numeric(1))
  rows$slot_probability <- rows$slot_count / simulations
  rows$win_probability_given_slot <- rows$win_count / rows$slot_count
  rows$win_contribution <- rows$win_count / simulations
  rows[order(match(rows$stage, c(knockout_stage_order, "third_place")), rows$match_id, rows$side, -rows$slot_probability), ]
}

simulate_tournament <- function(models, ratings, forms, groups, schedule, results, simulations, draw_multiplier, annex_mapping) {
  teams <- unlist(groups, use.names = FALSE)
  counts <- matrix(0, nrow = length(teams), ncol = length(stage_order), dimnames = list(teams, stage_order))
  group_counts <- matrix(0, nrow = length(teams), ncol = 6,
    dimnames = list(teams, c("first", "second", "third", "fourth", "best_third", "qualified")))
  route_encounters <- new.env(hash = TRUE, parent = emptyenv())
  route_advances <- new.env(hash = TRUE, parent = emptyenv())
  slot_counts <- new.env(hash = TRUE, parent = emptyenv())
  slot_wins <- new.env(hash = TRUE, parent = emptyenv())
  group_matches <- schedule[tolower(schedule$stage) == "group", ]
  lookup <- observed_lookup(results)
  knockout_results <- knockout_result_lookup(results)
  for (s in seq_len(simulations)) {
    standings <- empty_standings(groups)
    reached <- setNames(rep("group_exit", length(teams)), teams)
    for (i in seq_len(nrow(group_matches))) {
      row <- group_matches[i, ]
      obs <- get_observed(lookup, row$group, row$team_1, row$team_2)
      if (is.null(obs)) {
        lambdas <- predict_goals(models, ratings, forms, row$team_1, row$team_2, neutral = TRUE)
        score <- simulate_score(lambdas[1], lambdas[2], draw_multiplier)
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
    for (group in names(rankings)) {
      ranked_teams <- rankings[[group]]$team
      group_counts[ranked_teams, c("first", "second", "third", "fourth")] <-
        group_counts[ranked_teams, c("first", "second", "third", "fourth")] + diag(4)
    }
    group_counts[best_thirds$team, "best_third"] <- group_counts[best_thirds$team, "best_third"] + 1
    group_counts[qualified, "qualified"] <- group_counts[qualified, "qualified"] + 1

    if (any(tolower(schedule$stage) != "group")) {
      reached <- simulate_official_knockout(
        models, ratings, forms, schedule, rankings, best_thirds, reached, draw_multiplier,
        annex_mapping, knockout_results, route_encounters, route_advances, slot_counts, slot_wins
      )
    } else {
      current <- c(unlist(lapply(rankings, function(x) x$team[1:2])), best_thirds$team)[1:32]
      for (stage in c("round_of_16", "quarter_final", "semi_final", "final", "champion")) {
        pairs <- knockout_pairs(current)
        winners <- mapply(
          function(a, b) simulate_knockout_match(models, ratings, forms, a, b, draw_multiplier)$winner,
          pairs$team_1, pairs$team_2
        )
        reached[winners] <- stage
        current <- winners
      }
    }
    for (team in teams) {
      idx <- match(reached[team], stage_order)
      counts[team, 1:idx] <- counts[team, 1:idx] + 1
    }
  }
  list(
    probabilities = as.data.frame(counts / simulations),
    group_positions = as.data.frame(group_counts / simulations),
    route_nodes = build_route_rows(route_encounters, route_advances, simulations),
    bracket_slots = build_slot_rows(slot_counts, slot_wins, simulations)
  )
}

prob_ci <- function(p, n) {
  se <- sqrt(p * (1 - p) / n)
  c(max(0, p - ci_z * se), min(1, p + ci_z * se))
}

write_outputs <- function(simulation, groups, metrics, models, simulations, comparison = NULL,
                          annex_mode = "official", current_group_status = NULL, analysis = NULL) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  prob <- simulation$probabilities
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
  group_positions <- simulation$group_positions
  group_positions$team <- rownames(group_positions)
  team_groups <- setNames(rep(names(groups), lengths(groups)), unlist(groups, use.names = FALSE))
  group_positions$group <- unname(team_groups[group_positions$team])
  group_positions <- group_positions[, c("group", "team", "first", "second", "third", "fourth", "best_third", "qualified")]
  write.csv(group_positions, file.path(output_dir, "group_position_probabilities.csv"), row.names = FALSE)
  write.csv(simulation$route_nodes, file.path(output_dir, "team_route_nodes.csv"), row.names = FALSE)
  write.csv(simulation$bracket_slots, file.path(output_dir, "bracket_slot_probabilities.csv"), row.names = FALSE)
  if (!is.null(current_group_status)) {
    write.csv(current_group_status, file.path(output_dir, "current_group_status.csv"), row.names = FALSE)
  }
  write.csv(metrics, file.path(output_dir, "model_metrics.csv"), row.names = FALSE)
  metadata <- data.frame(
    key = c("simulations", "seed", "results_snapshot", "draw_calibration_multiplier", "formal_data_approved", "annex_c_mode", "selected_poisson_model"),
    value = c(
      simulations, seed, basename(results_path),
      metrics$value[metrics$metric == "draw_calibration_multiplier"],
      !allow_unconfirmed_data,
      annex_mode,
      attr(models, "model_name")
    ),
    stringsAsFactors = FALSE
  )
  write.csv(metadata, file.path(output_dir, "run_metadata.csv"), row.names = FALSE)
  coef_rows <- data.frame(
    feature = names(coef(models$home)),
    home_goal_coefficient = as.numeric(coef(models$home)),
    away_goal_coefficient = as.numeric(coef(models$away))
  )
  write.csv(coef_rows, file.path(output_dir, "model_coefficients.csv"), row.names = FALSE)
  if (!is.null(analysis)) {
    write.csv(analysis$data_audit, file.path(output_dir, "data_quality_audit.csv"), row.names = FALSE)
    write.csv(analysis$feature_summary, file.path(output_dir, "feature_descriptive_statistics.csv"), row.names = FALSE)
    write.csv(analysis$coefficient_inference, file.path(output_dir, "poisson_coefficient_inference.csv"), row.names = FALSE)
    write.csv(analysis$fit_statistics, file.path(output_dir, "poisson_fit_statistics.csv"), row.names = FALSE)
    write.csv(analysis$diagnostics, file.path(output_dir, "poisson_diagnostics.csv"), row.names = FALSE)
    write.csv(analysis$goal_calibration, file.path(output_dir, "poisson_goal_calibration.csv"), row.names = FALSE)
    write.csv(analysis$model_comparison, file.path(output_dir, "poisson_model_comparison.csv"), row.names = FALSE)
    write.csv(analysis$rolling_validation, file.path(output_dir, "rolling_origin_validation.csv"), row.names = FALSE)
    write.csv(analysis$logistic$metrics, file.path(output_dir, "logistic_metrics.csv"), row.names = FALSE)
    write.csv(analysis$logistic$roc, file.path(output_dir, "logistic_roc_curve.csv"), row.names = FALSE)
    write.csv(analysis$logistic$inference, file.path(output_dir, "logistic_coefficient_inference.csv"), row.names = FALSE)
  }
  if (!is.null(comparison) && nrow(comparison$detail) > 0) {
    write.csv(comparison$detail, file.path(output_dir, "prediction_vs_actual.csv"), row.names = FALSE)
    write.csv(comparison$summary, file.path(output_dir, "prediction_vs_actual_summary.csv"), row.names = FALSE)
    write.csv(comparison$rating_updates, file.path(output_dir, "in_tournament_elo_updates.csv"), row.names = FALSE)
  }
}

set.seed(seed)
required_approval <- c(
  basename(groups_path),
  basename(schedule_path),
  basename(history_path),
  basename(results_path),
  "annex_c_full_mapping"
)
if (file.exists(elo_path)) required_approval <- c(required_approval, basename(elo_path))
check_data_approval(approval_path, unique(required_approval))
groups <- load_groups(groups_path)
schedule <- load_schedule(schedule_path, groups)
history <- load_history(history_path)
data_audit <- audit_history_data(history_path)
external_elo <- load_elo(elo_path)
historical_state <- build_samples_and_state(history, external_elo)
ratings <- historical_state$ratings
forms <- historical_state$forms
samples <- historical_state$samples
rolling_validation <- run_rolling_validation(samples)
selected_model <- choose_model(rolling_validation)
models <- fit_models(samples, selected_model)
draw_multiplier <- fit_draw_calibration(models, samples)
metrics <- evaluate_model(models, samples, draw_multiplier)
model_comparison <- run_model_comparison(samples)
logistic <- fit_logistic_baseline(samples)
analysis_outputs <- list(
  data_audit = data_audit,
  feature_summary = feature_summary_rows(samples),
  coefficient_inference = coefficient_inference(models),
  fit_statistics = glm_fit_statistics(models),
  diagnostics = poisson_diagnostics(models),
  goal_calibration = goal_calibration_rows(models),
  model_comparison = model_comparison,
  rolling_validation = rolling_validation,
  logistic = logistic
)
results <- load_results(results_path)
annex_mapping <- load_annex_mapping(annex_path)
comparison <- compare_observed_results(models, ratings, forms, schedule, results, draw_multiplier)
current_group_status <- compute_current_group_status(groups, schedule, results)
simulation <- simulate_tournament(
  models, comparison$ratings, comparison$forms, groups, schedule, results, simulations, draw_multiplier, annex_mapping
)
annex_mode <- ifelse(nrow(annex_mapping) > 0, "official", "debug_candidate_matching")
write_outputs(simulation, groups, metrics, models, simulations, comparison, annex_mode, current_group_status, analysis_outputs)

cat(sprintf("Simulation complete: %s runs\n", simulations))
cat(sprintf("Draw calibration multiplier: %.4f\n", draw_multiplier))
cat(sprintf("Selected Poisson specification: %s\n", selected_model))
cat(sprintf("Output directory: %s\n", output_dir))
