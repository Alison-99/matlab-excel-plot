function [jobs,data,report] = prepare_plot_jobs(excelFile,jobs,cfg)
% 绘图前读完整批数据、统计图例顺序；不改数据与曲线绘制顺序。
assert(~isempty(jobs),'No plotting jobs.');
defaultSpecs={'-s','--o',':^','-.x','-+','-.*',':v','--d'};
methods={}; specs={}; data=cell(size(jobs)); candidates=cell(size(jobs));
if ~isempty(cfg.MethodLabels)
    methods=cellstr(string(cfg.MethodLabels)); specs=cellstr(string(cfg.MethodLineSpecs));
    assert(numel(methods)==numel(specs),'Method style map lengths differ.');
end
for j=1:numel(jobs)
    job=jobs(j); names=cellstr(string(job.labels)); names=names(:)';
    assert(numel(unique(names))==numel(names),'Duplicate method labels in %s.',job.fileStem);
    assert(numel(job.yRanges)==numel(names),'Every curve needs a label.');
    explicit=isfield(job,'lineSpecs')&&~isempty(job.lineSpecs);
    js=cell(1,numel(names)); xs=js; ys=js;
    for k=1:numel(names)
        m=find(strcmp(methods,names{k}));
        if isempty(m)
            methods{end+1}=names{k}; m=numel(methods); %#ok<AGROW>
            assert(explicit||m<=numel(defaultSpecs),'Provide additional lineSpecs.');
            if explicit, specs{m}=job.lineSpecs{k}; else, specs{m}=defaultSpecs{m}; end
        elseif explicit
            assert(strcmp(specs{m},job.lineSpecs{k}), ...
                'Inconsistent lineSpec for method %s across cases.',names{k});
        end
        js{k}=specs{m}; xr=job.xRange;
        if iscell(xr), xr=xr{k}; end
        x=read_plot_vector(excelFile,job.sheet,xr);
        y=read_plot_vector(excelFile,job.sheet,job.yRanges{k});
        assert(numel(x)==numel(y),'X/Y lengths differ for %s.',names{k});
        good=isfinite(x)&isfinite(y); assert(any(good),'No valid data for %s.',names{k});
        if strcmp(job.transform,'log10')
            assert(all(y(good)>0),'Nonpositive ARL cannot use log10.'); y(good)=log10(y(good));
        else
            assert(strcmp(job.transform,'none'),'Unknown transform.');
        end
        fprintf('%s | %s | X=%s Y=%s | %d/%d pairs\n', ...
            job.fileStem,names{k},xr,job.yRanges{k},nnz(good),numel(x));
        x(~good)=NaN; y(~good)=NaN; xs{k}=x; ys{k}=y;
    end
    jobs(j).labels=names; jobs(j).lineSpecs=js;
    candidates{j}=names(legend_curve_order(xs,ys));
    data{j}=struct('x',{xs},'y',{ys});
end
% 完整方法集合投票；缺方法的 Case 仅过滤标准顺序，不伪造曲线。
actual={}; for j=1:numel(jobs), actual=union(actual,jobs(j).labels,'stable'); end
full=find(cellfun(@(c)numel(c)==numel(actual)&&all(ismember(actual,c)),candidates));
full=full(:)';
incompleteFallback=isempty(full);
if incompleteFallback
    sizes=cellfun(@numel,candidates); full=find(sizes==max(sizes)); full=full(:)';
    fprintf('No complete-method case: vote among largest sets, append unseen methods stably.\n');
end
counts=zeros(1,numel(candidates));
for j=full, counts(j)=sum(cellfun(@(c)isequal(c,candidates{j}),candidates(full))); end
winners=full(counts(full)==max(counts(full))); tie=any(cellfun(@(c)~isequal(c,candidates{winners(1)}),candidates(winners)));
standard=cfg.LegendOrder;
if isempty(standard)
    pick=winners(1);
    for j=winners
        if isequal(candidates{j},cfg.StandardLegendOrder), pick=j; break; end
    end
    standard=candidates{pick};
    if tie, fprintf('Legend frequency tie: configured standard if tied, otherwise first eligible plot.\n'); end
else
    standard=cellstr(string(standard)); standard=standard(:)';
    assert(all(ismember(actual,standard)),'Manual LegendOrder must include every actual method.');
    assert(numel(unique(standard))==numel(standard),'Duplicate names in LegendOrder.');
end
standard=[standard,actual(~ismember(actual,standard))];
for j=1:numel(jobs)
    if strcmp(cfg.LegendMode,'per-case')&&isempty(cfg.LegendOrder)
        jobs(j).legendOrder=candidates{j};
    else
        jobs(j).legendOrder=standard(ismember(standard,jobs(j).labels));
    end
end
report=struct('candidateOrders',{candidates},'counts',counts, ...
    'standardOrder',{standard},'tie',tie,'incompleteFallback',incompleteFallback);
fprintf('Batch legend standard: %s\n',strjoin(standard,' > '));
end
