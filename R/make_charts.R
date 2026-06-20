#!/usr/bin/env Rscript

# Generate report PDF charts from R model outputs.
# Dependencies: base R only.

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default) {
  pos <- match(flag, args)
  if (!is.na(pos) && pos < length(args)) return(args[[pos + 1]])
  default
}

output_dir <- get_arg("--output", "output")
approval_path <- get_arg("--approval", file.path("data", "data_approval.csv"))
allow_unconfirmed_data <- "--allow-unconfirmed-data" %in% args
figure_dir <- file.path(output_dir, "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

approved_value <- function(x) {
  tolower(trimws(as.character(x))) %in% c("true", "1", "yes", "y", "approved")
}

check_data_approval <- function(path) {
  if (allow_unconfirmed_data) {
    warning("--allow-unconfirmed-data is enabled. Charts are for debugging only, not for the formal report.", call. = FALSE)
    return(invisible(TRUE))
  }
  required <- c(
    "worldcup_2026_groups.csv",
    "worldcup_2026_schedule.csv",
    "worldcup_2026_results_asof_2026-06-20.csv",
    "historical_matches.csv",
    "annex_c_full_mapping"
  )
  if (!file.exists(path)) {
    stop(sprintf("Data approval file not found: %s. Confirm data sources before generating formal charts.", path), call. = FALSE)
  }
  df <- read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
  missing <- setdiff(c("file", "approved"), names(df))
  if (length(missing) > 0) {
    stop(sprintf("%s is missing required columns: %s", path, paste(missing, collapse = ", ")), call. = FALSE)
  }
  missing_rows <- setdiff(required, df$file)
  if (length(missing_rows) > 0) {
    stop(sprintf("Data approval is missing rows for: %s", paste(missing_rows, collapse = ", ")), call. = FALSE)
  }
  pending <- df[df$file %in% required & !approved_value(df$approved), , drop = FALSE]
  if (nrow(pending) > 0) {
    stop(sprintf(
      "Data source confirmation required before formal chart generation: %s. Use --allow-unconfirmed-data for code debugging only.",
      paste(pending$file, collapse = ", ")
    ), call. = FALSE)
  }
  invisible(TRUE)
}

check_data_approval(approval_path)

read_required <- function(path) {
  if (!file.exists(path)) stop(sprintf("Required output file not found: %s", path), call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE)
}

champion <- read_required(file.path(output_dir, "champion_probabilities.csv"))
four <- read_required(file.path(output_dir, "final_four_probabilities.csv"))
stages <- read_required(file.path(output_dir, "team_stage_probabilities.csv"))
group_positions <- read_required(file.path(output_dir, "group_position_probabilities.csv"))
route_nodes <- read_required(file.path(output_dir, "team_route_nodes.csv"))
bracket_slots <- read_required(file.path(output_dir, "bracket_slot_probabilities.csv"))
current_group_status <- read_required(file.path(output_dir, "current_group_status.csv"))
metadata <- read_required(file.path(output_dir, "run_metadata.csv"))
data_audit <- read_required(file.path(output_dir, "data_quality_audit.csv"))
fit_statistics <- read_required(file.path(output_dir, "poisson_fit_statistics.csv"))
poisson_diagnostics <- read_required(file.path(output_dir, "poisson_diagnostics.csv"))
goal_calibration <- read_required(file.path(output_dir, "poisson_goal_calibration.csv"))
model_comparison <- read_required(file.path(output_dir, "poisson_model_comparison.csv"))
rolling_validation <- read_required(file.path(output_dir, "rolling_origin_validation.csv"))
logistic_metrics <- read_required(file.path(output_dir, "logistic_metrics.csv"))
logistic_roc <- read_required(file.path(output_dir, "logistic_roc_curve.csv"))
schedule <- read.csv(file.path("data", "worldcup_2026_schedule.csv"), stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
formal_run <- tolower(metadata$value[metadata$key == "formal_data_approved"][1]) == "true"
preview_label <- ifelse(formal_run, "", "调试预览：数据与 Annex C 尚未确认")
chart_family <- "sans"
if (identical(Sys.info()[["sysname"]], "Darwin")) {
  quartzFonts(CJK = quartzFont(rep("Heiti SC", 4)))
  chart_family <- "CJK"
}

open_png <- function(path, width, height, res = 180) {
  args <- list(filename = path, width = width, height = height, units = "px", res = res, bg = "white")
  if (identical(Sys.info()[["sysname"]], "Darwin")) args$type <- "quartz"
  else if (capabilities("cairo")) args$type <- "cairo"
  do.call(png, args)
}

plot_data_quality <- function(audit, path) {
  rows <- audit[audit$section == "summary" & audit$item != "raw_rows", , drop = FALSE]
  labels <- c(
    retained_rows = "保留样本", rows_after_cutoff = "截止日后",
    duplicate_match_keys = "重复键", invalid_dates = "无效日期",
    invalid_scores = "无效比分", high_score_matches_total_ge_10 = "总进球≥10"
  )
  open_png(path, 1800, 1000)
  op <- par(mar = c(5, 8, 4, 2), family = chart_family)
  values <- rows$value
  plotted <- log10(values + 1)
  names(plotted) <- unname(labels[rows$item])
  bp <- barplot(plotted, horiz = TRUE, las = 1, col = c("#237A57", rep("#D97706", length(values) - 1)),
    border = NA, main = "历史数据质量审计", xlab = "记录数（log10(数量+1)）",
    xlim = c(0, max(plotted) * 1.18))
  text(plotted, bp, labels = format(values, big.mark = ",", scientific = FALSE), pos = 4, cex = 0.82)
  draw_preview_label()
  par(op)
  dev.off()
}

plot_poisson_diagnostics <- function(df, calibration, path) {
  open_png(path, 2400, 1800)
  op <- par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1.5), family = chart_family)
  colors <- c(home = "#246B8E", away = "#D97706")
  for (outcome in c("home", "away")) {
    rows <- df[df$outcome == outcome, , drop = FALSE]
    sample_rows <- rows[seq(1, nrow(rows), length.out = min(5000, nrow(rows))), , drop = FALSE]
    plot(sample_rows$fitted, sample_rows$deviance_residual, pch = 16, cex = 0.28,
      col = grDevices::adjustcolor(colors[outcome], alpha.f = 0.28),
      xlab = "拟合进球", ylab = "Deviance residual", main = paste0(ifelse(outcome == "home", "先列队", "后列队"), "残差-拟合图"))
    abline(h = 0, lty = 2, col = "#555555")
  }
  max_cook <- quantile(df$cooks_distance, 0.995, na.rm = TRUE)
  plot(df$observation, pmin(df$cooks_distance, max_cook), pch = 16, cex = 0.2,
    col = grDevices::adjustcolor(colors[df$outcome], alpha.f = 0.25),
    xlab = "观测序号", ylab = "Cook distance（截至99.5%分位）", main = "影响点检查")
  plot(0, 0, type = "n", xlim = range(c(calibration$mean_predicted_goals, calibration$mean_observed_goals)),
    ylim = range(c(calibration$mean_predicted_goals, calibration$mean_observed_goals)),
    xlab = "分箱平均预测进球", ylab = "分箱平均实际进球", main = "进球校准")
  abline(0, 1, lty = 2, col = "#555555")
  for (outcome in c("home", "away")) {
    rows <- calibration[calibration$outcome == outcome, ]
    lines(rows$mean_predicted_goals, rows$mean_observed_goals, type = "b", pch = 16, lwd = 2, col = colors[outcome])
  }
  legend("topleft", c("先列队", "后列队"), col = colors, lwd = 2, pch = 16, bty = "n")
  draw_preview_label()
  par(op)
  dev.off()
}

