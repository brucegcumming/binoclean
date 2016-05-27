function [Expt, AllS] = BuildExpt(expts, values, varargin)
%Expt = stim.BuildExpt(expts, values, varargin) Set up a manual experiment that uses images build
%by matlab
%...,'npass') sets the number of times each image is shown
%...,'nrpt')  set the number of equivalent images (same parameters) that
%are built;
%
name = 'MatExpt';
Expt.stimdir = '';
nr = 0;
pt = 1;
nrpt = 5;
speed = 10;
npass = 2;
teststim = [];
dxs = [-2 2];
noises = [5 10 15];
sz = [256 256];
nim = 5;
ndots = 200;
nframes = 200;
noiseratio = 0;
saveexptfile = 0;
subspace = zeros(size(expts));
prefix = '/local/Images/rds/'; %where images are writte
args = {'step'};
ntrials = 0;
Expt.nframes = 0;
showvars = {};
frequencies = {};
j = 1;
while j <= length(varargin)
    if isstruct(varargin{j}) && isfield(varargin{j},'expttype')
        Expt = CopyFields(Expt,varargin{j});
    elseif strncmp(varargin{j},'basedir',6)
        j = j+1;
        Expt.stimdir = varargin{j};
    elseif strncmp(varargin{j},'expts',5)
        j = j+1;
        expts = varargin{j};
    elseif strncmp(varargin{j},'values',5)
        j = j+1;
        values = varargin{j};
    elseif strncmp(varargin{j},'freqs',5)
        j = j+1;
        frequencies = varargin{j};
    elseif strncmp(varargin{j},'dx',2)
        j = j+1;
        dxs = varargin{j};
    elseif strncmp(varargin{j},'ndots',4)
        j = j+1;
        ndots = varargin{j};
    elseif strncmp(varargin{j},'nrpt',4)
        j = j+1;
        nr = varargin{j};
    elseif strncmp(varargin{j},'npass',4)
        j = j+1;
        npass = varargin{j};
    elseif strncmp(varargin{j},'nframes',5)
        j = j+1;
        Expt.nframes = varargin{j};
    elseif strncmp(varargin{j},'ntrials',4)
        j = j+1;
        Expt.ntrials = varargin{j};
    elseif strncmp(varargin{j},'nseeds',4)
        j = j+1;
        Expt.nseeds = varargin{j};
    elseif strncmp(varargin{j},'ratio',5)
        j = j+1;
        noiseratio = varargin{j};
    elseif strncmp(varargin{j},'noisesds',7)
        j = j+1;
        noises = varargin{j};
    elseif strncmp(varargin{j},'pblank',4)
        j = j+1;
        Expt.pblank = varargin{j};
    elseif strncmp(varargin{j},'puncorr',4)
        j = j+1;
        Expt.puncorr = varargin{j};
    elseif strncmp(varargin{j},'subspace',7)
        j = j+1;
        subspace = varargin{j};
    elseif strncmp(varargin{j},'show',4)
        j = j+1;
        showvars = {showvars{:} varargin{j}};
    elseif strncmp(varargin{j},'speed',4)
        j = j+1;
        speed = varargin{j};
    elseif strncmp(varargin{j},'test',4)
        j = j+1;
        teststim = varargin{j};
    elseif strncmp(varargin{j},'type',4)
        j = j+1;
        type = varargin{j};
        basedir = ['/local/expts/' type];
    end
    j = j+1;
end

if isempty(Expt.stimdir)
    Expt.stimdir = ['/local/expts/' name]; %where stim files are written
end

%Get Pixel scaling
Monitor = binoc.GetMonitor;
if ~isempty(Monitor)
    args = {args{:} 'Monitor' Monitor};
end
stimvars = expts;
a = stimvars{1};
b = stimvars{2};
ns = 0;

Expt.npass = npass;

if subspace(1) && subspace(2)
    AllS = MakeSubSpace(expts, values, subspace, frequencies, Expt);
    ns = length(AllS);
else
    for j = 1:length(values{1})
        for k = 1:length(values{2})
            ns = ns+1;
            AllS(ns).(a) = values{1}(j);
            AllS(ns).(b) = values{2}(k);
            for c = 3:length(values)
                if iscellstr(values{c})
                    AllS(ns).(stimvars{c}) = values{c}{k};
                else
                    AllS(ns).(stimvars{c}) = values{c}(k);
                end
            end
        end
        exvals(ns,1) = values{1}(j);
        exvals(ns,2) = values{2}(k);
    end
end
for j = 1:length(AllS)
    stim.WriteStim(Expt.stimdir, j-1, AllS(j), {stimvars{:} showvars{:}});
end

Expt.imagedir = prefix;
Expt.stimorder = stim.SetOrder([0:ns-1],npass);
Expt.expts = expts;

