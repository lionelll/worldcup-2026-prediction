# R 语言代码说明

本目录包含预测系统的 R 后端代码。所有脚本均使用 base R，不依赖额外安装包。

## 文件

- `validate_inputs.R`：校验分组、赛程、历史训练集字段和日期边界。
- `worldcup_predictor.R`：完整建模与蒙特卡洛模拟主程序。
- `compare_snapshots.R`：比较相同随机种子下两个赛中快照的阶段概率变化。
- `make_charts.R`：根据输出结果生成 PDF 矢量图表，使用 base R `pdf()` 设备与 `GB1` 中文字体族。
- `test_route_outputs.R`：校验各轮对手概率、分支贡献、签表槽位、冠军总和与小样本标记。
- `worldcup_predictor.R` 同时输出数据质量审计、泊松回归推断与诊断、嵌套模型比较、时间滚动验证和二元逻辑回归对照结果。

`worldcup_predictor.R` 会额外生成两份赛中校验文件：

- `output/prediction_vs_actual.csv`：逐场记录模型给出的胜/平/负概率、实际比分、是否命中、Brier Score、Log Loss 和比分误差。
- `output/prediction_vs_actual_summary.csv`：汇总已录入赛果与模型预测之间的总体差异。
- `output/in_tournament_elo_updates.csv`：记录已赛结果带来的 Elo 滚动变化。
- `output/figures/fig5_3b_poisson_qq.png`：先列队与后列队泊松模型的 deviance residuals Q-Q 诊断图。
- `output/run_metadata.csv`：记录模拟次数、随机种子、赛果快照和平局校准系数。
- `output/team_route_nodes.csv`：保存逐队、逐轮、逐对手的条件路径节点和分支贡献。
- `output/bracket_slot_probabilities.csv`：保存每个比赛槽位的球队占据概率和获胜贡献。
- `output/group_position_probabilities.csv`：保存小组第一、第二、第三与出线概率。
- `output/current_group_status.csv`：按已结束比赛生成当前积分，并穷举剩余胜平负组合判断是否锁定或无缘小组前二。
- `output/data_quality_audit.csv`：历史数据缺失、重复、无效值与高比分标记。
- `output/poisson_coefficient_inference.csv`、`poisson_fit_statistics.csv`：GLM 系数检验与拟合诊断。
- `output/poisson_model_comparison.csv`、`rolling_origin_validation.csv`：候选模型与时间滚动验证。
- `output/logistic_metrics.csv`、`logistic_roc_curve.csv`：二元逻辑回归对照实验。

主程序采用严格时间顺序生成历史 Elo 和近 10 场状态特征。2025 年比赛只用于平局概率校准，2026 年 1 月 1 日至 6 月 10 日作为独立验证集；世界杯已赛结果不回填训练集，只更新剩余赛程预测所用的当前状态。

## 运行顺序

```bash
Rscript R/validate_inputs.R
Rscript R/worldcup_predictor.R
Rscript R/test_route_outputs.R
Rscript R/make_charts.R
```

正式运行有数据确认闸门：`R/worldcup_predictor.R` 和 `R/make_charts.R` 会检查 `data/data_approval.csv`。只要分组、赛程、已赛比分、历史训练集、Elo/Annex C 等关键数据仍未确认，程序会停止，避免把未经确认的数据写成正式结果。

如果仅验证程序流程，可以显式加入：

```bash
Rscript R/worldcup_predictor.R --allow-unconfirmed-data
Rscript R/test_route_outputs.R --output output
Rscript R/make_charts.R --allow-unconfirmed-data
```

该参数下生成的概率、指标和图表属于未确认输出，不能写入正式报告。

`--annex-c` 可指定 Annex C CSV，默认为 `data/annex_c_full_mapping.csv`。
正式模式会校验 12 选 8 的 495 个小组组合，且每个组合必须含 8 条一对一的
比赛槽位映射。未通过校验时禁止生成正式路线图。

当前项目已经包含 `data/worldcup_2026_schedule.csv`。如果在空环境中没有赛程文件、只做代码流程检查，可以临时运行：

```bash
Rscript R/worldcup_predictor.R --allow-generated-group-schedule
```

注意：`--allow-generated-group-schedule` 只用于干运行，不能作为正式报告结果来源。正式提交时使用经确认的真实赛程 CSV。
