function matexp = PlaidExpts(name, varargin)
%RLSExpts(name,...)
%Builds Expts for Plaid
%PlaidExpts('dir') varies dir and c2. (= components and pattern)
%...,'nrpt',n) set # of repeats (otherwise aims for ~80 trials)

basedir = ['/local/expts/Plaid' name];
stimw = 4;
liststim = 1;
nr = 0;
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
    elseif strncmp(varargin{j},'size',4)
        j = j+1;
        stimw = varargin{j};
    elseif strncmp(varargin{j},'nrpt',4)
        j = j+1;
        nr = varargin{j};
    end
    j = j+1;
end
matexp.stimdir = basedir;


values(1,:) = [0 45 -45 90 0 45 -45 90 0 45 -45 90 0];
values(2,:) =[0 0   0   0  0 0  0  0  0 0 0 0 360];
values(3,:)= [90 90  90   90  0 0  0  0   0 0 0 0 0];
values(4,:)= [1 1  1   1  1 1  1  1   0.5 0.5 0.5 0.5 1];
stimvars = {'or' 'nph' 'a2' 'co'};
exid = [1 2 3];

ns = 0;
for j = 1:size(values,2)
    ns = ns+1;
    for k = 1:length(stimvars)
        AllS(ns).(stimvars{k}) = values(k,j);
    end
    exvals(ns,:) = values(exid,j);
end

if ~exist(basedir)
    fprintf('Creating Directory %s\n',basedir);
    mkdir(basedir);
end

for j = 1:ns
    matexp.labels{j} = WriteStim(basedir, j-1, AllS(j),exvals(j,:));
    if liststim
        fprintf('%s\n',matexp.labels{j});
    end
end

if (nr ==0)  %set nr automatically to get ~ 80 trials
nr = round(80./ns);
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
fprintf('%d stim * %d repeats\n',ns,nr);
matexp.AllS = AllS;

function s = WriteStim(basedir, stimno, S, exvals)

stimname = sprintf('%s/stim%d',basedir,stimno);
fid = fopen(stimname,'w');
f = fields(S);
exstr = [];
s = [];
for j = 1:length(f)
    x = S.(f{j});
    
    if sum(strmatch(f{j},{'st'})); %char fields
        str = sprintf('%s=%s',f{j},x);
    else
        str = sprintf('%s=%.2f',f{j},x);
    end
    fprintf(fid,'%s\n',str);
    s = [s str ' '];
end
exstr = sprintf(' %.2f',exvals);
fprintf(fid,'manexpvals%d%s\n',stimno,exstr);

fclose(fid);

