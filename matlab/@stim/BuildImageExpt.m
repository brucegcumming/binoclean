function Expt = BuildImageExpt(type, varargin)
%Expt = stim.BuildExpt(type, varargin) Set up a manual experiment that uses images build
%by matlab
%BuildExpt('StereoAcuity') Builds RDS with disparity. Illustrates simple use
%BuildExpt('HarrisParker') Builds RDS with noise added differntly to white and black dots
%
%...,'npass') sets the number of times each image is shown
%...,'nrpt')  set the number of equivalent images (same parameters) that
%are built;
%
name = 'MatExpt';
basedir = ['/local/expts/' type]; %where stim files are written
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
noiseratio = 0;
saveexptfile = 0;

prefix = '/local/Images/rds/'; %where images are writte
args = {'step'};
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
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
    elseif strncmp(varargin{j},'ratio',5)
        j = j+1;
        noiseratio = varargin{j};
    elseif strncmp(varargin{j},'noisesds',7)
        j = j+1;
        noises = varargin{j};
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

%Get Pixel scaling
Monitor = binoc.GetMonitor;
if ~isempty(Monitor)
    args = {args{:} 'Monitor' Monitor};
end

noisetypes = 'bwgg';
if strcmp(type,'StereoAcuity')  %simple RDS Front/back Task
%Don't put dx in these stim files. That woudl cause binoc to apply translation
% to hte L,R images supplied.  Use a non-binoc label to describe what has
% happened in the image
    expvars = {'stepdx'}; %not binoc codes
    imi = 0;
    for j = 1:length(dxs)
        exvals(1) = dxs(j);
        S.stepdx  = dxs(j);
%Build an image on disk with this RDS.        
        R = stim.rds(sz, [dxs(j) 0], ndots, 'prefix',sprintf('%s/rds%03d',prefix,imi),'step','Monitor',Monitor);
        S.imi = imi;
%psyv is a binoc code for the value to be used for psychometric curves
% here, just the disparity
        S.psyv = dxs(j);
        S = CopyFields(S, R, {'dd' 'truedd' 'dw' 'wi' 'hi' });        
%write the stim file that makes binoc display this image        
        stim.WriteStim(basedir, imi, S, expvars,'ignore','truedd');
        imi = imi+1;
%Put stimulus descripitons in return struct.  Verg will see these when !mat
%is executed
        Expt.S(imi) = S; 
    end
elseif strcmp(type,'HarrisParker')
    saveexptfile = 1;
    expvars = {'stepdx' 'noise' 'pnoise'}; %not binoc codes
    S.imve = ObjectVersion(stim);
    imi = 0;
    name = 'HarrisParker';
    for j = 1:length(dxs)
        exvals(1) = dxs(j);
        S.stepdx  = dxs(j);
        for k = 1:length(noises)
            exvals(2) = noises(k);
            bnoise = noises(k).* noiseratio;
            for n = 1:length(noisetypes);
            for r = 1:nrpt
                if noisetypes(n) == 'w'
                    R = stim.rds(sz, [dxs(j) 0], ndots, 'noise',[noises(k) bnoise],'prefix',sprintf('%s/rds%03d',prefix,imi),args{:});
                    S.pnoise = 1;
                elseif noisetypes(n) == 'b'
                    R = stim.rds(sz, [dxs(j) 0], ndots, 'noise', [bnoise noises(k)],'prefix',sprintf('%s/rds%03d',prefix,imi),args{:});
                    S.pnoise = 0;
                elseif noisetypes(n) == 'g'
                    R = stim.rds(sz, [dxs(j) 0], ndots, 'noise', [noises(k) bnoise],'pnoise',0.5,'prefix',sprintf('%s/rds%03d',prefix,imi),args{:});                    
                    S.pnoise = 0.5;
                elseif noisetypes(n) == 'x'
                    R = stim.rds(sz, [dxs(j) 0], ndots, 'noise', [noises(k) noises(k)],'prefix',sprintf('%s/rds%03d',prefix,imi),args{:});                    
                    S.pnoise = 0.5;
                end                    
                S.imi = imi;
                if noises > 0
                    S.psyv = sign(dxs(j)) .* 1./noises(k);
                else
                    S.psyv = 1;
                end
                S.noise  = noises(k);
                S.bnoise = bnoise;
                S = CopyFields(S, R, {'se' 'dd' 'truedd' 'dw' 'wi' 'hi' 'x' 'y' 'dx'});
                stim.WriteStim(basedir, imi, S, expvars,'show',{'psyv', 'bnoise'},'ignore',{'x' 'y' 'dx'});
                imi = imi+1;
                Expt.S(imi) = S;                
            end
            end
        end
    end           
end
Expt.stimdir = basedir;
Expt.imagedir = prefix;
Expt.stimorder = stim.SetOrder([0:imi-1],npass);
Expt.expvars = expvars;
Expt.version = str2num(ObjectVersion(stim));
Expt.expname = name;
Expt.types{2} = 'pnoise';
if saveexptfile
    d = dir([basedir '/Expt*.mat']);
    if isempty(d)
        Expt.exptid =1;
    else
        Expt.exptid = 1+max(GetExptNumber({d.name}));
    end
    Expt.filename = sprintf('%s/Expt%d.mat',basedir,Expt.exptid);
    save(Expt.filename,'Expt');
end
stim.WriteOrder(basedir, Expt.stimorder, expvars, Expt);
fprintf('%d Trials\n',length(Expt.stimorder));

