function HumanACadapt(varargin)

p = 1;
dx = [0.1 -0.1];
ceval = -1;
testuc = 1;

j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'ce',2)
        j = j+1;
       ceval = varargin{j};
    elseif strncmpi(varargin{j},'disp',3)
        j = j+1;
       dx = varargin{j};
    elseif strncmpi(varargin{j},'prob',3)
        j = j+1;
        p = varargin{j};
    end
    j = j+1;
end

nf=600;
c = rand(nf,1);

preframes = 400;
dxs = zeros(2,nf);

if p == 1 %adaptor then UC for aftereffect
    ces = zeros(2,nf);
    ces(1,1:preframes) = ceval;
    ces(2,1:preframes) = ceval;
    dxs(1,1:preframes) = dx(1);
    dxs(2,2:preframes) = dx(2);
else
    ces = zeros(2,nf);
    rnd = rand(2,nf);
    ces(rnd <p) = ceval;
end

fid = fopen('/local/expts/ACadapt/stim0','w');

if testuc
fprintf(fid,'dx=%.2f\nbd=%.2f\n',dx);
fprintf(fid,'ce:%s\n',sprintf(' %.1f',ces(1,:)));
fprintf(fid,'cb:%s\n',sprintf(' %.1f',ces(2,:)));
else
fprintf(fid,'dx=%.2f\nbd=%.2f\nce=1\ncb=1\n',dx);
fprintf(fid,'dx:%s\n',sprintf(' %.2f',dxs(1,:)));
fprintf(fid,'bd:%s\n',sprintf(' %.2f',dxs(2,:)));
end
fclose(fid);