plot_model_comparison <- function(df, rolling, path) {
  rolling_mean <- aggregate(cbind(log_loss, brier_score) ~ model, rolling, mean)
  order_index <- order(rolling_mean$log_loss)
  rolling_mean <- rolling_mean[order_index, ]
  labels <- c(elo = "Elo", context = "Elo+场地赛事", form = "+近期状态", full = "+完整攻防")
  open_png(path, 2000, 1050)
  op <- par(mar = c(5, 9, 4, 2), family = chart_family)
  y <- seq_len(nrow(rolling_mean))
  x_range <- range(rolling_mean$log_loss) + c(-0.004, 0.008)
  plot(rolling_mean$log_loss, y, pch = 19, cex = 1.6, col = "#246B8E", yaxt = "n",
    xlim = x_range, ylim = c(0.5, nrow(rolling_mean) + 0.5),
    main = "候选泊松模型滚动验证", xlab = "平均 Log Loss（越低越好）", ylab = "")
  axis(2, at = y, labels = unname(labels[rolling_mean$model]), las = 1)
  abline(v = min(rolling_mean$log_loss), lty = 2, col = "#237A57")
  text(rolling_mean$log_loss, y, sprintf("%.4f", rolling_mean$log_loss), pos = 4, cex = 0.85)
  draw_preview_label()
  par(op)
  dev.off()
}

