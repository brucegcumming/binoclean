function E = ACRC(varargin)
% Call stim.BuildExpt to Make New ACRC 1D nosie experient
% ACRC('dps',[-0.5651:0.094184:0.56511],'puncorr',0.1,'pblank',0.02,'nframes',300);
%typical for lem.
%default is to mix in 2 contrast values, for each eye.
% (...,'freqs',[1 1 1 2 3 4 5 6 7 8]) makes condition 1 presented 3x as
% often and the others

name = 'ACRC';
type = 'normal';
basedir = '';
expts = {'dp' 'ce' 'Fr' 'cL' 'cR' 'sl'};
values{1} = -0.4:0.05:0.4;
verbose = 0;
%For values > 1, where subspace is set
%user specifies combinations of
%conditions used for each case of values{1}
%here 2,4 and % (correlation, contrast left, contrast right
%values(2,4,5) all are the same length, so that 
% values{2}(1) values{4}(1) values{5}(1)
% specfies one stimulus combinatino that will be used
values{2} = [-1 -1 -1 -1 1 1 1 1];
values{3} = [1 3];
values{4} = [1 1.0 0.2 0.2 1 1.0 0.2 0.2];
values{5} = [1 0.2 1.0 0.2 1 0.2 1.0 0.2];
%frequenices is a misnomer. But this sets how often each combination is
%used, by setting a repeat rate. i.e values{i}(1) and (5) are shown three
%times as oftern as the others.
frequencies{2} = [1 1 1 2 3 4 5 5 5 6 7 8]; 

values{6} = [0 3];
subspace = [1 1 0 1 1 0];
Expt.puncorr = 0.1;
Expt.pblank = 0.02;
Expt.expttype = 'ACRC1D';
Expt.nframes = 201;
Expt.ntrials = 80;
Expt.nrpt = 1;
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
    elseif strncmp(varargin{j},'dxs',3)
        j = j+1;
        values{1} = varargin{j};
    elseif strncmp(varargin{j},'dps',3)
        j = j+1;
        values{1} = varargin{j};
        expts{1} = 'dp';        
    elseif strncmp(varargin{j},'Frs',3)
        j = j+1;
        values{3} = varargin{j};
    elseif strncmp(varargin{j},'freqs',5)
        j = j+1;
        freqs = varargin{j};
    elseif strncmp(varargin{j},'nrpt',4)
        j = j+1;
        nr = varargin{j};
        Expt.nrpt = nr;
    elseif strncmp(varargin{j},'nframes',4)
        j = j+1;
        Expt.nframes = varargin{j};
    elseif strncmp(varargin{j},'npass',4)
        j = j+1;
        npass = varargin{j};
    elseif strncmp(varargin{j},'ntrials',4)
        j = j+1;
        Expt.ntrials = varargin{j};
    elseif strncmp(varargin{j},'puncorr',4)
        j = j+1;
        Expt.puncorr = varargin{j};
    elseif strncmp(varargin{j},'pblank',4)
        j = j+1;
        Expt.pblank = varargin{j};
    elseif strncmp(varargin{j},'speed',4)
        j = j+1;
        speed = varargin{j};
    elseif strncmp(varargin{j},'sls',3)
        j = j+1;
        values{6} = varargin{j};
    elseif strncmp(varargin{j},'test',4)
        j = j+1;
        teststim = varargin{j};
    elseif strncmp(varargin{j},'type',4)
        j = j+1;
        type = varargin{j};
    elseif strncmp(varargin{j},'verbose',4)
        verbose = 1;
    end
    j = j+1;
end
if isempty(basedir)
    basedir = ['/local/expts/' name];
end
Expt.stimdir = basedir;


%size(values,1) must match length stimvarver
if strcmp(type,'nocontrast')
    values{1} = -0.4:0.05:0.4;
    values{2} = [-1 1 -1 1];
    values{3} = [1 1 3 3];
    values{4} = [0 3];
    expts = {'dp' 'ce' 'Fr' 'sl'};
    subspace = [1 1 0 0];
elseif strcmp(type,'fixed')
    values{2} = [-1 1];
    expts = {'dp' 'ce'};
    values = values(1:2);
    subspace = [0 0 0 0];
    Expt.expttype = 'AC1D';
end
Expt.values = values;
%If length(Frs)  >2, then only apply changes in contrast to the longest Fr
%case
if length(values{3}) > 2
    allvalues = values;
    values{3} = values{3}(1:2);
    values{6} = values{6}(1:2);
    values{4} = ones(size(values{3}));
    subspace(4) = 0;
    values{5} = ones(size(values{3}));
    subspace(5) = 0;
    [Ea, AllS] = stim.BuildExpt(expts, values, Expt, 'subspace',subspace,'freqs',frequencies,'nseeds',10000,'show','se');
    Ea.S = AllS;
    values{3} = allvalues{3}(3:end);
    values{6} = allvalues{6}(3:end);
    values{4} = allvalues{4}; %Have contrast changes in the long Fr case
    subspace(4) = 1;
    values{5} = allvalues{5}; %Have contrast changes in the long Fr case
    subspace(5) = 1;
    [E, AllS] = stim.BuildExpt(expts, values, Ea, 'subspace',subspace,'freqs',frequencies,'nseeds',10000,'show','se');
    E.S = AllS;
else
    [E, AllS] = stim.BuildExpt(expts, values, Expt, 'subspace',subspace,'freqs',frequencies,'nseeds',10000,'show','se');
end

%if mixinf Fr and cL, we don't want contrast variation in the Fr==1 case
if isfield(AllS,'Fr') && isfield(AllS,'cL')
    id = find([AllS.Fr] ==1);
    for j = 1:length(id)
        AllS(id(j)).cL = ones(size(AllS(id(j)).cL));
        AllS(id(j)).cR = ones(size(AllS(id(j)).cR));
    end
end
E.S = AllS;
if verbose
    stim.Print(E.S);
end

return;

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
fprintf('%d stim * %d repeats = %d trials (%d stim)\n',ns,nr,ceil(ns * nr/pt),length(stimorder));


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
    if sum(strcmp(f{j},{'st' 'op'})); %char fields
        fprintf(fid,'%s=%s\n',f{j},x);
    else
        fprintf(fid,'%s=%.2f\n',f{j},x);
    end
end
exstr = sprintf(' %.2f',exvals);

fprintf(fid,'manexpvals%d%s\n',stimno,exstr);
fclose(fid);

