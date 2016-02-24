function Expt = BuildExpt(type, varargin)
%Expt = stim.BuildExpt(type, varargin) Set up a manual experiment that uses images build
%by matlab
%BuildExpt('HarrisParker') Builds RDS with noise added differntly to white and black dots
%
%...,'npass') sets the number of times each image is shown
%...,'nrpt')  set the number of equivalent images (same parameters) that
%are built;
%
name = 'MatExpt';
basedir = ['/local/expts/' type];
nr = 0;
pt = 1;
nrpt = 5;
speed = 10;
npass = 2;
teststim = [];
dxs = [-5 5];
noises = [5 10 15];
sz = [256 256];
nim = 5;
ndots = 200;
prefix = '/local/Images/rds/';
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
    elseif strncmp(varargin{j},'nrpt',4)
        j = j+1;
        nr = varargin{j};
    elseif strncmp(varargin{j},'npass',4)
        j = j+1;
        npass = varargin{j};
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

imi = 0;
noisetypes = 'wbgg';
if strcmp(type,'HarrisParker')
    expvars = {'stepdx' 'noise' 'pnoise'}; %not binoc codes
    for j = 1:length(dxs)
        exvals(1) = dxs(j);
        S.stepdx  = dxs(j);
        for k = 1:length(noises)
            exvals(2) = noises(k);
            for n = 1:length(noisetypes);
            for r = 1:nrpt
                if noisetypes(n) == 'w'
                    stim.rds(sz, [dxs(j) 0], ndots, [noises(k) 0],'prefix',sprintf('%s/rds%03d',prefix,imi));
                    S.pnoise = 1;
                elseif noisetypes(n) == 'b'
                    stim.rds(sz, [dxs(j) 0], ndots, [0 noises(k)],'prefix',sprintf('%s/rds%03d',prefix,imi));
                    S.pnoise = 0;
                elseif noisetypes(n) == 'g'
                    stim.rds(sz, [dxs(j) 0], ndots, [noises(k) 0],'pnoise',0.5,'prefix',sprintf('%s/rds%03d',prefix,imi));                    
                    S.pnoise = 0.5;
                end                    
                S.imi = imi;
                S.psyv = sign(dxs(j)) .* 1./noises(k);
                S.noise  = noises(k);
                stim.WriteStim(basedir, imi, S, expvars);
                imi = imi+1;
                Expt.S(imi) = S;
            end
            end
        end
    end           
end
Expt.stimdir = basedir;
Expt.stimorder = stim.SetOrder([0:imi-1],npass);
Expt.expvars = expvars;
stim.WriteOrder(basedir, Expt.stimorder, expvars, name);


fprintf('%d Trials\n',length(Expt.stimorder));