plot_logistic_roc <- function(roc, metrics, path) {
  auc <- metrics$value[metrics$metric == "auc"][1]
  roc <- roc[order(roc$fpr, roc$tpr), ]
  open_png(path, 1200, 1100)
  op <- par(mar = c(5, 5, 4, 2), family = chart_family)
  plot(roc$fpr, roc$tpr, type = "l", lwd = 3, col = "#A61B29", xlim = c(0, 1), ylim = c(0, 1),
    xlab = "假阳性率", ylab = "真阳性率", main = sprintf("二元逻辑回归 ROC（AUC = %.3f）", auc))
  abline(0, 1, lty = 2, col = "#777777")
  grid(col = "#E5E7EB")
  draw_preview_label()
  par(op)
  dev.off()
}

draw_preview_label <- function() {
  if (preview_label != "") {
    mtext(preview_label, side = 1, line = -1.2, adj = 1, col = "#A61B29", cex = 0.7, font = 2)
  }
}

plot_group_overview <- function(df, current_status, path) {
  open_png(path, 3200, 1800)
  op <- par(mar = c(1.5, 1.5, 3.5, 1.5), xpd = NA, family = chart_family)
  plot.new()
  plot.window(xlim = c(0, 4), ylim = c(0, 3))
  title("整体路径图 A：A-L 组晋级概率概览", cex.main = 1.45, font.main = 2)
  for (index in seq_along(LETTERS[1:12])) {
    group <- LETTERS[index]
    col <- (index - 1) %% 4
    row <- 2 - floor((index - 1) / 4)
    x0 <- col + 0.04
    x1 <- col + 0.96
    y0 <- row + 0.08
    y1 <- row + 0.92
    rect(x0, y0, x1, y1, col = "#F7F9FC", border = "#AAB7C4", lwd = 1.2)
    rect(x0, y1 - 0.16, x1, y1, col = "#173F5F", border = NA)
    text((x0 + x1) / 2, y1 - 0.08, paste0("GROUP ", group), col = "white", font = 2, cex = 0.92)
    rows <- df[df$group == group, , drop = FALSE]
    rows <- rows[order(-rows$qualified), ]
    for (i in seq_len(nrow(rows))) {
      y <- y1 - 0.235 - (i - 1) * 0.145
      text(x0 + 0.04, y, rows$team[i], adj = 0, font = 2, cex = 0.74)
      label <- sprintf("1:%2.0f  2:%2.0f  3:%2.0f  出线:%2.0f%%",
        rows$first[i] * 100, rows$second[i] * 100, rows$third[i] * 100, rows$qualified[i] * 100)
      text(x1 - 0.04, y, label, adj = 1, cex = 0.62, col = "#334E68")
      status <- current_status[current_status$team == rows$team[i], , drop = FALSE]
      if (nrow(status) > 0) {
        status_label <- sprintf("当前 %d 分 · %s", status$points[1], status$top2_status[1])
        text(x0 + 0.04, y - 0.045, status_label, adj = 0, cex = 0.48,
          col = ifelse(status$top2_status[1] == "已锁定前二", "#237A57", "#6B7280"))
      }
    }
    text(x0 + 0.04, y0 + 0.055, "1/2/3 为小组名次概率；出线含最佳第三名", adj = 0, cex = 0.52, col = "#6B7280")
  }
  draw_preview_label()
  par(op)
  dev.off()
}

