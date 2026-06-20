# 2026 年世界杯冠军概率预测

基于历史比赛数据与蒙特卡洛模拟的 2026 年世界杯冠军概率预测研究。

## 当前状态

当前项目已经具备 R 语言代码、报告草稿、网页展示、分组/赛程/已赛结果等结构化文件，但正式预测结果暂不输出为结论。原因是数据来源仍需用户确认。

关键原则：

- 缺数据时必须先向用户确认，不自行补造。
- 涉及数据来源、赛果、排名、赛程、训练集和 Elo 的内容，必须有来源与快照日期。
- 未经确认的数据可以用于代码调试，但不能写入正式报告结论。

## 研究方法

- **主模型**：泊松回归（`glm(..., family = poisson())`），预测双方 90 分钟进球数。
- **模拟方式**：蒙特卡洛模拟完整赛程。
- **对照模型**：二元逻辑回归，用于“第一列球队获胜 vs 非获胜”的解释、ROC/AUC 与概率质量对比；不进入赛事模拟。
- **课程方法补强**：数据质量审计、泊松 GLM 显著性与离散度诊断、AIC/BIC 嵌套模型比较、rolling-origin 时间交叉验证。
- **训练数据**：`data/historical_matches.csv` 已存在且字段校验通过，但来源、快照日期和使用许可仍需确认。
- **赛中更新**：截至 `2026-06-20 09:18` 明确完赛的 30 场结果已录入；赛果用于当前积分、滚动 Elo 和近 10 场状态，正式使用前仍需确认。
- **时间边界**：历史 Elo、近期状态均按比赛日期逐场生成，禁止将最终评分回填到过去比赛。
- **概率校准**：2025 年比赛用于拟合平局校准系数，2026-01-01 至 2026-06-10 用于独立验证。

## 数据确认

正式运行前先看：

- `data/DATA_STATUS.md`
- `data/data_approval.csv`

只有 `data/data_approval.csv` 中相关数据项的 `approved` 为 `true` 时，`R/worldcup_predictor.R` 才会作为正式模型运行。否则主程序会停止并提示需要确认哪些数据。

当前待确认项包括：

- 分组与队名。
- 小组赛和淘汰赛赛程。
- 截至 `2026-06-20 09:18` 的 30 场已赛比分和当前排名；直播中的比赛不纳入。
- `historical_matches.csv` 的来源与快照日期。
- 是否提供 `team_elo.csv`，或是否允许用历史比赛推断简化 Elo。
- 是否提供 FIFA Annex C 完整 495 种最佳第三名映射。

## 目录结构

```text
.
├── R/                          # 主代码（R 语言）
│   ├── worldcup_predictor.R    # 建模与模拟主程序
│   ├── compare_snapshots.R     # 相同随机种子下的赛中快照概率变化
│   ├── validate_inputs.R       # 输入数据校验
│   ├── test_route_outputs.R    # 路线/签表概率一致性测试
│   └── make_charts.R           # 报告图表与网页数据生成
├── data/                       # 输入数据与数据确认清单
│   ├── DATA_STATUS.md
│   ├── data_approval.csv
│   ├── historical_matches.csv
│   ├── worldcup_2026_groups.csv
│   ├── worldcup_2026_schedule.csv
│   ├── worldcup_2026_results_asof_2026-06-20.csv
│   └── worldcup_2026_standings_asof_2026-06-15.csv
├── output/                     # 调试输出；确认前不得作为正式结果
├── scripts/                    # Python 辅助脚本
└── web/                        # 静态网页仪表盘
```

## 运行步骤

```bash
# 1. 校验输入字段和日期边界
Rscript R/validate_inputs.R

# 2. 正式运行预测管线
Rscript R/worldcup_predictor.R

# 3. 校验路线概率、签表槽位和唯一冠军等不变量
Rscript R/test_route_outputs.R
```

如果数据尚未确认，第二步会停止。只做代码调试时可显式运行：

```bash
Rscript R/worldcup_predictor.R --allow-unconfirmed-data
```

该参数下产生的结果不能写入正式报告。

图表生成：

```bash
Rscript R/make_charts.R
```

小组实时判断输出为 `output/current_group_status.csv`。它按已结束比分生成积分表，
并穷举剩余胜平负组合，保守判断是否锁定或无缘小组前二。

路线模块的主要输出为 `output/team_route_nodes.csv`、
`output/bracket_slot_probabilities.csv` 和 `output/group_position_probabilities.csv`。
课程方法诊断输出包括 `output/data_quality_audit.csv`、
`output/poisson_fit_statistics.csv`、`output/poisson_model_comparison.csv`、
`output/rolling_origin_validation.csv` 和 `output/logistic_metrics.csv`。
正式模式必须提供完整且通过 495 种组合校验的
`data/annex_c_full_mapping.csv`；缺失时程序会停止。

## 网页展示

```bash
cd web && python3 -m http.server 8000
```

打开：

```text
http://127.0.0.1:8000
```

网页还提供小组晋级概览、完整签表和西班牙/法国/阿根廷/巴西/葡萄牙的
条件晋级路线。未确认 Annex C 时只显示带警示的调试预览，不作为正式结论。
