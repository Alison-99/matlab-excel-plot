function outputs = plot_excel(excelFile, jobs, outDir)
% Shared plotting implementation adapted from the user's r.m.
% jobs: struct array. Each job specifies sheet, xRange, yRanges, labels,
% title, fileStem, xLabel, yLabel, transform ('log10' or 'none').
% Optional: lineSpecs, xLimits, yLimits, xTicks, yTicks, fontName.
% xRange may be a cell array (one range per curve) for unequal sampling.
assert(isfile(excelFile), 'Excel file does not exist.');
if ~isfolder(outDir), mkdir(outDir); end
outputs = cell(numel(jobs),2);
for j = 1:numel(jobs)
    job = jobs(j);
    assert(numel(job.yRanges)==numel(job.labels), 'Every curve needs a label.');
    stem = char(job.fileStem);
    assert(~isempty(regexp(stem,'^[a-zA-Z0-9_-]+$','once')), 'Use a safe unique fileStem.');
    pngPath = fullfile(outDir,[stem '.png']);
    figPath = fullfile(outDir,[stem '.fig']);
    assert(~isfile(pngPath) && ~isfile(figPath), 'Output exists; choose a new directory or stem.');
    fig = figure('Visible','off','Color','w','Units','centimeters','Position',[2 2 24 18]);
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig); hold(ax,'on');
    defaultSpecs = {'-s','--o',':^','-.x','-+','-.*',':v','-.*'};
    specs = getOption(job,'lineSpecs',defaultSpecs);
    assert(numel(specs)>=numel(job.yRanges),'Provide a distinct lineSpec for each curve.');
    allX = []; allY = [];
    handles=gobjects(numel(job.yRanges),1);
    curveX=cell(numel(job.yRanges),1); curveY=curveX;
    baseWidths=getOption(job,'lineWidths',0.5);
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
        x = readVector(excelFile, job.sheet, xRange);
        y = readVector(excelFile, job.sheet, job.yRanges{k});
        assert(numel(x)==numel(y),'X/Y lengths differ for curve %d.',k);
        valid = isfinite(x) & isfinite(y);
        assert(any(valid),'Curve has no valid X/Y pairs.');
        if strcmp(job.transform,'log10')
            assert(all(y(valid)>0),'Nonpositive ARL cannot be transformed with log10.');
            y(valid) = log10(y(valid));
        else
            assert(strcmp(job.transform,'none'),'Unknown transform.');
        end
        fprintf('%s | %s | X=%s Y=%s | %d/%d pairs\n',stem,job.labels{k},xRange,job.yRanges{k},nnz(valid),numel(x));
        allX = [allX; x(valid)]; allY = [allY; y(valid)]; %#ok<AGROW>
        x(~valid)=NaN; y(~valid)=NaN; % Keep gaps; do not connect across missing rows.
        curveX{k}=x; curveY{k}=y;
        handles(k)=plot(ax,x,y,specs{k},'Color','k','LineWidth',baseWidths(k),'MarkerSize',6,'DisplayName',job.labels{k});
    end
    for k=1:numel(handles)
        setappdata(handles(k),'LegendOriginalLineWidth',baseWidths(k));
        if arl1Mask(k)
            handles(k).LineWidth=arl1_line_width(baseWidths(k));
        end
    end
    xlabel(ax,job.xLabel,'Interpreter','none','FontSize',7.7,'FontWeight','normal');
    ylabel(ax,job.yLabel,'Interpreter','none','FontSize',7.7,'FontWeight','normal');
    title(ax,job.title,'Interpreter','none','FontSize',20,'FontWeight','bold');
    set(ax,'FontSize',7,'FontWeight','normal','LineWidth',0.8,'Box','on');
    order=legend_curve_order(curveX,curveY);
    lg=legend(ax,handles(order),job.labels(order),'FontSize',8,'FontWeight','normal','Interpreter','none','Location','northeast','NumColumns',1,'Orientation','vertical');
    fprintf('%s | legend top-to-bottom: %s\n',stem,strjoin(job.labels(order),' > '));
    if isfield(job,'fontName') && ~isempty(job.fontName)
        set(findall(fig,'-property','FontName'),'FontName',job.fontName);
    end
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
    place_compact_legend(ax,lg,allowExpand);
    exportgraphics(fig,pngPath,'Resolution',900);
    exportgraphics(fig,fullfile(outDir,[stem '.pdf']),'ContentType','vector','BackgroundColor','white');
    savefig(fig,figPath);
    outputs(j,:) = {pngPath,figPath};
    clear cleanup
end
end

function value = getOption(job,key,fallback)
value = fallback;
if isfield(job,key) && ~isempty(job.(key)), value = job.(key); end
end

function v = readVector(file,sheet,range)
C = readcell(file,'Sheet',sheet,'Range',range);
assert(isvector(C),'Each range must contain a single row or column.');
v = nan(numel(C),1);
for k = 1:numel(C)
    a = C{k};
    if isnumeric(a) && isscalar(a)
        v(k) = a;
    elseif ischar(a) || (isstring(a) && isscalar(a))
        t = strtrim(erase(string(a),char(160)));
        if ismissing(t) || strlength(t)==0, continue; end
        v(k) = str2double(t);
        assert(~isnan(v(k)) || strcmpi(t,'NaN'), ...
            'Unparsed text at %s!%s, element %d: %s',sheet,range,k,t);
    elseif isempty(a) || all(ismissing(a),'all')
        continue
    else
        error('Unsupported cell type in %s!%s.',sheet,range);
    end
end
end
