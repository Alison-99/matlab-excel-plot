function result = place_compact_legend(ax,lg,allowExpand)
% Public MATLAB graphics only. Try native token layout, measure actual text,
% then fall back to a compact overlay if native minimum row spacing persists.
if nargin<3, allowExpand=true; end
old=getappdata(lg,'CompactAxes');
if ~isempty(old)&&isgraphics(old), delete(old); end
lg.Visible='on'; lg.FontWeight='normal'; lg.Location='northeast';
lg.NumColumns=1; lg.Orientation='vertical'; lg.AutoUpdate='off';
fonts=listfonts; candidates={'宋体','SimSun','Songti SC'};
if ~isappdata(lg,'ConfiguredLegendFont')
    for k=1:numel(candidates)
        if any(strcmpi(fonts,candidates{k})), lg.FontName=candidates{k}; break; end
    end
end
lg.ItemTokenSize=[30 18]; drawnow;
base=getpixelposition(lg,true);
lg.ItemTokenSize=[16 max(6,lg.FontSize)]; drawnow;
native=getpixelposition(lg,true);
scale=get(groot,'ScreenPixelsPerInch')/72;
names=lg.String; hs=lg.PlotChildren; n=numel(names);
heights=zeros(n,1); widths=heights;
for k=1:n
    m=text(ax,0,0,names{k},'Units','points','FontSize',lg.FontSize, ...
        'FontName',lg.FontName,'FontWeight','normal','Interpreter','none', ...
        'Visible','off','Margin',0.01,'HandleVisibility','off');
    e=m.Extent; heights(k)=e(4); widths(k)=e(3); delete(m);
end
markerPt=max(arrayfun(@(h)h.MarkerSize,hs));
% Extent includes font leading. Single-line labels use a font-sized row
% with 1pt leading; multiline labels retain their full measured height.
multiline=any(cellfun(@(s)contains(s,newline),names));
if multiline, rowPt=max(max(heights),markerPt)+1;
else, rowPt=max(lg.FontSize,markerPt)+1; end
pad=1.5; token=16; gap=2;
targetH=n*rowPt+2*pad;
targetW=2*pad+token+gap+max(widths);
custom=native(4)/scale>targetH*1.10;
for k=1:n
    originalWidth=getappdata(hs(k),'LegendOriginalLineWidth');
    if ~isempty(originalWidth) && originalWidth~=hs(k).LineWidth, custom=true; end
end
if custom, sizePx=[targetW targetH]*scale; else, sizePx=native(3:4); end
original=ylim(ax); span=diff(original); result='northeast';
b=boxAt(ax,sizePx,'northeast');
if overlaps(ax,b)
    found=false;
    if allowExpand
        for fraction=[0.15 0.30 0.50 0.75 1.00]
            ylim(ax,[original(1),original(2)+span*fraction]); drawnow;
            b=boxAt(ax,sizePx,'northeast');
            if ~overlaps(ax,b), result='northeast-expanded'; found=true; break; end
        end
    end
    if ~found
        ylim(ax,original); result='southwest';
        b=boxAt(ax,sizePx,'southwest');
        if overlaps(ax,b)
            result='needs-review';
            warning('plot_excel:LegendOverlap','Both inside legend positions need visual review.');
        end
    end
end
if strcmp(result,'southwest')||strcmp(result,'needs-review')
    lg.Location='southwest';
else
    lg.Location='northeast';
