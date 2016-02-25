function WriteStim(basedir, stimno, S, exf)
%stim.WriteStim(basedir, stimno, S, exvals)
%Creates a stimN file for controlling binoc expts in basedir
%each field in S, is written into the file
%if exvals is givne, it lists fields that matter for subsequent plotting
%recorded in each stim file with manexpvals

stimname = sprintf('%s/stim%d',basedir,stimno);
fid = fopen(stimname,'w');
if fid < 0
    cprintf('red','Cannot Write to file %s\n',stimname);
    return;
end
f = fields(S);

%print st first - it affects later codes
exstr = [];
if isfield(S,'st') && ischar(S.st)
    fprintf(fid,'st=%s\n',S.st);
    f = setdiff(f,'st');
end
for j = 1:length(f)
    x = S.(f{j});
    if ischar(x)
        fprintf(fid,'%s=%s\n',f{j},x);
        if sum(strcmp(f{j},exf));
            exstr = [exstr ' ' x];
        end
    else
        fprintf(fid,'%s=%s\n',f{j},num2str(x));
        if sum(strcmp(f{j},exf));
            exstr = [exstr ' ' num2str(x)];
        end
    end
end

fprintf(fid,'manexpvals%d%s\n',stimno,exstr);
fclose(fid);
