function v = read_plot_vector(file,sheet,range)
% 直接读取指定单元格；空值保留 NaN，不插值、不补零。
C=readcell(file,'Sheet',sheet,'Range',range);
assert(isvector(C),'Each range must contain a single row or column.');
v=nan(numel(C),1);
for k=1:numel(C)
    a=C{k};
    if isnumeric(a)&&isscalar(a)
        v(k)=a;
    elseif ischar(a)||(isstring(a)&&isscalar(a))
        t=strtrim(erase(string(a),char(160)));
        if ismissing(t)||strlength(t)==0, continue; end
        v(k)=str2double(t);
        assert(~isnan(v(k))||strcmpi(t,'NaN'), ...
            'Unparsed text at %s!%s, element %d: %s',sheet,range,k,t);
    elseif isempty(a)||all(ismissing(a),'all')
        continue
    else
        error('Unsupported cell type in %s!%s.',sheet,range);
    end
end
assert(~any(isinf(v)),'Infinite data in %s!%s.',sheet,range);
end