end
if custom
    lg.Visible='off';
    fig=ancestor(ax,'figure');
    c=axes('Parent',fig,'Units','pixels','Position',b,'Tag','CompactLegend', ...
        'Color','w','XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',[], ...
        'Box','on','LineWidth',0.5,'XColor','k','YColor','k','HandleVisibility','off');
    hold(c,'on');
    for k=1:n
        h=hs(k); sampleWidth=getappdata(h,'LegendOriginalLineWidth');
        if isempty(sampleWidth), sampleWidth=h.LineWidth; end
        y=1-(pad+(k-0.5)*rowPt)/targetH;
        plot(c,[pad pad+token]/targetW,[y y],'Color',h.Color, ...
            'LineStyle',h.LineStyle,'LineWidth',sampleWidth,'HandleVisibility','off');
        plot(c,(pad+token/2)/targetW,y,'LineStyle','none','Marker',h.Marker, ...
            'MarkerSize',h.MarkerSize,'MarkerEdgeColor',h.MarkerEdgeColor, ...
            'MarkerFaceColor',h.MarkerFaceColor,'Color',h.Color, ...
            'LineWidth',sampleWidth,'HandleVisibility','off');
        text(c,(pad+token+gap)/targetW,y,names{k},'FontSize',lg.FontSize, ...
            'FontName',lg.FontName,'FontWeight','normal','Interpreter','none', ...
            'VerticalAlignment','middle','Margin',0.01,'Clipping','off','HandleVisibility','off');
    end
    c.Units='normalized'; % Position follows the figure; refit after resizing.
    setappdata(lg,'CompactAxes',c);
else
    % Native candidate already has compact enough rows: use supported legend.
    lg.Units='pixels'; lg.Position=b;
end
metrics=struct('defaultHeightPt',base(4)/scale,'nativeAdjustedHeightPt',native(4)/scale, ...
    'finalHeightPt',sizePx(2)/scale,'rowPitchPt',rowPt,'fontSize',lg.FontSize, ...
    'custom',custom,'placement',result,'overlap',overlaps(ax,b));
setappdata(lg,'CompactMetrics',metrics);
fprintf('Legend %d entries: default %.1f pt -> token %.1f pt -> final %.1f pt, font %.1f, custom=%d, overlap=%d\n', ...
    n,metrics.defaultHeightPt,metrics.nativeAdjustedHeightPt,metrics.finalHeightPt, ...
    metrics.fontSize,custom,metrics.overlap);
end

function b=boxAt(ax,sizePx,location)
a=getpixelposition(ax,true); gap=5*get(groot,'ScreenPixelsPerInch')/72;
w=sizePx(1); h=sizePx(2);
if strcmp(location,'northeast'), b=[a(1)+a(3)-w-gap,a(2)+a(4)-h-gap,w,h];
else, b=[a(1)+gap,a(2)+gap,w,h]; end
end

function hit = overlaps(ax,b)
a=getpixelposition(ax,true);
lines=findobj(ax,'Type','line');
xl=ax.XLim; yl=ax.YLim;
hit=false;
for k=1:numel(lines)
    h=lines(k); x=h.XData(:); y=h.YData(:);
    xp=a(1)+(x-xl(1))/diff(xl)*a(3);
    yp=a(2)+(y-yl(1))/diff(yl)*a(4);
    pad=2+h.LineWidth*get(groot,'ScreenPixelsPerInch')/72/2;
    if ~strcmp(h.Marker,'none')
        pad=pad+h.MarkerSize*get(groot,'ScreenPixelsPerInch')/72/2;
    end
    rect=[b(1)-pad,b(2)-pad,b(1)+b(3)+pad,b(2)+b(4)+pad];
    valid=isfinite(xp)&isfinite(yp);
    if any(valid & xp>=rect(1)&xp<=rect(3)&yp>=rect(2)&yp<=rect(4))
        hit=true; return
    end
    if ~strcmp(h.LineStyle,'none')
        for m=1:numel(xp)-1
            if valid(m)&&valid(m+1)&&segmentHits([xp(m),yp(m)],[xp(m+1),yp(m+1)],rect)
                hit=true; return
            end
        end
    end
end
end

function hit=segmentHits(p,q,r)
% Slab intersection, including horizontal/vertical segments and tangencies.
lo=0; hi=1; d=q-p;
for dim=1:2
    if abs(d(dim))<eps
        if p(dim)<r(dim)||p(dim)>r(dim+2), hit=false; return; end
    else
        ts=sort(([r(dim),r(dim+2)]-p(dim))/d(dim));
        lo=max(lo,ts(1)); hi=min(hi,ts(2));
        if lo>hi, hit=false; return; end
    end
end
hit=true;
end
