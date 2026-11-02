function resultDir = run_plot_project(mode,index)
% 所有入口的完整执行流程；仅依赖本项目文件和 Excel，不依赖 Codex。
if nargin<1, mode='all'; end
if nargin<2, index=0; end
[excelFile,jobs,cfg,projectDir]=plot_config();
assert(isfile(excelFile),'Excel missing: edit excelFile in plot_config.m.');
fonts=listfonts;
assert(any(strcmpi(fonts,cfg.FontName))&&any(strcmpi(fonts,cfg.LegendFontName)), ...
    'Configured font missing on this computer; install it or explicitly update plot_config.m.');
% 重跑生成新目录，保留以往结果；输出位置仍在项目内部。
root=fullfile(projectDir,'results'); if ~isfolder(root), mkdir(root); end
[~,uniqueName]=fileparts(tempname(root)); resultDir=fullfile(root,uniqueName); mkdir(resultDir);
diary(fullfile(resultDir,'matlab_run.log')); cleanup=onCleanup(@()diary('off'));
fprintf('MATLAB %s\nmatlabroot=%s\ncomputer=%s\n',version,matlabroot,computer);
fprintf('Excel=%s\nFont=%s, LegendFont=%s, DPI=%g\n', ...
    excelFile,cfg.FontName,cfg.LegendFontName,cfg.ExportDPI);
switch mode
    case 'case'
        assert(index>=1&&index<=numel(jobs));
        outputs=plot_excel(excelFile,jobs(index),resultDir,cfg);
    case {'all','combined'}
        outputs=plot_excel(excelFile,jobs,resultDir,cfg);
        combine_case_plots(outputs,resultDir,'all_cases_ARL1',cfg);
    otherwise
        error('Unknown plotting mode: %s',mode);
end
save(fullfile(resultDir,'execution_config.mat'),'jobs','cfg','excelFile','outputs');
fprintf('SUCCESS: %s\n',resultDir);
end
