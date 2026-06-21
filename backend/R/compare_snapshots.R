#!/usr/bin/env Rscript

# Compare two team-stage probability snapshots produced with the same seed.

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) return(args[[pos + 1]])
  default
}

before_path <- get_arg("--before", "/private/tmp/team_stage_probabilities_asof_2026-06-19.csv")
after_path <- get_arg("--after", "output/team_stage_probabilities.csv")
output_path <- get_arg("--output", "output/snapshot_change_2026-06-19_to_2026-06-20.csv")

before <- read.csv(before_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
after <- read.csv(after_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
stages <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion")
missing <- setdiff(c("team", stages), intersect(names(before), names(after)))
if (length(missing) > 0) stop(sprintf("Snapshot columns missing: %s", paste(missing, collapse = ", ")), call. = FALSE)

comparison <- merge(before[, c("team", stages)], after[, c("team", stages)], by = "team", suffixes = c("_before", "_after"))
for (stage in stages) {
  comparison[[paste0(stage, "_change")]] <- comparison[[paste0(stage, "_after")]] - comparison[[paste0(stage, "_before")]]
}
comparison <- comparison[order(-abs(comparison$round_of_32_change), comparison$team), ]
write.csv(comparison, output_path, row.names = FALSE)
cat(sprintf("Snapshot comparison written to %s\n", output_path))
