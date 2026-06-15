# 2026 年世界杯冠军概率预测

本项目包含两部分提交内容：

1. 项目报告：`2026世界杯冠军概率预测报告_草稿.docx` / `2026世界杯冠军概率预测报告_草稿.md`
2. 完整代码：`R/` 目录下的 R 语言脚本

## 目录结构

```text
.
├── 2026世界杯冠军概率预测报告_草稿.docx
├── 2026世界杯冠军概率预测报告_草稿.md
├── data/
│   ├── README.md
│   ├── worldcup_2026_groups.csv
│   ├── worldcup_2026_schedule.csv
│   ├── worldcup_2026_results_asof_2026-06-15.csv
│   ├── worldcup_2026_standings_asof_2026-06-15.csv
│   ├── worldcup_2026_schedule_template.csv
│   └── historical_matches_template.csv
├── R/
│   ├── validate_inputs.R
│   ├── worldcup_predictor.R
│   ├── make_charts.R
│   └── README.md
├── web/
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── scripts/
│   ├── validate_inputs.py
│   ├── worldcup_predictor.py
│   ├── make_charts.py
│   └── build_report_docx.py
└── output/
```

## 数据要求

正式运行前需要准备：

- `data/historical_matches.csv`：真实国家队历史比赛结果。
- `data/team_elo.csv`：可选，球队 Elo 强度数据。

已经补齐：

- `data/worldcup_2026_groups.csv`：按用户提供的分组截图重建。
- `data/worldcup_2026_schedule.csv`：按用户提供的小组赛与淘汰赛赛程截图重建。
- `data/worldcup_2026_results_asof_2026-06-15.csv`：截至 2026-06-15 已赛结果。
- `data/worldcup_2026_standings_asof_2026-06-15.csv`：截至 2026-06-15 当前排名。

历史比赛最低字段：

```text
date,home_team,away_team,home_score,away_score,tournament,country,neutral
```

赛程最低字段：

```text
match_id,stage,group,match_date,team_1,team_2,venue,host_country,team_1_slot,team_2_slot
```

## 运行步骤

1. 校验输入数据：

```bash
Rscript R/validate_inputs.R
```

2. 运行完整预测管线：

```bash
Rscript R/worldcup_predictor.R
```

3. 生成图表：

```bash
Rscript R/make_charts.R
```

4. 当前项目已包含赛程文件；如果在空环境中只想检查代码流程，可用干运行参数：

```bash
Rscript R/worldcup_predictor.R --allow-generated-group-schedule
```

干运行只用于代码检查，不用于正式报告结果。

## 输出结果

运行后生成：

- `output/team_stage_probabilities.csv`
- `output/champion_probabilities.csv`
- `output/final_four_probabilities.csv`
- `output/group_advancement_probabilities.csv`
- `output/model_metrics.csv`
- `output/model_coefficients.csv`
- `output/asof_results_impact.csv`
- `output/figures/*.svg`

## 网页展示

当前项目还提供一个静态网页仪表盘，用于展示小组分组、截至 2026-06-15 的已赛结果、当前排名、后续赛程、淘汰赛槽位、R 程序状态和提交文件清单：

```bash
cd web
python3 -m http.server 8000
```

打开：

```text
http://127.0.0.1:8000
```

该网页只展示当前已有数据，不替代正式模型输出。

报告中的概率、模型指标和图表应全部来自这些输出文件。

## 口径说明

- 赛前模型训练数据截止到 `2026-06-10`。
- 分组、赛程、已赛结果和当前排名采用截至 `2026-06-15` 的赛中更新口径。
- 2026-06-15 已赛结果只用于赛中动态更新，不进入赛前训练集。
- 主模型为 R 语言 `glm(..., family = poisson())` 泊松回归，逻辑回归和随机森林在报告中作为解释/对照方法说明。
- 若公开数据中没有伤病、首发、红黄牌、天气、赔率、xG 等变量，不进行主观补造。

## Python 辅助文件

`scripts/` 目录保留了此前生成 Word 报告和 Python 版管线的辅助脚本。若课程要求“用 R 语言写”，正式提交代码以 `R/` 目录为准。
