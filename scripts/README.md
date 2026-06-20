# 脚本说明

## validate_inputs.py

用途：校验正式建模输入是否满足报告执行口径。

默认输入：

```bash
python3 scripts/validate_inputs.py
```

等价于校验：

- `data/worldcup_2026_groups.csv`
- `data/worldcup_2026_schedule.csv`
- `data/historical_matches.csv`

校验内容：

1. 分组数据必须包含 12 组、48 支球队、每组 4 队。
2. 赛程数据包含固定字段：`match_id`、`stage`、`group`、`match_date`、`team_1`、`team_2`、`venue`、`host_country`、`team_1_slot`、`team_2_slot`。
3. 历史训练集包含最低字段：`date`、`home_team`、`away_team`、`home_score`、`away_score`、`tournament`、`country`、`neutral`。
4. 历史比赛日期不得晚于 `2026-06-10`。
5. 训练集必须覆盖 `2010-01-01` 至 `2024-12-31` 区间。
6. 测试集必须覆盖 `2025-01-01` 至 `2026-06-10` 区间。

正式跑模型前先通过该脚本，避免报告口径和数据口径不一致。注意：该脚本只做结构校验，不等于确认数据来源。

## worldcup_predictor.py

完整预测管线，包含：

- 历史比赛读取与 2026-06-10 日期截断。
- Elo 强度推断或外部 Elo 匹配。
- 滚动窗口近期状态特征构造。
- 泊松回归训练。
- 单场模型指标输出。
- 小组赛与淘汰赛蒙特卡洛模拟。
- 截至 2026-06-20 09:18 明确完赛的 30 场结果更新。
- 各队晋级概率、冠军概率、四强概率输出。

正式运行：

```bash
python3 scripts/worldcup_predictor.py
```

正式结果必须先确认 `data/data_approval.csv` 中的关键数据项。未确认数据只能用于调试，不得写入报告结论。

当前项目已包含赛程文件；如果在空环境中只做代码流程检查：

```bash
python3 scripts/worldcup_predictor.py --allow-generated-group-schedule
```

注意：`--allow-generated-group-schedule` 只用于代码干运行，不可作为正式报告结果来源。

## make_charts.py

根据 `output/` 中的结果表生成 SVG 图表：

- `output/figures/champion_probability_top10.svg`
- `output/figures/final_four_probability_top10.svg`
- `output/figures/advancement_progression.svg`
- `output/figures/top_team_funnel.svg`

运行：

```bash
python3 scripts/make_charts.py
```

未完成数据确认时，图表脚本会停止。只做调试可显式使用 `--allow-unconfirmed-data`，但生成图表不能作为正式提交结果。
