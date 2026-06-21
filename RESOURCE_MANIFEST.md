# 运行资源清单

## R 后端

R 后端仅使用 base R，不需要安装额外 R 包。统一脚本从仓库根目录启动，并自动切换到 `backend/`。

当前计算所需输入均位于 `backend/data/`：

- `historical_matches.csv`
- `worldcup_2026_groups.csv`
- `worldcup_2026_schedule.csv`
- `worldcup_2026_results_asof_2026-06-20.csv`
- `data_approval.csv`

`team_elo.csv` 为可选输入。文件不存在时，程序根据历史比赛逐场更新并推导 Elo。

正式模式还需要 `backend/data/annex_c_full_mapping.csv`。当前目录只有字段模板 `annex_c_full_mapping_template.csv`，不包含完整 495 组官方映射，因此正式模式会停止。该文件必须来自已核验来源，不得根据模板补造。

## 网页

网页使用 Python 3 内置静态服务器，不需要安装前端包。`frontend/data/` 中的 CSV 已随仓库提供；后端重新运行后，`scripts/sync_frontend_data.sh` 会更新这些文件。

## Word 报告工具

仅在重新生成 Word 报告时需要 Python 第三方包：

```bash
python3 -m pip install -r backend/report_tools/requirements.txt
```

报告生成器读取：

- `backend/output/*.csv`
- `backend/output/figures/`
- `backend/assets/`

这些资源均已包含在仓库中。R 模型本身不依赖 `backend/assets/`。
