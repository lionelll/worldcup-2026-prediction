# R 语言代码说明

本目录为课程作业提交用 R 语言代码。所有脚本均使用 base R，不依赖额外安装包。

## 文件

- `validate_inputs.R`：校验分组、赛程、历史训练集字段和日期边界。
- `worldcup_predictor.R`：完整建模与蒙特卡洛模拟主程序。
- `make_charts.R`：根据输出结果生成 SVG 图表。

## 运行顺序

```bash
Rscript R/validate_inputs.R
Rscript R/worldcup_predictor.R
Rscript R/make_charts.R
```

当前项目已经包含 `data/worldcup_2026_schedule.csv`。如果在空环境中没有赛程文件、只做代码流程检查，可以临时运行：

```bash
Rscript R/worldcup_predictor.R --allow-generated-group-schedule
```

注意：`--allow-generated-group-schedule` 只用于干运行，不能作为正式报告结果来源。正式提交时使用本项目的真实赛程 CSV。