Expt.version = str2num(ObjectVersion(stim));
Expt.expname = name;

if saveexptfile
    d = dir([Expt.stimdir '/Expt*.mat']);
    if isempty(d)
        Expt.exptid =1;
    else
        Expt.exptid = 1+max(GetExptNumber({d.name}));
    end
    Expt.filename = sprintf('%s/Expt%d.mat',Expt.stimdir,Expt.exptid);
    save(Expt.filename,'Expt');
end
stim.WriteOrder(Expt.stimdir, Expt.stimorder, expts, Expt);
fprintf('%d Trials (%d stim, %d pass)\n',length(Expt.stimorder),ns,Expt.npass);


function AllS = MakeSubSpace(expts, values, subspace, frequencies, Expt)

frid = find(strcmp('Fr',expts));
for j = 1:length(values)
    nvalues(j) = length(values{j});
end
ntypes(subspace >0) = 1;
ntypes(subspace == 0) = nvalues(subspace==0);
trialtypes = unique(nvalues(subspace==0));
ntrialtypes = trialtypes(1);
stimvars = expts;
ea = expts{1};
eb = expts{2};
ns = 0;
nstim = round(Expt.ntrials./(Expt.npass .* trialtypes));
n = ceil(nstim.*ntrialtypes); %number of different stims
seeds = ceil(rand(1,n) .*  Expt.nseeds .* Expt.nframes);
pextra = 0;
xp= [0 0 0]; %probabilities for extra interleaves
xval = [0 0 0];
xi = 0;
if isfield(Expt,'puncorr')
    xi = xi+1;
    pextra = pextra + Expt.puncorr;
    xp(xi) = Expt.puncorr;
    xval(xi) = stim.IUNCORR;
end
if isfield(Expt,'pblank')
    xi = xi+1;
    pextra = pextra + Expt.pblank;
    xp(xi) = Expt.puncorr;
    xval(xi) = stim.IBLANK;
end
p = 1+pextra;
for j = 1:ntrialtypes
    for k = 1:nstim

    ns = ns+1;
    if ~isempty(frid)
        Fr = values{frid}(j);
        AllS(ns).Fr = Fr;
    else
        Fr = 1;
    end
    if subspace(1)
        nf = ceil(round(Expt.nframes./max([subspace(1) Fr])));
        rnd = rand(1,nf).*p;
        xid = ceil(rnd.*length(values{1}));
        xid(xid > length(values{1})) = 1;
        AllS(ns).(ea) = values{1}(xid);
        for k = xi:-1:1
            xids{k} = find(rnd > 1 & rnd <= 1+sum(xp(1:k)));
            AllS(ns).(ea)(xids{k}) = xval(k);
        end
        if Fr > 1
            AllS(ns).(ea) = RepeatFrames(AllS(ns).(ea), Fr);
        end
    else
        AllS(ns).(ea) = values{1}(j);
    end
    if subspace(2)
        nf = ceil(round(Expt.nframes./max([subspace(2) Fr])));
        if length(frequencies) > 1 && ~isempty(frequencies{2})
            a = ceil(rand(1,nf).*length(frequencies{2}));
            xid = replace(a,1:length(frequencies{2}),frequencies{2});
        else
            xid = ceil(rand(1,nf).*length(values{2}));
        end
        AllS(ns).(eb) = values{2}(xid);
        for k = 1:length(xids)
            if xval(k) == stim.IUNCORR && strcmp(eb,'ce')
                AllS(ns).ce(xids{k}) = 0;
            end
        end
        if Fr > 1
            AllS(ns).(eb) = RepeatFrames(AllS(ns).(eb), Fr);
        end
    else
        AllS(ns).(eb) = values{2}(j);
    end
    for c = 3:length(values)
        ec = stimvars{c};
        if iscellstr(values{c})
            AllS(ns).(stimvars{c}) = values{c}{j};
        elseif subspace(c)
                nf = ceil(round(Expt.nframes./max([subspace(c) Fr])));
            if subspace(2) && ~isempty(frequencies) %xid set above
            else
                xid = ceil(rand(1,nf).*length(values{c}));
            end
            AllS(ns).(stimvars{c}) = values{c}(xid);
            if Fr > 1
                AllS(ns).(ec) = RepeatFrames(AllS(ns).(ec), Fr);
            end
        else
            AllS(ns).(stimvars{c}) = values{c}(j);
        end
    end
    exvals(ns,1) = values{1}(j);
    AllS(ns).se = seeds(ns);
    end
end
Expt.nstims = ns;

function Y = RepeatFrames(X, Fr)
Y = interp1(1:length(X),X,[1:1./Fr:length(X)+1],'previous',X(end));
Y = Y(1:end-1);

