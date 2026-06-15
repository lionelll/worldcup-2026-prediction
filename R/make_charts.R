#!/usr/bin/env Rscript

# Generate report SVG charts from R model outputs.
# Dependencies: base R only.

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) return(args[[pos + 1]])
  default
}

output_dir <- get_arg("--output", "output")
figure_dir <- file.path(output_dir, "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

read_required <- function(path) {
  if (!file.exists(path)) stop(sprintf("Required output file not found: %s", path), call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE)
}

champion <- read_required(file.path(output_dir, "champion_probabilities.csv"))
four <- read_required(file.path(output_dir, "final_four_probabilities.csv"))
stages <- read_required(file.path(output_dir, "team_stage_probabilities.csv"))

plot_bar <- function(df, title, path, color) {
  svg(path, width = 9, height = 5.5)
  op <- par(mar = c(5, 9, 4, 2))
  values <- rev(df$probability)
  labels <- rev(df$team)
  bp <- barplot(values, horiz = TRUE, names.arg = labels, las = 1, col = color, border = NA,
                xlim = c(0, max(values, df$ci_upper, na.rm = TRUE) * 1.15),
                main = title, xlab = "概率")
  if (all(c("ci_lower", "ci_upper") %in% names(df))) {
    arrows(rev(df$ci_lower), bp, rev(df$ci_upper), bp, angle = 90, code = 3, length = 0.04)
  }
  text(values, bp, labels = sprintf("%.1f%%", values * 100), pos = 4, cex = 0.8)
  par(op)
  dev.off()
}

plot_progression <- function(df, path, top_n = 8) {
  stage_cols <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion")
  stage_labels <- c("出线", "16强", "8强", "四强", "决赛", "夺冠")
  df <- df[order(-df$champion), ][1:min(top_n, nrow(df)), ]
  svg(path, width = 10, height = 5.8)
  op <- par(mar = c(5, 5, 4, 9), xpd = TRUE)
  plot(1:length(stage_cols), rep(0, length(stage_cols)), type = "n", ylim = c(0, 1), xaxt = "n",
       xlab = "阶段", ylab = "晋级概率", main = "热门球队晋级概率阶梯图")
  axis(1, at = 1:length(stage_cols), labels = stage_labels)
  cols <- c("#2E74B5", "#70AD47", "#ED7D31", "#A64D79", "#5B9BD5", "#FFC000", "#4472C4", "#9E480E")
  for (i in seq_len(nrow(df))) {
    y <- as.numeric(df[i, stage_cols])
    lines(1:length(stage_cols), y, type = "b", col = cols[(i - 1) %% length(cols) + 1], lwd = 2, pch = 16)
  }
  legend("right", inset = c(-0.28, 0), legend = df$team, col = cols[seq_len(nrow(df))], lwd = 2, pch = 16, bty = "n")
  par(op)
  dev.off()
}

plot_funnel <- function(df, path) {
  df <- df[order(-df$champion), ][1, ]
  stages <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion")
  labels <- c("出线", "16强", "8强", "四强", "决赛", "夺冠")
  values <- as.numeric(df[stages])
  svg(path, width = 8, height = 5.4)
  op <- par(mar = c(2, 2, 4, 2))
  plot(0, 0, type = "n", xlim = c(0, 1), ylim = c(0, length(stages) + 1), axes = FALSE,
       xlab = "", ylab = "", main = paste0(df$team, " 单队晋级漏斗图"))
  for (i in seq_along(stages)) {
    y <- length(stages) - i + 1
    w <- max(values[i], 0.03)
    rect(0.5 - w / 2, y - 0.35, 0.5 + w / 2, y + 0.35, col = "#2E74B5", border = NA)
    text(0.5, y, sprintf("%s %.1f%%", labels[i], values[i] * 100), col = "white", font = 2)
  }
  par(op)
  dev.off()
}

plot_bar(champion, "冠军概率 Top 10", file.path(figure_dir, "champion_probability_top10.svg"), "#2E74B5")
plot_bar(four, "四强概率 Top 10", file.path(figure_dir, "final_four_probability_top10.svg"), "#70AD47")
plot_progression(stages, file.path(figure_dir, "advancement_progression.svg"))
plot_funnel(stages, file.path(figure_dir, "top_team_funnel.svg"))

cat(sprintf("Charts written to %s\n", figure_dir))

