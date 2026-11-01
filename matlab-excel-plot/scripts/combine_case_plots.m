function paths = combine_case_plots(outputs,outDir,stem)
% Combine case FIGs, preserving ordered legends. No overall title.
n=size(outputs,1);
if n==4, rows=2; cols=2;
elseif n==6, rows=3; cols=2;
else, cols=min(2,n); rows=ceil(n/cols);
end
paths={fullfile(outDir,[stem '.png']),fullfile(outDir,[stem '.fig'])};
assert(~isfile(paths{1}) && ~isfile(paths{2}),'Summary output already exists.');
f=figure('Visible','off','Color','w','Units','centimeters','Position',[2 2 24 11*rows]);
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
    set(dst,'XLim',src.XLim,'YLim',src.YLim,'XTick',src.XTick, ...
        'YTick',src.YTick,'FontSize',7,'FontWeight','normal','LineWidth',0.8,'Box','on');
    baseY=getappdata(src,'LegendBaseYLim');
    if ~isempty(baseY), ylim(dst,baseY); end
    setappdata(dst,'LegendBaseYLim',ylim(dst));
    if strcmp(src.YTickMode,'auto'), dst.YTickMode='auto'; end
    xlabel(dst,src.XLabel.String,'Interpreter','none','FontSize',7.7,'FontWeight','normal');
    ylabel(dst,src.YLabel.String,'Interpreter','none','FontSize',7.7,'FontWeight','normal');
    title(dst,src.Title.String,'Interpreter','none','FontSize',20,'FontWeight','bold');
    if ~isempty(srcLegend)
        names=srcLegend.String;
        handles=gobjects(numel(names),1);
        for m=1:numel(names)
            handles(m)=findobj(dst,'Type','line','DisplayName',names{m});
        end
        lg=legend(dst,handles,names,'FontSize',8,'FontWeight','normal','Interpreter','none','Location','northeast','NumColumns',1,'Orientation','vertical');
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
exportgraphics(f,paths{1},'Resolution',900);
exportgraphics(f,fullfile(outDir,[stem '.pdf']),'ContentType','vector','BackgroundColor','white');
savefig(f,paths{2});
end
