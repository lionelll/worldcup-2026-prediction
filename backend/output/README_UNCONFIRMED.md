# output 目录说明

本目录中的概率、图表和模型指标尚未完成全部数据来源核验，因此标记为未确认输出。

赛果快照日期、已赛场次、模拟次数和随机种子以 `run_metadata.csv` 为准。

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
