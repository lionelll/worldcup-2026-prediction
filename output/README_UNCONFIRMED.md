# output 目录说明

本目录中的概率、图表和模型指标文件是在数据来源尚未完全确认前产生的调试输出。

当前调试快照使用截至 `2026-06-19` 的 28 场赛果和 1000 次蒙特卡洛模拟。具体运行参数以 `run_metadata.csv` 为准。

在以下事项确认前，不得把这些结果写入正式报告：

1. `historical_matches.csv` 的来源、快照日期和清洗规则。
2. 分组、赛程、已赛比分和当前排名。
3. 是否使用外部 `team_elo.csv`，或允许用历史比赛推断简化 Elo。
4. FIFA Annex C 最佳第三名完整映射是否补齐。
5. `data/data_approval.csv` 中相关项是否全部改为 `approved=true`。

如果需要正式输出，请先完成数据确认，然后重新运行：

```bash
Rscript R/worldcup_predictor.R
Rscript R/make_charts.R
```
