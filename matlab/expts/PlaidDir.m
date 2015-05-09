function AllS = PlaidDir(varargin)
% Basic Ori tuning for plaid/rls with static or dynamic orthog

name = 'PlaidDir';
basedir = ['/local/expts/' name];
nr = 0;
pt = 4;
nrpt = 0;
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
    elseif strncmp(varargin{j},'nrpt',4)
        j = j+1;
        nr = varargin{j};
    end
    j = j+1;
end


%size(values,1) must match length stimvars
values{1} = [0:30:330];
values{2} = [0 1 1];
stimvars = {'or' 'c2'};

ns = 0;
for j = 1:length(values{1})
    for k = 1:length(values{2})-1
        ns = ns+1;
        AllS(ns).or = values{1}(j);
        AllS(ns).c2 = values{2}(k);
        AllS(ns).sM = 0;
    end
    ns = ns+1;
    AllS(ns).or = values{1}(j);
    AllS(ns).c2 = 1;
    AllS(ns).sM = 33;
    exvals(ns,1) = values{1}(j);
    exvals(ns,2) = values{2}(k);
end

for j = 1:ns
    WriteStim(basedir, j-1, AllS(j),exvals(j,:));
end

if (nr ==0)  %set nr automatically to get ~ 80 trials
nr = round((80 * pt)./ns);
end

stimorder = repmat([1:ns]-1,1,nr);
stimorder = stimorder(randperm(length(stimorder)));
f = fields(AllS);

fid = fopen([basedir '/stimorder'],'w');
fprintf(fid,'expvars %s',f{1});
for j = 2:length(f)
    fprintf(fid,',%s',f{j});
end
fprintf(fid,'\n');
fprintf(fid,'expname=%s\n',name);    
fprintf(fid,'%s\n',sprintf('%d ',stimorder));
fclose(fid);
fprintf('%d stim * %d repeats = %d trials\n',ns,nr,ceil(ns * nr/pt));


function WriteStim(basedir, stimno, S, exvals)

stimname = sprintf('%s/stim%d',basedir,stimno);
fid = fopen(stimname,'w');
f = fields(S);
exstr = [];
for j = 1:length(f)
    x = S.(f{j});
    if sum(strmatch(f{j},{'st'})); %char fields
        fprintf(fid,'%s=%s',f{j},x);
    else
        fprintf(fid,'%s=%.2f\n',f{j},x);
    end
end
exstr = sprintf(' %.2f',exvals);

fprintf(fid,'manexpvals%d%s\n',stimno,exstr);
fclose(fid);

