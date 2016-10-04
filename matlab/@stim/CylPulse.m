function [Expt, AllS] = CylPulse(dxs, pulset, pulsesz, varargin)
%AllS = stim.CylPulse(dxs, pulset, pulsesz)  make cylinder disparity expt
%   with pulses 

vals{1} =dxs;
for j = 1:length(pulset)
    for k = 1:length(pulsesz)
        ii = (j-1) *length(pulsesz) + k;
        vals{2}(ii) = pulset(j);
        vals{3}(ii) = pulsesz(k);
    end
end
stimvars = {'dx' 'pulset' 'pulsesz'};
[Expt, AllS] = stim.BuildExpt({'dx' 'pulset' 'pulsesz'}, vals,'basedir','/local/Expts/CylPulse','name','CylPulse','nseeds',1000,varargin{:});

if length(pulset) == 2 %random selection in range puslet(1):pulset(2)
    n = pulset(2) - pulset(1);
    rndt = pulset(1)+ ceil(rand(length(AllS)) .*n);
    for j = 1:length(AllS)
        AllS(j).pulset = rndt(j);
    end
end
K = Gauss(5,-20:20);
K = K./max(K);
for j = 1:length(AllS)
    AllS(j).psyv = AllS(j).dx;
    AllS(j) = SetPulse(Expt,AllS(j),K);
    stim.WriteStim(Expt.stimdir, j, AllS(j), stimvars);
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