slot_summary <- function(match_id, side, rows) {
  candidates <- rows[rows$match_id == match_id & rows$side == side, , drop = FALSE]
  candidates <- candidates[order(-candidates$slot_probability), ]
  if (nrow(candidates) == 0) return("待定")
  top <- candidates[seq_len(min(2, nrow(candidates))), , drop = FALSE]
  labels <- sprintf("%s %.0f%%", top$team, top$slot_probability * 100)
  other <- max(0, 1 - sum(top$slot_probability))
  if (other > 0.005) labels <- c(labels, sprintf("其他 %.0f%%", other * 100))
  paste(labels, collapse = " / ")
}

plot_bracket_overview <- function(slots, schedule, path) {
  stage_order <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final")
  bracket <- schedule[tolower(schedule$stage) %in% stage_order, , drop = FALSE]
  open_png(path, 4200, 2500)
  op <- par(mar = c(1.5, 1.5, 4, 1.5), xpd = NA, family = chart_family)
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  title("整体路径图 B：32 强至决赛槽位概率", cex.main = 1.5, font.main = 2)
  bracket$match_id <- toupper(bracket$match_id)
  rownames(bracket) <- bracket$match_id
  child_ids <- function(match_id) {
    row <- bracket[match_id, , drop = FALSE]
    exprs <- c(row$team_1_slot, row$team_2_slot)
    winner_numbers <- as.integer(sub("^W", "", exprs[grepl("^W[0-9]+$", exprs)]))
    ids <- sprintf("M%03d", winner_numbers)
    ids[ids %in% bracket$match_id]
  }
  leaf_ids <- function(match_id) {
    children <- child_ids(match_id)
    if (length(children) == 0) return(match_id)
    unlist(lapply(children, leaf_ids), use.names = FALSE)
  }
  semifinal_ids <- child_ids("M104")
  if (length(semifinal_ids) != 2) stop("Final M104 must reference exactly two semifinals.", call. = FALSE)
  left_root <- semifinal_ids[1]
  right_root <- semifinal_ids[2]
  left_leaves <- leaf_ids(left_root)
  right_leaves <- leaf_ids(right_root)
  positions <- list()
  leaf_y <- seq(0.91, 0.09, length.out = max(length(left_leaves), length(right_leaves)))
  for (i in seq_along(left_leaves)) positions[[left_leaves[i]]] <- c(0.055, leaf_y[i])
  for (i in seq_along(right_leaves)) positions[[right_leaves[i]]] <- c(0.945, leaf_y[i])
  stage_x_left <- c(round_of_32 = 0.055, round_of_16 = 0.17, quarter_final = 0.285, semi_final = 0.40)
  stage_x_right <- c(round_of_32 = 0.945, round_of_16 = 0.83, quarter_final = 0.715, semi_final = 0.60)
  assign_internal <- function(match_id, side) {
    children <- child_ids(match_id)
    if (length(children) == 0) return(positions[[match_id]])
    child_positions <- lapply(children, assign_internal, side = side)
    stage <- tolower(bracket[match_id, "stage"])
    x <- if (side == "left") stage_x_left[[stage]] else stage_x_right[[stage]]
    positions[[match_id]] <<- c(x, mean(vapply(child_positions, `[[`, numeric(1), 2)))
    positions[[match_id]]
  }
  assign_internal(left_root, "left")
  assign_internal(right_root, "right")
  positions[["M104"]] <- c(0.50, 0.50)

  text(c(0.055, 0.17, 0.285, 0.40, 0.50, 0.60, 0.715, 0.83, 0.945), 0.972,
    c("32强", "16强", "8强", "半决赛", "决赛", "半决赛", "8强", "16强", "32强"),
    font = 2, cex = 0.82, col = "#173F5F")
  half_w <- 0.050
  for (match_id in bracket$match_id) {
    target <- positions[[match_id]]
    for (source_id in child_ids(match_id)) {
      source <- positions[[source_id]]
      direction <- sign(target[1] - source[1])
      segments(source[1] + direction * half_w, source[2], target[1] - direction * half_w, target[2],
        col = "#B8C4CE", lwd = 1.25)
    }
  }
  for (match_id in bracket$match_id) {
    pos <- positions[[match_id]]
    stage <- tolower(bracket[match_id, "stage"])
    box_h <- if (stage == "round_of_32") 0.040 else 0.047
    rect(pos[1] - half_w, pos[2] - box_h, pos[1] + half_w, pos[2] + box_h,
      col = "white", border = "#54728C", lwd = 1.1)
    text(pos[1], pos[2] + box_h * 0.58, match_id, font = 2, cex = 0.58, col = "#A61B29")
    text(pos[1], pos[2], slot_summary(match_id, "team_1", slots), cex = 0.46)
    text(pos[1], pos[2] - box_h * 0.58, slot_summary(match_id, "team_2", slots), cex = 0.46)
  }
  draw_preview_label()
  par(op)
  dev.off()
}

