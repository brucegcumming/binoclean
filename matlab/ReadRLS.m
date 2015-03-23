function result = ReadRLS(name, varargin)

txt = scanlines(name);
checkdisp = 1;
explore = 0;
maxframes = 500;

idid = find(strncmp('id',txt,2));
mtid = find(strncmp('mtrS',txt,4));
rlsid = setdiff(1:length(txt),union(idid,mtid));
if checkdisp
    corrs = zeros(1,length(rlsid));
    disps = corrs;
end


frame = 1;
for j = 1:length(rlsid)
    s = txt{rlsid(j)};
    id = strfind(s,':');
    a = id(1)+1;
    k = 1;
    while a < length(s)
        x = sscanf(s(a),'%1x');
        if isempty(x) 
            a = length(s);
        else
        im(k,1) = bitand(x,8); %R eye
        im(k,2) = bitand(x,2);
        k = k+1;
        a = id(1)+k;
        end
    end
    im(:,1) = bitshift(im(:,1),-2);
    if checkdisp
        lags = -11:11;
        for k = 1:length(lags)
            if lags(k) > 0
                x = corrcoef(im(1:end-lags(k),1),im(1+lags(k):end,2));
            else
                x = corrcoef(im(1-lags(k):end,1),im(1:end+lags(k),2));
            end
            xc(k) = x(1,2);
        end
        [a,b] = max(xc);
        [c,d] = min(xc);
        result.disps(j) = lags(b);
        result.corrs(j) = a;
        if a < 0.95 && c > -0.95
            imagesc(im');
            cim = im;
            cim(:,1) = circshift(im(:,1),lags(b));
            imagesc(cim');
        elseif a >= 0.95
            result.disps(j) = lags(b);
            result.corrs(j) = a;
        else
            result.disps(j) = lags(d);
            result.corrs(j) = c;
        end
    end
    if explore
        GetFigure('RLS');
        imagesc(im');
        [xc, lags] = xcorr(im(1,:),im(2,:),'unbiased');
        [a,b] = max(xc);
    end
    if j > maxframes
        return;
    end
end