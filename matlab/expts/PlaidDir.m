function AllS = PlaidDir(varargin)
% Basic Ori tuning for plaid/rls with static or dynamic orthog

name = 'PlaidDir';
basedir = ['/local/expts/' name];
type = 'unikinetic';
nr = 0;
pt = 4;
nrpt = 0;
speed = 10;
npass = 2;

j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
    elseif strncmp(varargin{j},'nrpt',4)
        j = j+1;
        nr = varargin{j};
    elseif strncmp(varargin{j},'speed',4)
        j = j+1;
        speed = varargin{j};
    elseif strncmp(varargin{j},'type',4)
        j = j+1;
        type = varargin{j};
    end
    j = j+1;
end


%size(values,1) must match length stimvarver
if strcmp(type,'unikinetic')
    values{1} = [0:30:330];
    values{2} = [0 1  1 1];
    values{3} = [90 90 45 -45];
    stimvars = {'or' 'c2' 'a2'};
elseif strcmp(type, 'fullunikinetic') %include RDS, dynamic unikinetic, and dynamic rls
%1 SG
%2 UP90
%3 UP45
%4 UP-45
%5 FP45
%6 FP-45
%7 Dynamic SG
%8 FP90
%9 RDS
%9 TypeI Plaid 120
    values{1} = [0:30:330];
    values{2} = [0 1    1  1   1   1 0 1  0 1];
    values{3} = [90 90 45 -45 45 -45 90 90 0 120];
    values{5} = [0   0  0  0  Inf  Inf 0 Inf 0 speed];
    values{6} = [1   1  1  1   1   1 0 1  1 1];
    values{4} = {'rls' 'rls' 'rls' 'rls' 'rls' 'rls' 'rls' 'rls' 'rds' 'rls'}'
    stimvars = {'or' 'c2' 'a2' 'st' 'v2' 'sl'};

else
    values{1} = [0:30:330];
    values{2} = [0 1];
    stimvars = {'or' 'c2'};
end

ns = 0;
for j = 1:length(values{1})
    for k = 1:length(values{2})
        ns = ns+1;
        AllS(ns).sM = 0;
        AllS(ns).or = values{1}(j);
        AllS(ns).c2 = values{2}(k);
        for c = 3:length(values)
            if iscellstr(values{c})
                AllS(ns).(stimvars{c}) = values{c}{k};
            else
                AllS(ns).(stimvars{c}) = values{c}(k);
            end
        end
    end
    if ~strcmp(type,'fullunikinetic')
        ns = ns+1;
        AllS(ns).or = values{1}(j);
        AllS(ns).c2 = 1;
        AllS(ns).sM = 33;
        for c = 3:length(values)
            AllS(ns).(stimvars{c}) = values{c}(1);
        end
    end
    exvals(ns,1) = values{1}(j);
    exvals(ns,2) = values{2}(k);
end

ses = 1000+ round(rand(1,length(AllS)).*10000);
for j = 1:length(AllS)
    AllS(j).se = ses(j);
end
for j = 1:npass
    AllS(1 + ns*(j-1):ns*j) = AllS(1:ns);
    exvals(1 + ns*(j-1):ns*j,:) = exvals(1:ns,:);    
end
ns = length(AllS);
for j = 1:ns
    WriteStim(basedir, j-1, AllS(j),exvals(j,:));
end

if (nr ==0)  %set nr automatically to get ~ 80 trials
nr = round((80 * pt)./ns);
end

stimorder = repmat([1:ns]-1,1,nr);
stimorder = stimorder(randperm(length(stimorder)));
teststim = 109;
if ~isempty(teststim)
    stimorder(1:end) = teststim;
end

f = fields(AllS);
if strcmp(type,'fullunikinetic')
    f = setdiff(f,'sM'); %now
end

fid = fopen([basedir '/stimorder'],'w');
fprintf(fid,'expvars=%s',f{1});
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

%print st first - it affects later codes
exstr = [];
if isfield(S,'st') && ischar(S.st)
    fprintf(fid,'st=%s\n',S.st);
    f = setdiff(f,'st');
end

for j = 1:length(f)
    x = S.(f{j});
    if sum(strmatch(f{j},{'st'})); %char fields
        fprintf(fid,'%s=%s\n',f{j},x);
    else
        fprintf(fid,'%s=%.2f\n',f{j},x);
    end
end
exstr = sprintf(' %.2f',exvals);

fprintf(fid,'manexpvals%d%s\n',stimno,exstr);
fclose(fid);

