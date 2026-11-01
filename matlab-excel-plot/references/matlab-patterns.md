# MATLAB 实现参考

以下是数值 X、多数值 Y 的最小模式。根据已检查的工作簿替换配置；日期、分组、误差条和非标准表头需要单独调整。面向 MATLAB R2023b；其他版本先检查函数可用性。

```matlab
% 配置：填写真实路径、表名和原始列名
inputFile = '/absolute/path/data.xlsx';
sheet = 'Sheet1';
xName = 'Time';
yNames = {'Signal A', 'Signal B'};
xLabel = 'Time'; % 仅使用已确认的单位
 yLabel = 'Signal';
outDir = fullfile(fileparts(inputFile), 'matlab_plots');
baseName = 'signals'; % 如结果已存在，改用唯一名称

assert(isfile(inputFile), 'Input workbook does not exist.');
opts = detectImportOptions(inputFile, 'Sheet', sheet, ...
    'VariableNamingRule', 'preserve');
T = readtable(inputFile, opts);
required = [{xName}, yNames];
assert(all(ismember(required, T.Properties.VariableNames)), ...
    'Requested columns are missing. Inspect the workbook headers.');
x = T.(xName);
assert(isnumeric(x) && isvector(x), 'Expected a numeric X column.');

if ~isfolder(outDir), mkdir(outDir); end
extensions = {'.png', '.fig'};
for k = 1:numel(extensions)
    assert(~isfile(fullfile(outDir, [baseName extensions{k}])), ...
        'Output exists. Choose a new baseName.');
end
fig = figure('Color', 'w', 'Visible', 'off', ...
    'Position', [100 100 1000 650]);
ax = axes(fig);
hold(ax, 'on');
for k = 1:numel(yNames)
    y = T.(yNames{k});
    assert(isnumeric(y) && isvector(y), 'Expected numeric Y columns.');
    valid = isfinite(x) & isfinite(y);
    fprintf('%s: %d/%d valid pairs; %d excluded rows\n', ...
        yNames{k}, nnz(valid), height(T), nnz(~valid));
    assert(any(valid), 'No valid X/Y pairs.');
    % 用 NaN 留下缺测位置，避免折线跨越缺失段。
    xp = x; yp = y;
    xp(~valid) = NaN; yp(~valid) = NaN;
    plot(ax, xp, yp, 'LineWidth', 1.5, 'DisplayName', yNames{k});
end
xlabel(ax, xLabel, 'Interpreter', 'none');
ylabel(ax, yLabel, 'Interpreter', 'none');
set(ax, 'FontSize', 12, 'LineWidth', 1, 'Box', 'on');
legend(ax, 'show', 'Interpreter', 'none', 'Location', 'best');
exportgraphics(fig, fullfile(outDir, [baseName '.png']), 'Resolution', 300);
savefig(fig, fullfile(outDir, [baseName '.fig']));
close(fig);
```

- 中文字体：通过 `listfonts` 查询可用字体，再设置 axes 和文本对象的 `FontName`，不要假设任意系统都有某个字体。
- 不连续时间序列：若需要表现缺失时间间隔，检查时间步长；仅依靠已有行中的 NaN 不能识别整行缺失的时刻。
- 多 sheet：先 `sheetnames(inputFile)`，为每张表独立检查类型和单位，不假定各表结构一致。
- 批处理示例：`"/Applications/MATLAB_R2023b.app/bin/matlab" -batch "run('/absolute/path/plot_data.m')"`。这是简单路径示例；含单引号等特殊字符时按 shell 和 MATLAB 两层语法处理。
