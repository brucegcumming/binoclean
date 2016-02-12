function [bim, left, right] = rds(sz, dxy,ndots, varargin)
 %[bim, left, right] = rds(sz, dxy,ndots, varargin)
 %build an RDS.  sz is in pixels. 
 %dxy is horiztonalal and vertical disp in pxiels
 %'noise',[b w], adds gaussain nose with SD w to white dots, sd b to black
 %dots
 %Writes reslt to ./Images/rds001L.pgm
 %e.g. stim.rds([256 256],[0 0],200,'noise',[1 0]); for the new
 %Harris/Parker thing

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
rnd = 10 + ceil(rand(ndots,2) .* (w-26));
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

bim = left+right;
imwrite(left,'Images/rds001L.pgm','pgm');
imwrite(right,'Images/rds001R.pgm','pgm');

function [left, right] = splitrds(sz, dxy,ndots, varargin)
