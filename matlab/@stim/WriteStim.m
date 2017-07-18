function WriteStim(basedir, stimno, S, exf,varargin)
%stim.WriteStim(basedir, stimno, S, exvals)
%Creates a stimN file for controlling binoc expts in basedir
%each field in S, is written into the file
%if exvals is given, it lists fields that matter for subsequent plotting
%recorded in each stim file with manexpvals
%
%stim.WriteStim(basedir, AllS) where AllS is a struct length > 1
%    writes all teh stim files


if isstruct(stimno)
    AllS = stimno;
    for j = 1:length(AllS)
        stim.WriteStim(basedir,j-1,AllS(j));
    end
    return;
end
if nargin < 4
    exf = {};
end

if isempty(exf)
    exf = fields(S);
end
stimname = sprintf('%s/stim%d',basedir,stimno);
fid = fopen(stimname,'w');
if fid < 0
    cprintf('red','Cannot Write to file %s\n',stimname);
    return;
end
f = fields(S);
if isfield(S,'psyv')
    forcef = {'psyv'};  %codes to send to string description in binoc
else
    forcef = {};
end
j = 1;
while j <= length(varargin)
    if strcmp(varargin{j},'ignore') %list of fields NOT to write
        j = j+1;
        f = setdiff(f,varargin{j});
    elseif strcmp(varargin{j},'show') %fields to show in binoc
        j = j+1;
        forcef = union(forcef, varargin{j});
    end
    j = j+1;
end

%print st first - it affects later codes
exstr = [];
if isfield(S,'st') && ischar(S.st)
    fprintf(fid,'st=%s\n',S.st);
    f = setdiff(f,'st');
end
%write exf field first
for j = 1:length(exf)
    x = S.(exf{j});
    if ischar(x)
        fprintf(fid,'%s=%s\n',exf{j},x);
        exstr = [exstr ' ' x];
    elseif length(x) > 1 %subspace
        fprintf(fid,'%s:',exf{j});
        for k = 1:length(x)
            fprintf(fid,'%s ',num2str(x(k)));
        end
        fprintf(fid,'\n');            
        exstr = [exstr ' ' num2str(x(1))];
    else
        fprintf(fid,'%s=%s\n',exf{j},num2str(x));
        exstr = [exstr ' ' num2str(x)];
    end
end

%Don't allow forcing of non-existent fields
forcef = intersect(forcef, fields(S));
for j = 1:length(forcef)
    x = S.(forcef{j});
    if ischar(x)
        fprintf(fid,'%s=%s\n',forcef{j},x);
    else
        fprintf(fid,'%s=%s\n',forcef{j},num2str(x));
    end
end

fprintf(fid,'manexpvals%d%s\n',stimno,exstr);

f = setdiff(f,exf);
f = setdiff(f,forcef);
for j = 1:length(f)
    x = S.(f{j});
    if ischar(x)
        fprintf(fid,'%s=%s\n',f{j},x);
    else
        fprintf(fid,'%s=%s\n',f{j},num2str(x));
    end
end

fclose(fid);
