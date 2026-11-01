function order = legend_curve_order(xs, ys)
% Top-to-bottom legend order using majority position at shared measured X.
% Ties/overlaps do not vote. No interpolation or changes to plotted data.
n=numel(xs); edges=false(n); strength=zeros(n);
for a=1:n
    for b=a+1:n
        va=isfinite(xs{a}) & isfinite(ys{a});
        vb=isfinite(xs{b}) & isfinite(ys{b});
        xa=xs{a}(va); ya=ys{a}(va); xb=xs{b}(vb); yb=ys{b}(vb);
        assert(numel(unique(xa))==numel(xa) && numel(unique(xb))==numel(xb), ...
            'Legend ordering requires unique X per curve; resolve repeated measurements first.');
        [~,ia,ib]=intersect(xa,xb);
        if isempty(ia), continue; end
        d=ya(ia)-yb(ib);
        tol=1e-10*max(1,max(abs([ya(ia);yb(ib)])));
        up=nnz(d>tol); down=nnz(d<-tol);
        if up+down==0, continue; end
        strength(a,b)=(up-down)/(up+down); strength(b,a)=-strength(a,b);
        if up>down, edges(a,b)=true;
        elseif down>up, edges(b,a)=true;
        end
    end
end
% Topological order preserves every majority relation when consistent.
% Cycles: choose largest net majority wins, then strongest aggregate margin.
remaining=1:n; order=zeros(1,n); warned=false;
for k=1:n
    e=edges(remaining,remaining);
    candidates=find(sum(e,1)==0);
    if isempty(candidates)
        if ~warned
            warning('plot_excel:LegendCycle', ...
                'Crossing curves have cyclic majority positions; using wins and vote margins to resolve.');
            warned=true;
        end
        candidates=1:numel(remaining);
    end
    net=sum(e,2)-sum(e,1)';
    margin=sum(strength(remaining,remaining),2);
    keys=[-net(candidates),-margin(candidates),remaining(candidates)'];
    [~,idx]=sortrows(keys,[1 2 3]);
    picked=candidates(idx(1));
    order(k)=remaining(picked); remaining(picked)=[];
end
end