aggregate_team_stage <- function(rows, team, stage) {
  x <- rows[rows$team == team & rows$stage == stage, , drop = FALSE]
  if (nrow(x) == 0) return(data.frame())
  encounters <- aggregate(encounter_count ~ opponent, x, sum)
  advances <- aggregate(advance_count ~ opponent, x, sum)
  x <- merge(encounters, advances, by = "opponent", all = TRUE)
  x$encounter_count[is.na(x$encounter_count)] <- 0
  x$advance_count[is.na(x$advance_count)] <- 0
  total <- sum(x$encounter_count)
  x$opponent_probability <- x$encounter_count / total
  x$matchup_advance_probability <- ifelse(x$encounter_count > 0, x$advance_count / x$encounter_count, 0)
  simulations <- as.numeric(metadata$value[metadata$key == "simulations"][1])
  x$advancement_contribution <- x$advance_count / simulations
  x$low_sample <- x$encounter_count < 30
  x[order(-x$opponent_probability), ]
}

top_opponents <- function(rows, limit = 5) {
  if (nrow(rows) <= limit) return(rows)
  top <- rows[seq_len(limit), , drop = FALSE]
  rest <- rows[-seq_len(limit), , drop = FALSE]
  other_encounters <- sum(rest$encounter_count)
  other_advances <- sum(rest$advance_count)
  other <- data.frame(
    opponent = "其他",
    encounter_count = other_encounters,
    advance_count = other_advances,
    opponent_probability = sum(rest$opponent_probability),
    matchup_advance_probability = ifelse(other_encounters > 0, other_advances / other_encounters, 0),
    advancement_contribution = sum(rest$advancement_contribution),
    low_sample = other_encounters < 30,
    stringsAsFactors = FALSE
  )
  rbind(top, other)
}

