function create_plot_project(excelFile,jobs,projectDir,cfg)
% 生成完整 R2023b 代码项目：主脚本、各 Case 脚本、合并脚本和全部依赖。
% Excel 路径只在生成的 plot_config.m 管理；默认复制原文件到 data/。
if nargin<4, cfg=plot_style(); else, cfg=plot_style(cfg); end
assert(isfile(excelFile),'Excel file missing.');
% 兼容旧 job.fontName，但生成项目时提升为一个集中样式参数。
if isfield(jobs,'fontName')
    names={jobs.fontName}; names=names(~cellfun(@isempty,names));
    if ~isempty(names)
        assert(numel(unique(string(names)))==1,'Use one common font across the batch.');
        cfg.FontName=names{1};
    end
    jobs=rmfield(jobs,'fontName');
end
assert(~isfolder(projectDir),'Choose a new project directory; existing files are not overwritten.');
[jobs,~,report]=prepare_plot_jobs(excelFile,jobs,cfg);
% 固定批量统计结果，单独执行任一 Case 时不会重新按一个 Case 改顺序。
if strcmp(cfg.LegendMode,'majority')||~isempty(cfg.LegendOrder)
    cfg.LegendOrder=report.standardOrder;
end
cfg.MethodLabels={}; cfg.MethodLineSpecs={};
for j=1:numel(jobs)
    for k=1:numel(jobs(j).labels)
        if ~ismember(jobs(j).labels{k},cfg.MethodLabels)
            cfg.MethodLabels{end+1}=jobs(j).labels{k};
            cfg.MethodLineSpecs{end+1}=jobs(j).lineSpecs{k};
        end
    end
end
mkdir(projectDir);
source=fileparts(mfilename('fullpath')); dependencies=dir(fullfile(source,'*.m'));
for k=1:numel(dependencies)
    copyfile(fullfile(source,dependencies(k).name),fullfile(projectDir,dependencies(k).name));
end
[~,name,ext]=fileparts(excelFile);
if cfg.CopyExcel
    mkdir(fullfile(projectDir,'data')); copyfile(excelFile,fullfile(projectDir,'data',[name ext]));
    pathExpression=['fullfile(projectDir,''data'',' literal([name ext]) ')'];
else
    pathExpression=literal(excelFile);
end
f=fopen(fullfile(projectDir,'plot_config.m'),'w','n','UTF-8'); assert(f>=0);
c=onCleanup(@()fclose(f));
fprintf(f,'function [excelFile,jobs,cfg,projectDir] = plot_config()\n');
fprintf(f,'%% 统一配置：在此修改 Excel 路径、真实单元格范围和样式。\n');
fprintf(f,'projectDir=fileparts(mfilename(''fullpath''));\nexcelFile=%s;\n',pathExpression);
fprintf(f,'%% 字体和图例顺序在项目生成时固定；所有入口复用同一配置。\n');
fields=fieldnames(cfg);
for k=1:numel(fields), fprintf(f,'cfg.%s=%s;\n',fields{k},literal(cfg.(fields{k}))); end
fields=fieldnames(jobs);
for j=1:numel(jobs)
    fprintf(f,'%% %s：读取源 Excel，不插值、不平滑。\n',jobs(j).title);
    for k=1:numel(fields), fprintf(f,'jobs(%d).%s=%s;\n',j,fields{k},literal(jobs(j).(fields{k}))); end
end
fprintf(f,'end\n'); clear c
writeEntry(projectDir,'plot_all_cases.m','all',0,'所有 Case 单图及合并图');
writeEntry(projectDir,'plot_combined_ARL1.m','combined',0,'合并图（自动先生成所需源 Case）');
writeEntry(projectDir,'run_plots.m','all',0,'兼容原有调用方式');
for j=1:numel(jobs)
    writeEntry(projectDir,sprintf('plot_case_%02d.m',j),'case',j,jobs(j).title);
end
save(fullfile(projectDir,'legend_order_report.mat'),'report');
fprintf('Complete MATLAB project: %s\n',projectDir);
end

function writeEntry(folder,name,mode,index,description)
f=fopen(fullfile(folder,name),'w','n','UTF-8'); assert(f>=0); c=onCleanup(@()fclose(f));
fprintf(f,'%% %s；MATLAB R2023b 可直接运行，全部依赖随项目保存。\n',description);
fprintf(f,'addpath(fileparts(mfilename(''fullpath'')));\n');
fprintf(f,'resultDir=run_plot_project(''%s'',%d);\n',mode,index);
end

function out=literal(v)
% 配置用显式 MATLAB 源代码序列化，避免隐藏工作区变量或 .mat 依赖。
if ischar(v)
    assert(isrow(v)||isempty(v),'Configuration text must be single-line.');
    if contains(v,newline), out=['sprintf(' literal(strrep(strrep(v,'\','\\'),newline,'\n')) ')'];
    else, out=['''' strrep(v,'''','''''') '''']; end
elseif isstring(v)
    if isscalar(v), out=literal(char(v)); else, out=literal(cellstr(v)); end
elseif islogical(v)
    out=['logical(' mat2str(v) ')'];
elseif isnumeric(v)
    out=mat2str(v,17);
elseif iscell(v)
    parts=cell(size(v)); for k=1:numel(v), parts{k}=literal(v{k}); end
    if isempty(v), out='{}'; return; end
    rows=cell(1,size(v,1));
    for k=1:size(v,1), rows{k}=strjoin(parts(k,:),','); end
    out=['{' strjoin(rows,';') '}'];
else
    error('Unsupported configuration type: %s',class(v));
end
end
