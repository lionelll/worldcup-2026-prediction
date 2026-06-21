#!/usr/bin/env Rscript

# Validate route, group-position, and bracket-slot outputs from the R simulator.

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) return(args[[pos + 1]])
  default
}

output_dir <- get_arg("--output", "output")
read_output <- function(name) {
  path <- file.path(output_dir, name)
  if (!file.exists(path)) stop(sprintf("Missing output: %s", path), call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
}

routes <- read_output("team_route_nodes.csv")
slots <- read_output("bracket_slot_probabilities.csv")
groups <- read_output("group_position_probabilities.csv")
stages <- read_output("team_stage_probabilities.csv")
metadata <- read_output("run_metadata.csv")
current_status <- read_output("current_group_status.csv")

tol <- 1e-8
context_key <- paste(routes$team, routes$parent_prefix, routes$stage, sep = "||")
context_sums <- tapply(routes$opponent_probability, context_key, sum)
stopifnot(max(abs(context_sums - 1)) < tol)

slot_key <- paste(slots$match_id, slots$side, sep = "||")
slot_sums <- tapply(slots$slot_probability, slot_key, sum)
stopifnot(max(abs(slot_sums - 1)) < tol)

stopifnot(abs(sum(stages$champion) - 1) < tol)
stopifnot(max(abs(rowSums(groups[, c("first", "second", "third", "fourth")]) - 1)) < tol)

qualified <- setNames(groups$qualified, groups$team)
stage_qualified <- setNames(stages$round_of_32, stages$team)
common <- intersect(names(qualified), names(stage_qualified))
stopifnot(max(abs(qualified[common] - stage_qualified[common])) < tol)

next_stage <- c(
  round_of_32 = "round_of_16",
  round_of_16 = "quarter_final",
  quarter_final = "semi_final",
  semi_final = "final",
  final = "champion"
)
for (stage in names(next_stage)) {
  contributions <- tapply(
    routes$advancement_contribution[routes$stage == stage],
    routes$team[routes$stage == stage],
    sum
  )
  target <- setNames(stages[[next_stage[[stage]]]], stages$team)
  common <- intersect(names(contributions), names(target))
  stopifnot(max(abs(contributions[common] - target[common])) < tol)
}

stopifnot(all(routes$low_sample == (routes$encounter_count < 30)))
stopifnot(all(current_status$remaining_matches == 3 - current_status$played))
stopifnot(all(current_status$top2_status %in% c("已锁定前二", "仍竞争前二", "已无缘前二")))
stopifnot(all(current_status$points >= 0 & current_status$points <= 9))
for (group in unique(current_status$group)) {
  group_rows <- current_status[current_status$group == group, , drop = FALSE]
  stopifnot(setequal(group_rows$current_rank, 1:4))
}
meta <- setNames(metadata$value, metadata$key)
if (tolower(meta[["formal_data_approved"]]) == "true") {
  stopifnot(meta[["annex_c_mode"]] == "official")
}

cat("Route output validation passed.\n")
