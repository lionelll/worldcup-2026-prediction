# 数据目录说明

本目录用于保存 2026 年世界杯预测报告所需的输入数据。所有数据必须真实、可追溯、可复现；不得填入虚构分组、虚构赛果或手工编造的球队强度。

## 1. 真实分组与赛程

分组文件：`worldcup_2026_groups.csv`

赛程文件：`worldcup_2026_schedule.csv`

当前排名文件：`worldcup_2026_standings_asof_2026-06-15.csv`

来源优先级：

1. FIFA 2026 世界杯官方赛事页。
2. FIFA 官方赛程或规则文件。
3. 与 FIFA 官方信息一致的公开赛程数据快照。

采集规则：

- 赛前基准模型只使用 2026-06-10 前信息。
- 赛中更新版本额外使用截至 2026-06-20 明确完赛的 32 场比分；所有新增赛果均保留来源说明并等待最终整体确认，未开赛或未明确完赛的比赛不纳入。
- 使用真实分组和真实赛程，不使用示意性分组。
- 淘汰赛行保留官方槽位；含最佳第三名的场次以候选槽位集合记录。

必需字段：

```text
match_id,stage,group,match_date,kickoff_time,team_1,team_2,venue,host_country,team_1_slot,team_2_slot,source_note
```

分组文件字段：

```text
group,slot,team
```

Annex C 文件：`annex_c_full_mapping.csv`。字段为：

```text
qualified_groups,match_id,third_group,source_note
```

- `qualified_groups`：升序连写的 8 个出线第三名小组字母，例如 `ABCDEFGH`。
- 每个 `qualified_groups` 必须有 8 行，对应 8 个最佳第三名槽位。
- 完整文件必须覆盖 495 种组合，不允许重复比赛或重复小组。
- `annex_c_full_mapping_template.csv` 只是空字段模板，不含任何猜测映射。

`worldcup_2026_groups.csv` 与 `worldcup_2026_schedule.csv` 已按用户提供的百度体育分组/赛程/淘汰赛截图录入，但当前只视为“待确认数据”。正式提交前必须由用户确认，或再与 FIFA 官方赛事页、官方赛程 PDF 做最终核对。未经确认时，不得把这些数据对应的模型结果写入正式报告。

## 2. 历史比赛训练集

文件名：`historical_matches.csv`

数据要求：

- 必须是真实国家队历史比赛结果。
- 最低字段为 `date`、`home_team`、`away_team`、`home_score`、`away_score`、`tournament`、`country`、`neutral`。
- 训练/测试边界固定为：
  - 训练集：2010-01-01 至 2024-12-31。
  - 测试集：2025-01-01 至 2026-06-10。
  - 2026-06-11 及之后的比赛必须删除。

公开简化数据中没有的变量不补造，包括球员伤病、首发阵容、红黄牌、公平竞赛分、天气、赔率、xG 等。

## 3. 球队强度数据

推荐文件名：`team_elo.csv`

主模型使用 Elo 分差，FIFA 排名或积分只作为基准对照。若 Elo 数据为每日快照，应在特征构造时按比赛日期取赛前最新 Elo，不得使用赛后更新值。

## 4. 可复现记录

正式报告附录中需要记录：

- 数据来源 URL。
- 下载日期或数据快照日期。
- 清洗规则。
- 队名映射规则。
- 随机种子。

## 5. 赛中结果更新

文件名：`worldcup_2026_results_asof_2026-06-20.csv`

历史快照：`worldcup_2026_results_asof_2026-06-15.csv`、`worldcup_2026_results_asof_2026-06-17.csv`

当前排名文件：`worldcup_2026_standings_asof_2026-06-15.csv`

该文件记录截至 2026-06-15 已录入但待最终确认的世界杯小组赛结果，用于将原先的赛前预测扩展为赛中动态更新分析。使用规则：

- 小组赛最低字段为 `match_date,team_1,team_2,team_1_score,team_2_score`。
- 若已开始录入淘汰赛，额外提供 `match_id,stage,winner,decided_by`；
  `decided_by` 建议固定为 `90min`、`extra_time` 或 `penalties`。
- 已确认的淘汰赛对手和胜者会在模拟中固定为 100%，不再抽样。
- 已赛比分可以用于更新小组积分、净胜球和剩余赛程模拟。
- 当前排名文件用于网页展示和人工核对；正式模拟仍优先由已赛比分和剩余赛程动态计算。
- 不得把已赛结果回填进“赛前模型训练”中，否则会改变原始赛前预测口径。
- 报告中应明确区分“赛前预测基准”和“赛中更新结果”。

## 6. 数据确认闸门

正式模型运行前必须检查：

- `DATA_STATUS.md`：逐项说明当前数据是否可用于正式结果。
- `data_approval.csv`：只有对应数据项 `approved=true` 后，R 主程序才允许正式运行。

当前默认策略是：缺数据、来源不清、快照日期不明、字段含义不明时，不自行补造，也不据此形成正式结论。若仅用于验证程序流程，可以显式使用 `--allow-unconfirmed-data`，但生成内容属于未确认输出。
