# 报告辅助工具

本目录不是预测后端的一部分，只负责把 R 后端已经生成的 CSV 和 PNG 组装成 Word 报告。

- `generate_course_report.py`：从 `../data`、`../output` 和 `../assets` 生成完整报告。
- `update_report_preserving_front.py`：保留用户已修改的第三章前内容，替换第三章及之后内容。

数据未确认时，报告生成器默认停止。`--allow-unconfirmed-data` 只能生成带有“数据待确认”标识的非正式报告。

安装 Python 依赖：

```bash
python3 -m pip install -r report_tools/requirements.txt
```

示例：

```bash
cd backend
python3 report_tools/generate_course_report.py --allow-unconfirmed-data
```
