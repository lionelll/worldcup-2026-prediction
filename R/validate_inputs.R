#!/usr/bin/env Rscript

# Validate input CSV files for the 2026 World Cup prediction report.
# This script uses base R only.

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) {
    return(args[[pos + 1]])
  }
  default
}

groups_path <- get_arg("--groups", "data/worldcup_2026_groups.csv")
schedule_path <- get_arg("--schedule", "data/worldcup_2026_schedule.csv")
history_path <- get_arg("--history", "data/historical_matches.csv")
results_path <- get_arg("--results", "data/worldcup_2026_results_asof_2026-06-20.csv")
annex_path <- get_arg("--annex-c", "data/annex_c_full_mapping.csv")
allow_unconfirmed_data <- "--allow-unconfirmed-data" %in% args

required_groups <- c("group", "slot", "team")
required_schedule <- c(
  "match_id", "stage", "group", "match_date", "team_1", "team_2",
  "venue", "host_country", "team_1_slot", "team_2_slot"
)
required_history <- c(
  "date", "home_team", "away_team", "home_score", "away_score",
  "tournament", "country", "neutral"
)

cutoff <- as.Date("2026-06-10")
train_start <- as.Date("2010-01-01")
train_end <- as.Date("2024-12-31")
test_start <- as.Date("2025-01-01")
test_end <- cutoff

stop_missing <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Required file not found: %s", path), call. = FALSE)
  }
}

require_columns <- function(df, required, path) {
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop(sprintf("%s is missing required columns: %s", path, paste(missing, collapse = ", ")), call. = FALSE)
  }
}

read_required_csv <- function(path) {
  stop_missing(path)
  read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
}

validate_groups <- function(path) {
  df <- read_required_csv(path)
  require_columns(df, required_groups, path)
  if (nrow(df) != 48) {
    stop(sprintf("%s must contain exactly 48 teams, found %s", path, nrow(df)), call. = FALSE)
  }
  expected_groups <- LETTERS[1:12]
  bad_groups <- setdiff(unique(df$group), expected_groups)
  if (length(bad_groups) > 0) {
    stop(sprintf("Invalid group labels: %s", paste(bad_groups, collapse = ", ")), call. = FALSE)
  }
  counts <- table(df$group)
  if (length(counts) != 12 || any(counts != 4)) {
    stop("Groups file must contain 12 groups and exactly 4 teams per group.", call. = FALSE)
  }
  if (any(duplicated(df$team))) {
    stop("Groups file contains duplicate teams.", call. = FALSE)
  }
  slot_ok <- mapply(function(g, s) startsWith(s, g), df$group, df$slot)
  if (!all(slot_ok)) {
    stop("Every slot must start with its group letter, e.g. A1 for group A.", call. = FALSE)
  }
  invisible(TRUE)
}

validate_schedule <- function(path) {
  df <- read_required_csv(path)
  require_columns(df, required_schedule, path)
  if (nrow(df) == 0) {
    stop("Schedule file contains no rows.", call. = FALSE)
  }
  dates <- as.Date(df$match_date)
  if (any(is.na(dates))) {
    stop("Schedule contains invalid match_date values.", call. = FALSE)
  }
  if (any(dates < as.Date("2026-01-01"))) {
    stop("Schedule contains dates before 2026.", call. = FALSE)
  }
  if (!any(tolower(df$stage) == "group")) {
    stop("Schedule must include group-stage rows with stage='group'.", call. = FALSE)
  }
  invalid_groups <- setdiff(unique(df$group[df$group != ""]), LETTERS[1:12])
  if (length(invalid_groups) > 0) {
    stop(sprintf("Schedule contains invalid group labels: %s", paste(invalid_groups, collapse = ", ")), call. = FALSE)
  }
  invisible(TRUE)
}

