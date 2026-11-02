function outputs = plot_excel(excelFile, jobs, outDir, cfg)
% Shared plotting implementation adapted from the user's r.m.
% jobs: struct array. Each job specifies sheet, xRange, yRanges, labels,
% title, fileStem, xLabel, yLabel, transform ('log10' or 'none').
% Optional: lineSpecs, xLimits, yLimits, xTicks, yTicks, fontName.
% xRange may be a cell array (one range per curve) for unequal sampling.
if nargin<4, cfg=plot_style(); else, cfg=plot_style(cfg); end
assert(isfile(excelFile), 'Excel file does not exist.');
[jobs,data,legendReport]=prepare_plot_jobs(excelFile,jobs,cfg);
if ~isfolder(outDir), mkdir(outDir); end
save(fullfile(outDir,'legend_order_report.mat'),'legendReport');
outputs = cell(numel(jobs),2);
for j = 1:numel(jobs)
    job = jobs(j);
    assert(numel(job.yRanges)==numel(job.labels), 'Every curve needs a label.');
    stem = char(job.fileStem);
    assert(~isempty(regexp(stem,'^[a-zA-Z0-9_-]+$','once')), 'Use a safe unique fileStem.');
    pngPath = fullfile(outDir,[stem '.png']);
    figPath = fullfile(outDir,[stem '.fig']);
    assert(~isfile(pngPath) && ~isfile(figPath) && ~isfile(fullfile(outDir,[stem '.pdf'])), 'Output exists; choose a new directory or stem.');
    fig = figure('Visible','off','Color','w','Units','centimeters','Position',[2 2 cfg.FigureWidthCm cfg.SingleHeightCm]);
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig); hold(ax,'on');
    defaultSpecs = {'-s','--o',':^','-.x','-+','-.*',':v','-.*'};
    specs = getOption(job,'lineSpecs',defaultSpecs);
    assert(numel(specs)>=numel(job.yRanges),'Provide a distinct lineSpec for each curve.');
    allX = []; allY = [];
    handles=gobjects(numel(job.yRanges),1);
    curveX=cell(numel(job.yRanges),1); curveY=curveX;
    baseWidths=getOption(job,'lineWidths',cfg.BaseLineWidth);
    if isscalar(baseWidths), baseWidths=repmat(baseWidths,1,numel(job.yRanges)); end
    assert(numel(baseWidths)==numel(job.yRanges),'lineWidths must match curves');
    if isfield(job,'arl1Mask') && ~isempty(job.arl1Mask)
        arl1Mask=logical(job.arl1Mask);
        if isscalar(arl1Mask), arl1Mask=repmat(arl1Mask,1,numel(job.yRanges)); end
    else
        arl1Mask=repmat(contains(upper(string(job.yLabel)),'ARL1'),1,numel(job.yRanges));
    end
    assert(numel(arl1Mask)==numel(job.yRanges),'arl1Mask must match curves');
    for k = 1:numel(job.yRanges)
        xRange = job.xRange;
        if iscell(xRange), xRange = xRange{k}; end
        x=data{j}.x{k}; y=data{j}.y{k};
        valid=isfinite(x)&isfinite(y);
        allX = [allX; x(valid)]; allY = [allY; y(valid)]; %#ok<AGROW>
        x(~valid)=NaN; y(~valid)=NaN; % Keep gaps; do not connect across missing rows.
        curveX{k}=x; curveY{k}=y;
        handles(k)=plot(ax,x,y,specs{k},'Color','k','LineWidth',baseWidths(k),'MarkerSize',cfg.MarkerSize,'DisplayName',job.labels{k});
    end
    for k=1:numel(handles)
        setappdata(handles(k),'LegendOriginalLineWidth',baseWidths(k));
        if arl1Mask(k)
            handles(k).LineWidth=arl1_line_width(baseWidths(k));
        end
    end
    style=cfg;
    if isfield(job,'fontName')&&~isempty(job.fontName)
        style.FontName=job.fontName;
    end
    set(ax,'FontName',style.FontName,'FontSize',style.AxisFontSize, ...
        'FontWeight',style.FontWeight,'LineWidth',style.AxisLineWidth, ...
        'TickDir',style.TickDir,'TickLength',style.TickLength,'Box',style.Box, ...
        'XGrid',style.Grid,'YGrid',style.Grid,'TickLabelInterpreter',style.Interpreter);
    xlabel(ax,job.xLabel,'FontName',style.FontName,'Interpreter',style.Interpreter, ...
        'FontSize',style.XLabelFontSize,'FontWeight',style.FontWeight);
    ylabel(ax,job.yLabel,'FontName',style.FontName,'Interpreter',style.Interpreter, ...
        'FontSize',style.YLabelFontSize,'FontWeight',style.FontWeight);
    title(ax,job.title,'FontName',style.FontName,'Interpreter',style.Interpreter, ...
        'FontSize',style.TitleFontSize,'FontWeight',style.TitleFontWeight);
    [found,order]=ismember(job.legendOrder,job.labels); assert(all(found));
    lg=legend(ax,handles(order),job.labels(order),'FontName',style.LegendFontName, ...
        'FontSize',style.LegendFontSize,'FontWeight',style.FontWeight, ...
        'Interpreter',style.Interpreter,'Location','northeast','NumColumns',1,'Orientation','vertical');
    setappdata(lg,'ConfiguredLegendFont',true);
    setappdata(ax,'PlotStyle',style);
    fprintf('%s | legend top-to-bottom: %s\n',stem,strjoin(job.labels(order),' > '));
    xl = getOption(job,'xLimits',[min(allX) max(allX)]);
    if xl(1)<xl(2), xlim(ax,xl); end
    if isfield(job,'yLimits') && ~isempty(job.yLimits), ylim(ax,job.yLimits); end
    xt = getOption(job,'xTicks',unique(allX));
    xticks(ax,xt);
    if isfield(job,'yTicks') && ~isempty(job.yTicks), yticks(ax,job.yTicks); end
    % Explicit bounds must not silently hide measurements.
    yl = ylim(ax); xl = xlim(ax);
    if any(allX<xl(1) | allX>xl(2)) || any(allY<yl(1) | allY>yl(2))
        warning('plot_excel:ClippedData','Explicit axis limits clip data in %s.',stem);
    end
    allowExpand=~isfield(job,'yLimits') || isempty(job.yLimits);
    setappdata(ax,'LegendAllowExpandY',allowExpand);
    setappdata(ax,'LegendBaseYLim',ylim(ax));
    setappdata(ax,'OriginalYTickMode',ax.YTickMode);
    place_compact_legend(ax,lg,allowExpand);
    export_plot_figure(fig,fullfile(outDir,stem),style);
    outputs(j,:) = {pngPath,figPath};
    clear cleanup
end
end

function value = getOption(job,key,fallback)
value = fallback;
if isfield(job,key) && ~isempty(job.(key)), value = job.(key); end
end

