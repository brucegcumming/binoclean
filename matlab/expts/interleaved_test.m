function varargout = interleaved_test(path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function varargout = interleaved_test(path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function creates an intervleaved manula stimulus sequence for BINOC
% much of this function is really a script and the parameters for the
% stimulus build needs to be editied directly in the script.  The function
% calls Adrian's function BuildACadapt.  This function has the input of the
% path to the stimulus folders.  There folders need to be folders as follows
%
%    path/runA
%    path/runb
%    path/ACadaptpsych
%
% currently this function is hardwired to run subsets of stimuli from near
% and far adaptor conditions using the "group" stimulus presentation
% function


%BuildACadapt('dxvals',-0.6:0.1:0.6,'preframes',150,'ntrials',80,'nrpts',2,'nf',300,'clear','dir','/local/jbe/expts/ACadaptpsych','adaptcorr', 1,'acdisps',0.1,'ilac',0,'uncor',0,'blank',0)
%BuildACadapt('dxvals',-0.6:0.1:0.6,'preframes',150,'ntrials',80,'nrpts',2,'nf',300,'clear','dir','/local/jbe/expts/ACadaptpsych','adaptcorr', -1,'acdisps',0.1,'ilac',0,'uncor',0,'blank',0)

%BuildACadapt('dxvals',[-0.6:0.1:0.6],'preframes',0,'ntrials',80,'nrpts',2,'nf',150,'clear','dir','/local/lem/expts/tmp/runB','ilac',0,'uncor',0,'blank',0)
%DEFAULTS
MONKEY = 'lem';
SIGNALS = [0 0.06 0.12 0.18];
NTRIALS = 5;
PATH = ['/local/' MONKEY '/expts'];
% if ~isempty(name)
%     MONKEY = name;
% end
% 
% if ~isempty(signals)
%     SIGNALS = signals;
% end
% 
% if ~isempty(nrpts)
%     NRPTS = nrpts;
% end
if ~isempty(path)
    PATH = path;
end
% BuildACadapt('dxvals',[-0.6:0.1:0.6],'disps',[-0.1 0.1],'signals', SIGNALS,'preframes',150,'ntrials',NTRIALS,'nrpts', 1,'nf',300,'clear','psych','dir',['/local/' MONKEY '/expts/tmp/runA'],'acdisp',-0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);
% BuildACadapt('dxvals',[-0.6:0.1:0.6],'disps',[-0.1 0.1],'signals', SIGNALS,'preframes',150,'ntrials',NTRIALS,'nrpts', 1,'nf',300,'clear','psych','dir',['/local/' MONKEY '/expts/tmp/runB'],'acdisp',0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);

dirA = [PATH '/runA/'];
dirB = [PATH '/runB/'];
SVDIR = [PATH '/ACadaptpsych/'];

BuildACadapt('dxvals',[-0.6:0.1:0.6],'disps',[-0.1 0.1],'signals', SIGNALS,'preframes',150,'ntrials',NTRIALS,'nrpts', 1,'nf',300,'clear','psych','dir',dirA,'acdisp',-0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);
BuildACadapt('dxvals',[-0.6:0.1:0.6],'disps',[-0.1 0.1],'signals', SIGNALS,'preframes',150,'ntrials',NTRIALS,'nrpts', 1,'nf',300,'clear','psych','dir',dirB,'acdisp',0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);


% dirA = ['/local/' MONKEY '/expts/tmp/runA/'];
% dirB = ['/local/' MONKEY '/expts/tmp/runB/'];
% SVDIR = ['/local/' MONKEY '/expts/ACadaptpsych/'];


%clear out stim directory
unix(['rm ' SVDIR '*']);

%copy stimuli from run 1 to stim directory
tmp = dir([dirA 'stim*']);
id = find(strcmp({tmp.name},'stimorder')==0);
%svdir = ['/local/' MONKEY '/expts/ACadaptpsych/'];

for i=1:length(id)
    file = [dirA tmp(id(i)).name];
    unix(['cp ' file ' ' SVDIR]);
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
    svfile = [SVDIR 'stim' num2str(i+len1-1)];
    unix(['cp ' file ' ' svfile]);
    file = []; svfile = [];
end


%make stimorder file
t1 = 0:len1-1;
t2 = len1:len1+len2-1;

order1 = t1(randperm(length(t1)));
order2 = t2(randperm(length(t2)));
stimorder=[]; group=[];
for i=1:length(order1)/5
    tmpA = order1((i-1)*5+1:i*5);
    tmpB = order2((i-1)*5+1:i*5);
    
    stimorder = [stimorder tmpA];
    group = [group ones(1,5)];
    
    stimorder = [stimorder tmpB];
    group = [group 2*ones(1,5)];
    
    clear tmpA tmpB
end

%write order file to disk
sname = [SVDIR 'stimorder'];
fid = fopen(sname,'w');
for i=1:length(stimorder)
    fprintf(fid,'%i ',stimorder(i));
end 

fprintf(fid,'\n%s ','group');

for i=1:length(group)
    fprintf(fid,'%i ',group(i));
end 


fclose(fid);


%make stimorder file
% t = [0:len1+len2-1];
% order = t(randperm(length(t)));
% 
% 
% %write order file to disk
% sname = [SVDIR 'stimorder'];
% fid = fopen(sname,'w');
% for i=1:length(order)
%     fprintf(fid,'%i ',order(i));
% end 
% fclose(fid);


if nargout > 0
    varargout{1} = '1';
end









        
        
        
        