plot_team_route <- function(team, route_rows, stages, group_positions, path) {
  stage_keys <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final")
  stage_labels <- c("32强对阵", "16强对阵", "8强对阵", "半决赛", "决赛")
  stage_prob_keys <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final")
  team_stage <- stages[stages$team == team, , drop = FALSE]
  team_group <- group_positions[group_positions$team == team, , drop = FALSE]
  open_png(path, 4200, 2200)
  op <- par(mar = c(1.5, 1.5, 4, 1.5), xpd = NA, family = chart_family)
  plot.new()
  plot.window(xlim = c(0, 5), ylim = c(0, 1))
  title(paste0(team, "：条件晋级路线图"), cex.main = 1.55, font.main = 2)
  timeline_x <- seq(0.25, 4.75, length.out = 7)
  for (i in 1:6) arrows(timeline_x[i] + 0.23, 0.86, timeline_x[i + 1] - 0.23, 0.86,
    length = 0.06, col = "#90A4AE", lwd = 1.5)
  rect(timeline_x[1] - 0.25, 0.77, timeline_x[1] + 0.25, 0.95, col = "#EAF2F8", border = "#2D5F8B", lwd = 1.4)
  group_label <- if (nrow(team_group) == 0) "分组待确认" else sprintf(
    "%s组\n第1 %.1f%% / 第2 %.1f%%\n第3 %.1f%% / 出线 %.1f%%",
    team_group$group, team_group$first * 100, team_group$second * 100,
    team_group$third * 100, team_group$qualified * 100
  )
  text(timeline_x[1], 0.91, "当前小组", font = 2, cex = 0.78, col = "#173F5F")
  text(timeline_x[1], 0.83, group_label, cex = 0.58)
  timeline_labels <- c("32强", "16强", "8强", "四强", "决赛")
  for (stage_index in seq_along(stage_keys)) {
    x <- timeline_x[stage_index + 1]
    stage <- stage_keys[stage_index]
    reach <- if (nrow(team_stage) == 0) 0 else as.numeric(team_stage[[stage_prob_keys[stage_index]]])
    rect(x - 0.25, 0.79, x + 0.25, 0.93, col = "#F8FAFC", border = "#54728C", lwd = 1.2)
    text(x, 0.89, timeline_labels[stage_index], font = 2, cex = 0.78, col = "#173F5F")
    text(x, 0.83, sprintf("到达 %.1f%%", reach * 100), cex = 0.66, col = "#A61B29", font = 2)
  }
  champion <- if (nrow(team_stage) == 0) 0 else as.numeric(team_stage$champion)
  rect(timeline_x[7] - 0.25, 0.79, timeline_x[7] + 0.25, 0.93, col = "#FFF4CC", border = "#C69214", lwd = 1.5)
  text(timeline_x[7], 0.89, "冠军", font = 2, cex = 0.80, col = "#8A5A00")
  text(timeline_x[7], 0.83, sprintf("夺冠 %.1f%%", champion * 100), font = 2, cex = 0.68)

  detail_x <- seq(0.5, 4.5, length.out = 5)
  for (stage_index in seq_along(stage_keys)) {
    x <- detail_x[stage_index]
    stage <- stage_keys[stage_index]
    rect(x - 0.46, 0.18, x + 0.46, 0.70, col = "#F8FAFC", border = "#9AAFC1", lwd = 1.1)
    rect(x - 0.46, 0.62, x + 0.46, 0.70, col = "#173F5F", border = NA)
    text(x, 0.66, stage_labels[stage_index], font = 2, cex = 0.82, col = "white")
    opponents <- top_opponents(aggregate_team_stage(route_rows, team, stage), 5)
    if (nrow(opponents) == 0) {
      text(x, 0.45, "未到达 / 数据待确认", cex = 0.62, col = "#6B7280")
    } else {
      for (j in seq_len(nrow(opponents))) {
        y <- 0.575 - (j - 1) * 0.065
        low <- isTRUE(opponents$low_sample[j])
        label <- sprintf("%s  遇%.1f%%  胜%.1f%%  贡献%.1f%%",
          opponents$opponent[j], opponents$opponent_probability[j] * 100,
          opponents$matchup_advance_probability[j] * 100,
          opponents$advancement_contribution[j] * 100)
        if (low) label <- paste0(label, "  样本少")
        text(x - 0.42, y, label, adj = 0, cex = 0.63, col = ifelse(low, "#9CA3AF", "#273444"))
      }
    }
  }
  text(2.5, 0.11, "遇=到达该轮后遇到该对手的条件概率；胜=该对阵晋级率；贡献=该分支对下一轮无条件概率的贡献",
    cex = 0.78, col = "#52616B")
  draw_preview_label()
  par(op)
  dev.off()
}