validate_history <- function(path) {
  df <- read_required_csv(path)
  require_columns(df, required_history, path)
  if (nrow(df) == 0) {
    stop("Historical match file contains no rows.", call. = FALSE)
  }
  dates <- as.Date(df$date)
  if (any(is.na(dates))) {
    stop("Historical match file contains invalid date values.", call. = FALSE)
  }
  if (any(dates > cutoff)) {
    stop(sprintf("Historical match file contains matches after cutoff %s.", cutoff), call. = FALSE)
  }
  if (!any(dates >= train_start & dates <= train_end)) {
    stop("Historical match file has no training rows in 2010-01-01..2024-12-31.", call. = FALSE)
  }
  if (!any(dates >= test_start & dates <= test_end)) {
    stop("Historical match file has no test rows in 2025-01-01..2026-06-10.", call. = FALSE)
  }
  if (any(is.na(as.integer(df$home_score))) || any(is.na(as.integer(df$away_score)))) {
    stop("Scores must be integers.", call. = FALSE)
  }
  if (any(as.integer(df$home_score) < 0) || any(as.integer(df$away_score) < 0)) {
    stop("Scores must be non-negative.", call. = FALSE)
  }
  neutral_values <- tolower(trimws(as.character(df$neutral)))
  allowed <- c("true", "false", "1", "0", "yes", "no")
  if (any(!neutral_values %in% allowed)) {
    stop("neutral must be boolean-like: true/false/1/0/yes/no.", call. = FALSE)
  }
  invisible(TRUE)
}

validate_results <- function(path) {
  df <- read_required_csv(path)
  required <- c("match_date", "group", "team_1", "team_2", "team_1_score", "team_2_score")
  require_columns(df, required, path)
  if (any(is.na(as.Date(df$match_date)))) stop("Results contain invalid match_date values.", call. = FALSE)
  if (any(is.na(as.integer(df$team_1_score))) || any(is.na(as.integer(df$team_2_score)))) {
    stop("Result scores must be integers.", call. = FALSE)
  }
  if ("stage" %in% names(df) && any(tolower(df$stage) != "group")) {
    knockout <- df[tolower(df$stage) != "group", , drop = FALSE]
    require_columns(knockout, c("match_id", "winner", "decided_by"), path)
    if (any(knockout$match_id == "") || any(knockout$winner == "")) {
      stop("Every knockout result must include match_id and winner.", call. = FALSE)
    }
    allowed <- c("90min", "extra_time", "penalties")
    if (any(!knockout$decided_by %in% allowed)) {
      stop("decided_by must be 90min, extra_time, or penalties.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

canonical_groups <- function(x) paste(sort(unique(strsplit(toupper(gsub("[^A-L]", "", x)), "")[[1]])), collapse = "")

validate_annex <- function(path) {
  if (!file.exists(path)) {
    if (allow_unconfirmed_data) {
      warning("Annex C mapping is absent; validation continues only for debug mode.", call. = FALSE)
      return(invisible(FALSE))
    }
    stop(sprintf("Official Annex C mapping not found: %s", path), call. = FALSE)
  }
  df <- read_required_csv(path)
  require_columns(df, c("qualified_groups", "match_id", "third_group"), path)
  df$qualified_groups <- vapply(df$qualified_groups, canonical_groups, character(1))
  if (length(unique(df$qualified_groups)) != choose(12, 8)) {
    stop("Annex C must contain 495 unique combinations.", call. = FALSE)
  }
  if (any(table(df$qualified_groups) != 8)) {
    stop("Every Annex C combination must contain exactly eight assignments.", call. = FALSE)
  }
  invisible(TRUE)
}

validate_groups(groups_path)
validate_schedule(schedule_path)
validate_history(history_path)
validate_results(results_path)
validate_annex(annex_path)

cat("Input validation passed.\n")
cat(sprintf("Groups: %s\n", groups_path))
cat(sprintf("Schedule: %s\n", schedule_path))
cat(sprintf("History: %s\n", history_path))
cat(sprintf("Results: %s\n", results_path))
cat(sprintf("Annex C: %s\n", ifelse(file.exists(annex_path), annex_path, "missing (debug only)")))
cat(sprintf("Date cutoff: %s\n", cutoff))
