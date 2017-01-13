function [Expt, AllS] = CylPulse(dxs, pulset, pulsesz, varargin)
%AllS = stim.CylPulse(dxs, pulset, pulsesz)  make cylinder disparity expt
%   with pulses
%Typical: 
%stim.CylPulse([-0.1:0.02:0.1],[30 240], [0.02 -0.02], 'nframes', 240,'nrpt',1)
%if pulset has length 2, then each trial has a random pick from that range.
%   .... 'ors',[90 135]) to set orientation ranges (default -45 0 45 90)
%   ....  'tsd', sigma) sets SD of Guassian time kernel for pulse (frames)
%pulset is the time at which the first element of the kernel is appplie. SO
%it can be in the range 1:nframes - length(kernel);

stimvals{4} = [-45 0 45 90];
tsigma = 5;
skip = [];
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'ors',3)
        j = j+1;
        skip(j:j+1) = 1;
        stimvals{4} = varargin{j};        
    elseif strncmp(varargin{j},'tsd',3)
        j = j+1;
        tsigma = varargin{j};
    end
    j = j+1;
end


if ~isempty(skip)
    varargin = varargin(setdiff(1:length(varargin),find(skip)));
end
vals{1} =dxs;
npulset = length(pulset);
if npulset == 2
    npulset = 1;
end
for o = 1:length(stimvals{4});
for j = 1:npulset
    for k = 1:length(pulsesz)
        ii = sub2ind([length(stimvals{4}) npulset length(pulsesz)],o,j,k);
        vals{2}(ii) = pulset(j);
        vals{3}(ii) = pulsesz(k);
        vals{4}(ii) = stimvals{4}(o);
    end
end
end
stimvars = {'dx' 'pulset' 'pulsesz' 'or'};
[Expt, AllS] = stim.BuildExpt({'dx' 'pulset' 'pulsesz' 'or'}, vals,'basedir','/local/Expts/CylPulse','name','CylPulse','nseeds',1000,varargin{:});

if tsigma > 10
    K = Gauss(tsigma,-20:20);
else
    K = Gauss(tsigma,-20:20);
end

if length(pulset) == 2 %random selection in range puslet(1):pulset(2)
    if pulset(2) > Expt.nframes - length(K)
        pulset(2) = Expt.nframes-length(K);
    end
    n = pulset(2) - pulset(1);
    rndt = pulset(1)+ ceil(rand(length(AllS)) .*n);
    for j = 1:length(AllS)
        AllS(j).pulset = rndt(j);
    end
end
K = K./max(K);
Expt.kernel = K;
for j = 1:length(AllS)
    AllS(j).psyv = AllS(j).dx;
    AllS(j) = SetPulse(Expt,AllS(j),K);
    stim.WriteStim(Expt.stimdir, j-1, AllS(j), stimvars);
end

function S = SetPulse(E, S, K)

dx = S.dx;
K = K .* S.pulsesz;
for j = 1:E.nframes
    S.dx(j) = dx;
end
for t = 1:length(K)
    if t+S.pulset <= E.nframes
        S.dx(t+S.pulset) = S.dx(t+S.pulset) +K(t);
    end
end
