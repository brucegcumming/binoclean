function AllS = BinocExpt(varargin)
% Basic Matlab function for generating Binoc Expts

name = 'Test';
basedir = ['/local/expts/' name];
nr = 0;
j = 1;
while j <= length(varargin)
    if strncmp(varargin{j},'basedir',6)
        j = j+1;
        basedir = varargin{j};
    end
    j = j+1;
end


%size(values,1) must match length stimvars
values(1,:)= [1 2 3 1   2   3];
values(2,:) = [1 1 1 0.5 0.5 0.5];
stimvars = {'sf' 'co'};

ns = 0;
for j = 1:size(values,2)
    ns = ns+1;
    for k = 1:length(stimvars)
        AllS(ns).(stimvars{k}) = values(k,j);
    end
    exvals(ns,:) = values(:,j);
end

for j = 1:ns
    WriteStim(basedir, j-1, AllS(j),exvals(j,:));
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

