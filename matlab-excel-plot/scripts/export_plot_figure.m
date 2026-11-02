function export_plot_figure(fig,stem,cfg)
% PNG/PDF/FIG 共用最终 Figure，不为 PDF 重画或默认栅格化。
set(fig,'Color',cfg.BackgroundColor,'Renderer',cfg.Renderer,'InvertHardcopy','off');
drawnow;
axesList=findall(fig,'Type','axes');
for k=1:numel(axesList)
    ax=axesList(k);
    % 固定最终刻度/范围，避免不同格式重新计算自动刻度。
    set(ax,'XLim',ax.XLim,'YLim',ax.YLim,'XTick',ax.XTick,'YTick',ax.YTick);
end
drawnow; before=captureState(fig);
exportgraphics(fig,[stem '.png'],'Resolution',cfg.ExportDPI,'BackgroundColor',cfg.BackgroundColor);
assert(isequaln(before,captureState(fig)),'PNG export changed figure state.');
exportgraphics(fig,[stem '.pdf'],'ContentType','vector','BackgroundColor',cfg.BackgroundColor);
assert(isequaln(before,captureState(fig)),'PDF export changed figure state.');
setappdata(fig,'ExportStyle',cfg); savefig(fig,[stem '.fig']);
end
function state=captureState(fig)
axs=findall(fig,'Type','axes'); state=cell(numel(axs),1);
for k=1:numel(axs)
    a=axs(k); state{k}={a.Position,a.XLim,a.YLim,a.XTick,a.YTick, ...
        a.FontName,a.FontSize,a.LineWidth,a.XTickLabel,a.YTickLabel};
end
end
