# 2026 年世界杯冠军概率预测 - 完整代码

基于历史比赛数据、泊松回归与蒙特卡洛模拟的 2026 年世界杯冠军概率预测。

## 目录结构

```
./
├── backend/                        # R 代码、数据与模型输出
│   ├── R/                          # 主代码（纯 base R）
│   │   ├── worldcup_predictor.R    # 建模与蒙特卡洛模拟主程序
│   │   ├── make_charts.R           # 图表生成
│   │   ├── validate_inputs.R       # 输入数据校验
│   │   ├── test_route_outputs.R    # 路线与概率一致性测试
│   │   └── compare_snapshots.R     # 赛中快照概率对比
│   ├── data/                       # 输入数据
│   ├── output/                     # 模型输出与图表
│   ├── assets/                     # 报告素材
│   └── report_tools/               # Word 报告生成工具
├── frontend/                       # 静态网页
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── data/                       # 前端数据副本
├── scripts/                        # 运行、校验与同步脚本
├── RESOURCE_MANIFEST.md            # 运行资源说明
└── README.md
```

## 运行环境

- **R**：base R，无需安装额外 R 包。
- **Python**：Python 3，用于启动静态网页。
- **报告工具**：重新生成 Word 时安装 `backend/report_tools/requirements.txt`。
- **操作系统**：macOS / Linux；Windows 使用 Git Bash 或 WSL 运行 Shell 脚本。

## 后端运行

在仓库根目录执行：

```bash
# 检查当前资源
./scripts/verify_resources.sh validate

# 运行当前数据快照
./scripts/run_backend.sh validate
```

正式模式使用：

```bash
./scripts/run_backend.sh formal
```

缺少完整 Annex C 映射或数据确认未通过时，正式模式会停止，不会补造数据。

## 必需数据

R 后端需要 `backend/data/` 下的以下文件：

| 文件 | 说明 |
|------|------|
| `historical_matches.csv` | 2010-2026 年国际足球比赛数据 |
| `worldcup_2026_groups.csv` | 48 队分组 |
| `worldcup_2026_schedule.csv` | 小组赛与淘汰赛赛程 |
| `worldcup_2026_results_asof_2026-06-20.csv` | 截至 6 月 20 日的 32 场赛果 |
| `data_approval.csv` | 数据确认状态 |

`annex_c_full_mapping.csv` 是正式模式必需资源，当前尚未提供；`team_elo.csv` 为可选资源。详见 `RESOURCE_MANIFEST.md`。

## 主要输出

- `backend/output/champion_probabilities.csv` - 48 队夺冠概率。
- `backend/output/final_four_probabilities.csv` - 四强概率。
- `backend/output/team_stage_probabilities.csv` - 各阶段晋级概率。
- `backend/output/group_advancement_probabilities.csv` - 小组出线概率。
- `backend/output/prediction_vs_actual.csv` - 逐场预测与实际结果。
- `backend/output/figures/` - 模型诊断及预测图表。

## 网页展示

```bash
./scripts/serve_frontend.sh
```

浏览器打开 `http://127.0.0.1:8000`。网页不需要安装前端依赖。

## 研究方法

- **主模型**：泊松回归，预测双方 90 分钟进球数。
- **特征**：动态 Elo、近 10 场滚动状态和场地赛事变量。
- **模拟**：10,000 次蒙特卡洛完整赛事模拟，随机种子为 `20260615`。
- **对照模型**：二元逻辑回归，不进入赛事模拟。
- **验证**：独立测试集与 rolling-origin 时间交叉验证。
- **诊断**：显著性、离散度、AIC/BIC、残差图、Q-Q 图与 ROC/AUC。