plot_group_overview(group_positions, current_group_status, file.path(figure_dir, "fig7_5a_overall_groups.png"))
plot_bracket_overview(bracket_slots, schedule, file.path(figure_dir, "fig7_5b_overall_bracket.png"))
featured <- c("西班牙", "法国", "阿根廷", "巴西", "葡萄牙")
slugs <- c("spain", "france", "argentina", "brazil", "portugal")
for (i in seq_along(featured)) {
  plot_team_route(featured[i], route_nodes, stages, group_positions,
    file.path(figure_dir, sprintf("fig7_%s_%s_route.png", i + 5, slugs[i])))
}

plot_data_quality(data_audit, file.path(figure_dir, "fig2_0_data_quality_audit.png"))
plot_poisson_diagnostics(poisson_diagnostics, goal_calibration, file.path(figure_dir, "fig5_3_poisson_diagnostics.png"))
plot_model_comparison(model_comparison, rolling_validation, file.path(figure_dir, "fig5_4_model_comparison.png"))
plot_logistic_roc(logistic_roc, logistic_metrics, file.path(figure_dir, "fig5_5_logistic_roc.png"))

web_data_dir <- file.path("web", "data")
dir.create(web_data_dir, recursive = TRUE, showWarnings = FALSE)
web_files <- c(
  "team_route_nodes.csv", "bracket_slot_probabilities.csv", "group_position_probabilities.csv",
  "team_stage_probabilities.csv", "current_group_status.csv", "run_metadata.csv",
  "data_quality_audit.csv", "poisson_fit_statistics.csv", "poisson_model_comparison.csv",
  "rolling_origin_validation.csv", "logistic_metrics.csv"
)
for (name in web_files) file.copy(file.path(output_dir, name), file.path(web_data_dir, name), overwrite = TRUE)
file.copy(file.path("data", "worldcup_2026_schedule.csv"), file.path(web_data_dir, "worldcup_2026_schedule.csv"), overwrite = TRUE)

plot_bar <- function(df, title, path, color) {
  pdf(path, width = 9, height = 5.5, family = "GB1")
  op <- par(mar = c(5, 9, 4, 2))
  values <- rev(df$probability)
  labels <- rev(df$team)
  bp <- barplot(values, horiz = TRUE, names.arg = labels, las = 1, col = color, border = NA,
                xlim = c(0, max(values, df$ci_upper, na.rm = TRUE) * 1.15),
                main = title, xlab = "概率")
  if (all(c("ci_lower", "ci_upper") %in% names(df))) {
    arrows(rev(df$ci_lower), bp, rev(df$ci_upper), bp, angle = 90, code = 3, length = 0.04)
    label_x <- rev(df$ci_upper)
  } else {
    label_x <- values
  }
  text(label_x, bp, labels = sprintf("%.1f%%", values * 100), pos = 4, cex = 0.8)
  par(op)
  dev.off()
}

plot_progression <- function(df, path, top_n = 8) {
  stage_cols <- c("round_of_32", "round_of_16", "quarter_final", "semi_final", "final", "champion")
  stage_labels <- c("出线", "16强", "8强", "四强", "决赛", "夺冠")
  df <- df[order(-df$champion), ][1:min(top_n, nrow(df)), ]
  pdf(path, width = 10, height = 5.8, family = "GB1")
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
  pdf(path, width = 8, height = 5.4, family = "GB1")
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

plot_bar(champion, "冠军概率 Top 10", file.path(figure_dir, "champion_probability_top10.pdf"), "#2E74B5")
plot_bar(four, "四强概率 Top 10", file.path(figure_dir, "final_four_probability_top10.pdf"), "#70AD47")
plot_progression(stages, file.path(figure_dir, "advancement_progression.pdf"))
plot_funnel(stages, file.path(figure_dir, "top_team_funnel.pdf"))

cat(sprintf("Charts written to %s\n", figure_dir))
