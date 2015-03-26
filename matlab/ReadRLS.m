function [result, Images] = ReadRLS(name, varargin)

txt = scanlines(name);
checkdisp = 1;
explore = 0;
maxframes = 0;
showframes = [];

j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'max',3)
        j = 1+1;
        maxframes = varargin{j};
    elseif strncmpi(varargin{j},'show',4)
        j = 1+1;
        showframes = varargin{j};
    end
    j = j+1;
end
idid = find(strncmp('id',txt,2));
mtid = find(strncmp('mtrS',txt,4));
rlsid = setdiff(1:length(txt),union(idid,mtid));
if checkdisp
    corrs = zeros(1,length(rlsid));
    disps = corrs;
end

if ~isempty(showframes)
    rlsid = rlsid(showframes);
end

result.lines = rlsid;
frame = 1;
for j = 1:length(rlsid)
    s = txt{rlsid(j)};
    id = strfind(s,':');
    a = id(1)+1;
    k = 1;
    im = [];
    while a <= length(s)
        x = sscanf(s(a),'%1x');
        if isempty(x) 
            a = length(s)+1;
        else
        im(k,1) = bitand(x,12); %R eye
        im(k,2) = bitand(x,3);
        k = k+1;
        a = id(1)+k;
        end
    end
    
    id = strfind(s,'!dp');
    if ~isempty(id)
        x = sscanf(s(id(1):end),'!dp%f');
        result.dps(j) = x;
    else 
        result.dps(j) = 0;
    end
    
    id = strfind(s,':');
    if strcmp(s(id(1):end),':NaN')
        result.dps(j) = NaN;        
    end
    
    
    id = strfind(s,'U');
    if ~isempty(id)
        result.dps(j) = NaN;
    end
    if ~isempty(im)
    im(:,1) = bitshift(im(:,1),-2);
    if nargout > 1
        Images(:,:,j) = im;
    end

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
        if a < 0.95 && c > -0.95 && ~isnan(result.dps(j));
            imagesc(im');
            cim = im;
            if a > abs(c)
                cim(:,1) = circshift(im(:,1),lags(b));
            else
                result.corrs(j) = c;
                cim(:,1) = circshift(im(:,1),lags(d));
                result.disps(j) = lags(d);
            end
            imagesc(cim');
        elseif a >= 0.95
            result.disps(j) = lags(b);
            result.corrs(j) = a;
        else
            result.disps(j) = lags(d);
            result.corrs(j) = c;
        end
        result.size(j) = size(im,1);
    end
    if explore
        GetFigure('RLS');
        imagesc(im');
        [xc, lags] = xcorr(im(1,:),im(2,:),'unbiased');
        [a,b] = max(xc);
    end
    end
    if j > maxframes && maxframes > 0 
        break;
    end
end


result.badcor =  find(result.disps == -result.dps & abs(result.corrs) < 0.99);
result.baddisp =  find(result.disps ~= -result.dps & ~isnan(result.dps));end
