function varargout = interleaved_test(name)

%BuildACadapt('dxvals',-0.6:0.1:0.6,'preframes',150,'ntrials',80,'nrpts',2,'nf',300,'clear','dir','/local/jbe/expts/ACadaptpsych','adaptcorr', 1,'acdisps',0.1,'ilac',0,'uncor',0,'blank',0)
%BuildACadapt('dxvals',-0.6:0.1:0.6,'preframes',150,'ntrials',80,'nrpts',2,'nf',300,'clear','dir','/local/jbe/expts/ACadaptpsych','adaptcorr', -1,'acdisps',0.1,'ilac',0,'uncor',0,'blank',0)

%BuildACadapt('dxvals',[-0.6:0.1:0.6],'preframes',0,'ntrials',80,'nrpts',2,'nf',150,'clear','dir','/local/lem/expts/tmp/runB','ilac',0,'uncor',0,'blank',0)
MONKEY = name;

BuildACadapt('dxvals',[-0.6:0.1:0.6],'disps',[-0.1 0.1],'signals',[0 0.06 0.12 0.18],'preframes',150,'ntrials',3,'nrpts',1,'nf',300,'clear','psych','dir',['/local/' MONKEY '/expts/tmp/runA'],'acdisp',-0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);
BuildACadapt('dxvals',[-0.6:0.1:0.6],'disps',[-0.1 0.1],'signals',[0 0.06 0.12 0.18],'preframes',150,'ntrials',3,'nrpts',1,'nf',300,'clear','psych','dir',['/local/' MONKEY '/expts/tmp/runB'],'acdisp',0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);

dirA = ['/local/' MONKEY '/expts/tmp/runA/'];
dirB = ['/local/' MONKEY '/expts/tmp/runB/'];
SVDIR = ['/local/' MONKEY '/expts/ACadaptpsych/'];

%clear out stim directory
unix(['rm ' SVDIR '*']);

%copy stimuli from run 1 to stim directory
tmp = dir([dirA 'stim*']);
id = find(strcmp({tmp.name},'stimorder')==0);
svdir = ['/local/' MONKEY '/expts/ACadaptpsych/'];

for i=1:length(id)
    file = [dirA tmp(id(i)).name];
    unix(['cp ' file ' ' svdir]);
    file = [];
end

len1 = length(id);
id = [];
clear tmp

%copy and rename stimuli from run 2 to stim directory
tmp = dir([dirB 'stim*']);
id = find(strcmp({tmp.name},'stimorder')==0);
len2 = length(id);

for i=1:length(id)
    file = [dirB tmp(id(i)).name];
    svfile = [svdir 'stim' num2str(i+len1-1)];
    unix(['cp ' file ' ' svfile]);
    file = []; svfile = [];
end

groups(1:len1) = 1;
groups(1+len1:len1+len2) = 2;
%make stimorder file
t = [0:len1+len2-1];
neworder = randperm(length(t));
order = t(neworder);
groups = groups(neworder);
%write order file to disk

sname = [SVDIR 'stimorder'];
fid = fopen(sname,'w');
for i=1:length(order)
    fprintf(fid,'%i ',order(i));
end 
fprintf(fid,'\ngroup ');
for i=1:length(order)
    fprintf(fid,'%i ',groups(i));
end 
fprintf(fid,'\n');
fclose(fid);


if nargout > 0
    varargout{1} = '1';
end









        
        
        
        