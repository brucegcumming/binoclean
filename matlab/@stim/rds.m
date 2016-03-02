function [bim, left, right] = rds(sz, dxy,ndots, varargin)
%[bim, left, right] = rds(sz, dxy,ndots, varargin)
 %build an RDS.  sz is in pixels. 
 %dxy is horiztonalal and vertical disp in pxiels
 %'noise',[b w], adds gaussain nose with SD w to white dots, sd b to black dots
 %e.g. stim.rds([256 256],[0 0],200,'noise',[1 0],'step'); for the new Harris/Parker thing
 %
 %... 'noise', [w b], 'pnoise' 0.5, uses sd 'w' with p o f0.5, else uses sd
 %'b' but applies these regardless of dot color
% Writes result to ./Images/rds001L.pgm or PREFIXL.pgm if set with
% rds(...,'prefix', PREFIX)
%bim now contains stimulus paramters, not a binocular images
 
prefix = 'Images/rds001';
Monitor.pix2deg = 0.0166;   %default

j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'noise',5)
        j = j+1;
        noisesd = varargin{j};
    elseif strncmpi(varargin{j},'Monitor',5)
        j = j+1;
        Monitor = varargin{j};
    elseif strncmpi(varargin{j},'prefix',5)
        j = j+1;
        prefix = varargin{j};
    end
    j = j+1;
end

strs = cell2cellstr(varargin);
if sum(strcmp('step',strs))
  [left, right, bim] = steprds(sz, dxy,ndots, Monitor, varargin{:});
else
  [left, right] = squarerds(sz, dxy,ndots, varargin{:});
end

%bim = left+right;
%bim.dd = ndots
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


function [left, right, details] = steprds(sz, dxy,ndots, Monitor, varargin)
left = zeros(sz)+0.5;
right = zeros(sz)+0.5;
dw = 7;
pnoise = 0;
noisesd = [4 0];
seed = 0;

j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'noise',5)
        j = j+1;
        noisesd = varargin{j};
    elseif strncmpi(varargin{j},'seed',5)
        j = j+1;
        seed = varargin{j};
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

if seed > 0
    rng(seed);
else
    seed = ceil(rand(1) .* 100000);
end

%x:x+dw is set tto color, which is dw+1 pixels
dw = dw-1;
details.se = seed;
details.dd = ndots .* (dw+1).^2./(w.*h);
details.dw = dw .* Monitor.pix2deg;
details.wi = w.* Monitor.pix2deg;
details.hi = h.* Monitor.pix2deg;

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
iw = w - dw;
for j = 1:ndots    
    x = rnd(j,1);
    y = rnd(j,2);
    left(y:y+dw,x:x+dw) = color(j);
    dx(j) = dxy(1) + noise(j);
%add disparity to dots in center    
    if y > h/2
        dx(j) = dxy(1) + noise(j);
    else
        dx(j) = -dxy(1) + noise(j);
    end
    while x > (w - dw -dx(j))
        x = 1+ x- iw;
    end
    while x+dx(j) < 1
        x = x + iw;
    end
    right(y+dy:y+dw+dy,x+dx(j):x+dw+dx(j)) = color(j);
    if size(right,2) > w
        x = rnd(j,1);        
    end
end
details.truedd = (sum(right(:) ~= 0.5) + sum(left(:) ~= 0.5))./(2.*w.*h);
details.x = rnd(:,1);
details.y = rnd(:,2);
details.dx = dx;