function paths = combine_case_plots(outputs,outDir,stem,cfg)
% Combine case FIGs, preserving ordered legends. No overall title.
if nargin<4, cfg=plot_style(); else, cfg=plot_style(cfg); end
n=size(outputs,1); assert(n>0,'No cases to combine.');
if n==4, rows=2; cols=2;
elseif n==6, rows=3; cols=2;
else, cols=min(2,n); rows=ceil(n/cols);
end
paths={fullfile(outDir,[stem '.png']),fullfile(outDir,[stem '.fig'])};
assert(~isfile(paths{1}) && ~isfile(paths{2}) && ~isfile(fullfile(outDir,[stem '.pdf'])),'Summary output already exists.');
f=figure('Visible','off','Color','w','Units','centimeters','Position',[2 2 cfg.FigureWidthCm cfg.CombinedRowHeightCm*rows]);
cleanup=onCleanup(@()close(f));
t=tiledlayout(f,rows,cols,'TileSpacing','compact','Padding','compact');
for k=1:n
    srcFig=openfig(outputs{k,2},'invisible');
    srcCleanup=onCleanup(@()close(srcFig));
    src=findobj(srcFig,'Type','axes','-not','Tag','CompactLegend');
    assert(isscalar(src),'Expected one axes per case FIG.');
    srcLegend=findobj(srcFig,'Type','legend');
    dst=nexttile(t,k);
    copyobj(allchild(src),dst);
    originalLines=findobj(src,'Type','line');
    for m=1:numel(originalLines)
        sourceLine=originalLines(m);
        targetLine=findobj(dst,'Type','line','DisplayName',sourceLine.DisplayName);
        if isscalar(targetLine)
            setappdata(targetLine,'LegendOriginalLineWidth',getappdata(sourceLine,'LegendOriginalLineWidth'));
        end
    end
    allowExpand=getappdata(src,'LegendAllowExpandY');
    if isempty(allowExpand), allowExpand=true; end
    setappdata(dst,'LegendAllowExpandY',allowExpand);
    props={'FontName','FontSize','FontWeight','LineWidth','TickDir','TickLength', ...
        'Box','XGrid','YGrid','TickLabelInterpreter','XScale','YScale', ...
        'XDir','YDir','XTickLabelRotation','YTickLabelRotation', ...
        'XLim','YLim','XTick','YTick','XTickLabel','YTickLabel'};
    for m=1:numel(props), dst.(props{m})=src.(props{m}); end
    baseY=getappdata(src,'LegendBaseYLim');
    if ~isempty(baseY), ylim(dst,baseY); end
    setappdata(dst,'LegendBaseYLim',ylim(dst));
    tickMode=getappdata(src,'OriginalYTickMode');
    if isempty(tickMode)||strcmp(tickMode,'auto'), dst.YTickMode='auto'; dst.YTickLabelMode='auto'; end
    sourceTexts={src.XLabel,src.YLabel,src.Title}; targetTexts={dst.XLabel,dst.YLabel,dst.Title};
    textProps={'String','FontName','FontUnits','FontSize','FontWeight','Interpreter'};
    for m=1:3
        for r=1:numel(textProps), targetTexts{m}.(textProps{r})=sourceTexts{m}.(textProps{r}); end
    end
    style=getappdata(src,'PlotStyle');
    if isempty(style), style=cfg; end
    setappdata(dst,'PlotStyle',style);
    if ~isempty(srcLegend)
        names=srcLegend.String;
        handles=gobjects(numel(names),1);
        for m=1:numel(names)
            handles(m)=findobj(dst,'Type','line','DisplayName',names{m});
        end
        lg=legend(dst,handles,names,'FontName',srcLegend.FontName, ...
            'FontSize',srcLegend.FontSize,'FontWeight',srcLegend.FontWeight, ...
            'Interpreter',srcLegend.Interpreter,'Location','northeast','NumColumns',1,'Orientation','vertical');
        setappdata(lg,'ConfiguredLegendFont',true);
    end
    clear srcCleanup
end
drawnow;
allLegends=findobj(f,'Type','legend');
for k=1:numel(allLegends)
    lg=allLegends(k);
    ax=ancestor(lg.PlotChildren(1),'axes');
    place_compact_legend(ax,lg,getappdata(ax,'LegendAllowExpandY'));
end
assert(isequal(t.GridSize,[rows cols]));
assert(isempty(t.Title.String),'Summary must not have an overall title.');
export_plot_figure(f,fullfile(outDir,stem),cfg);
end
