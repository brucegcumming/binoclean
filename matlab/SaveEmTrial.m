function [ch, cv] = SaveEmTrial(Expt, trial, name, varargin)


nframes = 120; %number of frames in replay dispaly

samper = 1./nframes;

id = find(Expt.Header.emtimes > 0);
a = find(Expt.Header.emtimes(id) < Expt.Trials(trial).dur); %
ratio = nframes./a(end);
[a,b] = unique(round([1:length(id)] .* ratio));
smp = id(1) + b -1;

ch = mean(Expt.Trials(trial).EyeData(smp,[1 2]),2);
cv = mean(Expt.Trials(trial).EyeData(smp,[3 4]),2);
fid = fopen(name,'w');
if fid > 0
    fprintf(fid,'emx:=%s\n',sprintf('%.2f ',ch));
    fprintf(fid,'emy:=%s\n',sprintf('%.2f ',cv));
end
 

