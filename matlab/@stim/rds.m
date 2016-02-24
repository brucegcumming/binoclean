function [bim, left, right] = rds(sz, dxy,ndots, varargin)
%[bim, left, right] = rds(sz, dxy,ndots, varargin)
 %build an RDS.  sz is in pixels. 
 %dxy is horiztonalal and vertical disp in pxiels
 %'noise',[b w], adds gaussain nose with SD w to white dots, sd b to black dots
 %e.g. stim.rds([256 256],[0 0],200,'noise',[1 0]); for the new Harris/Parker thing
 %
 %... 'noise', [w b], 'pnoise' 0.5, uses sd 'w' with p o f0.5, else uses sd
 %'b' but applies these regardless of dot color
% Writes result to ./Images/rds001L.pgm or PREFIXL.pgm if set with
% rds(...,'prefix', PREFIX)
 
prefix = 'Images/rds001';

j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'noise',5)
        j = j+1;
        noisesd = varargin{j};
    elseif strncmpi(varargin{j},'prefix',5)
        j = j+1;
        prefix = varargin{j};
    end
    j = j+1;
end

strs = cell2cellstr(varargin);
if sum(strcmp('step',strs))
  [left, right] = steprds(sz, dxy,ndots, varargin{:});
else
  [left, right] = squarerds(sz, dxy,ndots, varargin{:});
end

bim = left+right;
imwrite(left,[prefix 'L.pgm'],'pgm');
imwrite(right,[prefix 'R.pgm'],'pgm');

    
function [left, right] = squarerds(sz, dxy,ndots, varargin)
 
left = zeros(sz)+0.5;
right = zeros(sz)+0.5;
dw = 6;
pnoise = 0;
noisesd = [4 0];
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'noise',5)
        j = j+1;
        noisesd = varargin{j};
    elseif strncmpi(varargin{j},'pnoise',5)
        j = j+1;
        pnoise = varargin{j};
    end
    j = j+1;
end
w = sz(1);
h = sz(2);
dx = dxy(1);
dy = dxy(2);

box = round([w/6 5*w/6 h/6 5*h/6]);
rnd = dw + ceil(rand(ndots,2) .* (w-2*dw));
color = round(rand(1,ndots));
noise = round(randn(1,ndots));

if pnoise > 0
    noisetype = round(rand(1,ndots));
else
    noisetype = color;
end
noise(noisetype == 0) = noise(noisetype == 0) .* noisesd(1);
noise(noisetype == 1) = noise(noisetype == 1) .* noisesd(2);
    
%ind2sub might speed this up....
sw = diff(box(1:2));
sh = diff(box(3:4));
for j = 1:ndots    
    x = rnd(j,1);
    y = rnd(j,2);
    left(y:y+dw,x:x+dw) = color(j);
    dx = dxy(1) + noise(j);
%add disparity to dots in center    
    if(abs(x- w/2) < sw/2 & abs(y - h/2) < sh/2)
        if x+dx > box(2)
            right(y+dy:y+dw+dy,[x+dx:x+dw+dx]-sw) = color(j);
        else
            right(y+dy:y+dw+dy,x+dx:x+dw+dx) = color(j);
        end
    else
        right(y+dy:y+dw+dy,x:x+dw) =  color(j);
    end
end


function [left, right] = steprds(sz, dxy,ndots, varargin)
left = zeros(sz)+0.5;
right = zeros(sz)+0.5;
dw = 6;
pnoise = 0;
noisesd = [4 0];
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'noise',5)
        j = j+1;
        noisesd = varargin{j};
    elseif strncmpi(varargin{j},'pnoise',5)
        j = j+1;
        pnoise = varargin{j};
    end
    j = j+1;
end
w = sz(1);
h = sz(2);
dx = dxy(1);
dy = dxy(2);

box = round([w/6 5*w/6 h/6 5*h/6]);
rnd = dw + ceil(rand(ndots,2) .* (w-2*dw));
color = round(rand(1,ndots));
noise = round(randn(1,ndots));

if pnoise > 0
    noisetype = round(rand(1,ndots));
else
    noisetype = color;
end
noise(noisetype == 0) = noise(noisetype == 0) .* noisesd(1);
noise(noisetype == 1) = noise(noisetype == 1) .* noisesd(2);
    
%ind2sub might speed this up....
sw = diff(box(1:2));
sh = diff(box(3:4));
iw = w - 2 * dw;
for j = 1:ndots    
    x = rnd(j,1);
    y = rnd(j,2);
    left(y:y+dw,x:x+dw) = color(j);
    dx = dxy(1) + noise(j);
%add disparity to dots in center    
    if y > h/2
        dx = dxy(1) + noise(j);
    else
        dx = -dxy(1) + noise(j);
    end
    if x+dx > w-dw
        right(y+dy:y+dw+dy,[x+dx:x+dw+dx]-iw) = color(j);
    elseif x+dx < dw
        right(y+dy:y+dw+dy,[x+dx:x+dw+dx]+iw) = color(j);
    else
        right(y+dy:y+dw+dy,x+dx:x+dw+dx) = color(j);
    end
end
