# 内置绘图函数配置

`plot_excel(excelFile, jobs, outDir)` 读取配置指定的真实单元格。工作簿的语义识别由使用技能的 Codex 完成；函数不声称能从任意 Excel 布局自动判断 ARL1。用户无需编写配置或提供 .m，由 Codex 检查数据后生成驱动脚本。

首选生成完整可搬移项目：识别并构造 jobs 后调用 `create_plot_project(excelFile,jobs,newProjectDir,cfg)`。函数默认原样复制 Excel 至 data/，生成：

- `plot_config.m`：显式 Excel 相对路径、每条曲线的读取范围、完整样式和冻结的整批图例顺序。
- `plot_all_cases.m` / `run_plots.m`：直接执行全部单图和合并图。
- `plot_case_01.m` 等：直接执行对应 Case；`plot_combined_ARL1.m`：自动生成源 Case 后合并。
- 全部辅助 `.m`：包括读取、数据处理、绘图、排序、图例避让及导出，不依赖原 Skill 路径或临时 MAT 文件。

每次运行创建 results/唯一目录；重跑不覆盖旧图。用户只需把整个项目搬移后在 MATLAB R2023b 中运行主脚本。要换数据文件和修改范围，编辑 `plot_config.m`；要让新数据重新投票，可清空 `cfg.LegendOrder` 后执行主脚本。`cfg.CopyExcel=false` 可保留集中配置的原文件路径，此时迁移需手动改路径。

原来的三参数 `plot_excel` 和 `combine_case_plots` 接口仍兼容；第四参数可传统一 cfg。直接调用时必须同时提供 scripts/ 下全部依赖，以下低层调用不是完整项目交付的替代品。

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
- 图例先按 `legend_curve_order` 生成候选，再由 `prepare_plot_jobs` 取整批完整顺序的众数；并列优先 StandardLegendOrder，再取首个有效完整候选。`cfg.LegendOrder` 为人工覆盖；`cfg.LegendMode='per-case'` 保留旧行为。缺方法的 Case 过滤标准顺序；labels 与 lineSpecs 按原曲线对应关系传入，实际数据不重排。合并时保留句柄/标签对应。
- 模板为函数文件，应按签名调用，不能直接 `run('plot_excel.m')`。

汇总图：同时复制 `scripts/combine_case_plots.m`，在驱动脚本末尾调用 `summaryPaths = combine_case_plots(outputs,outDir,'all_cases');`。4图2行2列、6图3行2列，不设总标题；jobs.title 只写实际的 Case 编号。

当前样式以用户最新r.m为准：曲线0.5pt、标记6pt、坐标轴0.8pt；刻度7pt、轴标签约7.7pt，常规字重；图例8pt、宋体（本机可用时）、自动紧凑间距，保持符号大小。Case20pt不变。优先测量原生属性调整效果，不足时自动回退CompactLegend覆盖层；复制数据轴时排除Tag=CompactLegend。导出900dpi PNG、矢量PDF和FIG。保留右上角→向上扩展Y→左下角的避让顺序。

ARL1线宽：驱动目录同时复制arl1_line_width.m。job.lineWidths为基础线宽（默认0.5），job.arl1Mask可按曲线指定ARL1身份；未指定时按yLabel包含ARL1识别。ARL1固定设0.8pt，取消2.5pt及×1.3旧规则，非ARL1保留原值。图例样本通过LegendOriginalLineWidth保存原宽度，其他视觉属性不改。

## 统一样式与导出

`cfg=plot_style()` 保留当前参数：AxisFontSize=7、标签7.7、LegendFontSize=8、TitleFontSize=20；常规字重，标题bold；基础线宽0.5、ARL1固定0.8、MarkerSize=6、AxisLineWidth=0.8；24×18cm单图、24×(11×行数)cm合并图；900dpi、白底。字体优先SimSun/Songti SC，生成后在配置中固定实际字体名称；不使用用户示例中的2.5pt/600dpi数值覆盖默认。

合并图从源轴复制字体、字号、TickDir/TickLength、Box/Grid、刻度标签旋转、范围和文本属性；从源曲线复制线型、标记、数据与线宽；使用同一图例字体/字号。轴范围仍由各Case数据决定，避让可按布局向上扩展，不统一强制固定范围。

`export_plot_figure` 在drawnow和图例避让后固定最终刻度/范围，以同一Figure连续导出PNG/PDF/FIG，检查导出前后对象状态；默认painters及矢量PDF。渲染差异仍需实际对照PNG和PDF，不能仅凭同一Figure宣称一致。PDF中可嵌入字体由MATLAB导出器处理；字体缺失/不可嵌入须说明，不能默认栅格化解决。参见[MathWorks exportgraphics](https://www.mathworks.com/help/matlab/ref/exportgraphics.html)。
