function varargout = interleaved_test(path, varargin)
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
%MONKEY  = 'pla';
PATH    = ['/local/expts'];

SIGNALS = [0 0.09 0.18 0.27];
NTRIALS = 3;
NRPTS   = 2;
DX      = [-0.3:0.05:0.3];
NBLK    = 10;
NF      = 300;
PF      = 150;

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
j = 1;
while j <= length(varargin)
    if strcmp(varargin{j},'signals')
        j = j+1;
        SIGNALS = varargin{j};
    end
    j = j+1;
end

BuildACadapt2('dxvals',DX,'disps',[-0.1 0.1],'signals', SIGNALS,'preframes',PF,'ntrials',NTRIALS,'nrpts', 1,'nf',NF,'clear','psych','dir',dirA,'acdisp',-0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);
BuildACadapt2('dxvals',DX,'disps',[-0.1 0.1],'signals', SIGNALS,'preframes',PF,'ntrials',NTRIALS,'nrpts', 1,'nf',NF,'clear','psych','dir',dirB,'acdisp',0.1,'adaptcorr',-1,'ilac',0,'uncor',0,'blank',0);


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
%add repeat
n1 = []; n2 = [];
for i=1:NRPTS
    n1 = [n1 t1];
    n2 = [n2 t2];
end

%%combine into one group
%n = [n1 n2]; 
% stimorder = n(randperm(length(n)));
% for i=1:length(stimorder)
%     if ismember(stimorder(i),n1)
%         group(i) = 1;
%     elseif ismember(stimorder(i),n2)
%         group(i) = 2;
%     else
%         group(i) = 0;
%     end
% end

order{1} = n1(randperm(length(n1)));
order{2} = n2(randperm(length(n2)));
stimorder=[]; group=[]; 
ID = round(rand)+1;AD = setdiff(1:2,ID);
for i=1:ceil(length(order{1})/NBLK)
    if i==ceil(length(order{1})/NBLK)
        tmpA = order{ID}((i-1)*NBLK+1:length(order{ID}));
        tmpB = order{AD}((i-1)*NBLK+1:length(order{AD}));

        stimorder = [stimorder tmpA];
        group = [group ones(1,length(tmpA))];

        stimorder = [stimorder tmpB];
        group = [group 2*ones(1,length(tmpB))];

        clear tmpA tmpB
    else

        tmpA = order{ID}((i-1)*NBLK+1:i*NBLK);
        tmpB = order{AD}((i-1)*NBLK+1:i*NBLK);

        stimorder = [stimorder tmpA];
        group = [group ones(1,length(tmpA))];

        stimorder = [stimorder tmpB];
        group = [group 2*ones(1,length(tmpB))];

        clear tmpA tmpB

    end
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









        
        
        
        