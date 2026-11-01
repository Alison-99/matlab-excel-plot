# 内置绘图函数配置

`plot_excel(excelFile, jobs, outDir)` 读取配置指定的真实单元格。工作簿的语义识别由使用技能的 Codex 完成；函数不声称能从任意 Excel 布局自动判断 ARL1。用户无需编写配置或提供 .m，由 Codex 检查数据后生成驱动脚本。

在独立输出目录复制 `scripts/plot_excel.m` 、`scripts/legend_curve_order.m` 和 `scripts/place_compact_legend.m`，同目录保存 `run_plots.m`。驱动脚本用 `addpath(fileparts(mfilename('fullpath')))` 定位函数，而非依赖原工作目录。路径、表名、范围和标签必须替换为本次实测值。

```matlab
addpath(fileparts(mfilename('fullpath')));
excelFile = '/absolute/path/experiment.xlsx';
outDir = fileparts(mfilename('fullpath'));
jobs = struct();
jobs.sheet = 'r';
jobs.xRange = 'A3:A23';
jobs.yRanges = {'B3:B23','C3:C23','D3:D23','E3:E23'};
jobs.labels = {'r=0.1','r=0.3','r=0.5','r=0.7'};
jobs.title = 'Case 1';
jobs.fileStem = 'r_case1';
jobs.xLabel = 'delta';
jobs.yLabel = 'log10(ARL1)';
jobs.transform = 'log10';
jobs.lineSpecs = {'-s','--o',':^','-.x'};
outputs = plot_excel(excelFile,jobs,outDir);
```

- `jobs` 为同字段的 struct 数组，支持循环生成多个块/Case。唯一 `fileStem` 使用 ASCII 字母、数字、下划线、连字符；中文语义放在 title/labels。
- `xRange` 为单个单行/单列范围，或与 yRanges 等长的 cell 数组，支持各曲线使用自己的 X 和数据长度。`yRanges` 和 `labels` 为 cell 数组。不要使用跨多个实验块的范围。
- `lineSpecs` 超过八条曲线时须主动扩展足够的不同标记与线型。相同方法在同一任务不同 Case 中保持同一线型。
- 可选 `xLimits`、`yLimits` 为两元素数值数组；`xTicks`、`yTicks` 为递增数值数组；`fontName` 为已安装字体。默认横轴 min/max，纵轴自动，显示全部实际X刻度值及左右端点，不自动抽稀。
- 默认导出 900 dpi PNG/FIG，每个范围在日志中打印有效配对数。读取器支持数值文本及不间断空格，空白/NaN 留作缺失，其他非数值文本报错；含括号误差值的 `均值(误差)` 不可直接读取为单个数字，须先确认含义再适配。
- 图例由 `legend_curve_order` 按共同实测点的多数上下关系自动排序；labels 与 lineSpecs 仍按原曲线对应关系传入，不预先重排数据。导出汇总图时沿用每张源图的 Legend.String/PlotChildren 顺序。
- 模板为函数文件，应按签名调用，不能直接 `run('plot_excel.m')`。

汇总图：同时复制 `scripts/combine_case_plots.m`，在驱动脚本末尾调用 `summaryPaths = combine_case_plots(outputs,outDir,'all_cases');`。4图2行2列、6图3行2列，不设总标题；jobs.title 只写实际的 Case 编号。

当前样式以用户最新r.m为准：曲线0.5pt、标记6pt、坐标轴0.8pt；刻度7pt、轴标签约7.7pt，常规字重；图例8pt、宋体（本机可用时）、自动紧凑间距，保持符号大小。Case20pt不变。优先测量原生属性调整效果，不足时自动回退CompactLegend覆盖层；复制数据轴时排除Tag=CompactLegend。导出900dpi PNG、矢量PDF和FIG。保留右上角→向上扩展Y→左下角的避让顺序。

ARL1线宽：驱动目录同时复制arl1_line_width.m。job.lineWidths为基础线宽（默认0.5），job.arl1Mask可按曲线指定ARL1身份；未指定时按yLabel包含ARL1识别。ARL1固定设0.8pt，取消2.5pt及×1.3旧规则，非ARL1保留原值。图例样本通过LegendOriginalLineWidth保存原宽度，其他视觉属性不改。
