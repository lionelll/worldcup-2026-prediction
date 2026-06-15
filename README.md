# 2026 年世界杯冠军概率预测

基于历史比赛数据与蒙特卡洛模拟的 2026 年世界杯冠军概率预测研究。

## 研究方法

- **主模型**：泊松回归（`glm(..., family = poisson())`），预测双方 90 分钟进球数
- **模拟方式**：蒙特卡洛模拟 10,000 次完整赛程（48 队新赛制）
- **对照模型**：逻辑回归、随机森林（用于解释和对比）
- **训练数据**：2010-2024 年国际比赛结果（15,000+ 场）
- **赛中更新**：纳入截至 2026-06-15 已赛的 12 场小组赛真实比分

## 预测结果（Top 5）

| 排名 | 球队 | 夺冠概率 |
|------|------|----------|
| 1 | 西班牙 | 17.19% |
| 2 | 阿根廷 | 12.50% |
| 3 | 法国 | 8.50% |
| 4 | 摩洛哥 | 5.36% |
| 5 | 巴西 | 5.24% |

## 目录结构

```text
.
├── R/                          # 主代码（R 语言）
│   ├── worldcup_predictor.R    # 建模与模拟主程序
│   ├── validate_inputs.R       # 输入数据校验
│   └── make_charts.R           # 图表生成
├── data/                       # 输入数据
│   ├── historical_matches.csv  # 历史比赛结果（2010-2026）
│   ├── worldcup_2026_groups.csv
│   ├── worldcup_2026_schedule.csv
│   ├── worldcup_2026_results_asof_2026-06-15.csv
│   └── worldcup_2026_standings_asof_2026-06-15.csv
├── output/                     # 模型输出
├── scripts/                    # Python 辅助脚本
└── web/                        # 静态网页仪表盘
```

## 运行步骤

```bash
# 1. 校验输入数据
Rscript R/validate_inputs.R

# 2. 运行完整预测管线（约 2-3 分钟）
Rscript R/worldcup_predictor.R

# 3. 生成图表
Rscript R/make_charts.R
```

## 输出结果

运行后在 `output/` 下生成：

- `champion_probabilities.csv` — 冠军概率 Top 10
- `final_four_probabilities.csv` — 四强概率 Top 10
- `team_stage_probabilities.csv` — 各队各阶段晋级概率
- `group_advancement_probabilities.csv` — 各小组出线概率
- `model_metrics.csv` — 模型评估指标
- `model_coefficients.csv` — 模型系数

## 口径说明

- 赛前模型训练数据截止到 `2026-06-10`
- 赛中更新采用截至 `2026-06-15` 的已赛结果，不进入赛前训练集
- 公开数据中没有的变量（伤病、首发、赔率、xG 等）不主观补造

## 网页展示

```bash
cd web && python3 -m http.server 8000
# 打开 http://127.0.0.1:8000
```

## 数据来源

- 历史比赛数据：[International Football Results from 1872 to Present](https://github.com/martj42/international_results)
- 分组与赛程：FIFA 2026 世界杯官方赛程
- Elo 评分：由历史比赛自动推算
