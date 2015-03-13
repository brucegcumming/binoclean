function varargout = frozen_noise_Expt(varargin)
%AllS = BuildExpt(...  Makes stimulus description file for binoc
%This version does disparity/correlation subspace stimuli
%   ...,'dxvals', [dx],   give the list of dx vals for the subspace map
%   ...,'disps', [dx],   gives signal disparity values (usually one -, one +)
%   ..., 'acdisps', [ac] give disp values for the ac adaptors (first 100 frames)
%   ..., 'signal' [x]  gives the signal strength valses (fraction of frames
%                      with signal disparity
%   ...,'ntrials', N, is the number of times each stimulus is presented
%   ...,'nrpts', R, is the number of times each exact (default 2 = twopass)

% stim_dir = '/Users/james/binoc_expts/';
stim_dir = '/local/expts/frozenNoise/';
if ~exist(stim_dir,'dir')
    fprintf('Making stim directory %s\n',stim_dir);
    system(sprintf('mkdir %s',stim_dir));
end

num_frozen_seqs = 2;
fixed_seeds = 1000 + (1:num_frozen_seqs);
num_total_seqs = 10;
nf = 400;
j = 1;
stimvals{1} = [1:num_total_seqs];
ntrials = 6; %number of times to repeat set
rpts = 1; %5 number of times to show each exact sequence

while j <= length(varargin)
    if strncmpi(varargin{j},'stimno',5)
        j = j+1;
        stimno = varargin{j};
    elseif strncmpi(varargin{j},'dxvals',5)
        j = j+1;
        distvals = varargin{j};
    elseif strncmpi(varargin{j},'disps',5)
        j = j+1;
        stimvals{2} = varargin{j};
    elseif strncmpi(varargin{j},'ntrials',5)
        j = j+1;
        ntrials = varargin{j};
    elseif strncmpi(varargin{j},'nrpts',5)
        j = j+1;
        rpts = varargin{j};
    elseif strncmpi(varargin{j},'acdisps',5)
        j = j+1;
        stimvals{3} = varargin{j};
    elseif strncmpi(varargin{j},'flip',5)
        flipsaccade = 1;
    elseif strncmpi(varargin{j},'size',3)
        j = j+1;
        sacsize=varargin{j};
    elseif strncmpi(varargin{j},'ori',5)
        j = j+1;
        S.or = varargin{j};
    elseif strncmpi(varargin{j},'yshift',5)
        S.types = {'imy'};
        S.or = 90;
    elseif strncmpi(varargin{j},'signals',5)
        j = j+1;
        stimvals{1} = varargin{j};
    end
    j = j+1;
end

S.stimno = 0;
nstim = [length(stimvals{1}) ntrials/rpts];
for t = 1:nstim(2)
    for j = 1:nstim(1)
        cur_seq_num = stimvals{1}(j);
        
        if cur_seq_num <= num_frozen_seqs
            S.se = fixed_seeds(j); 
        else
            S.se = 1000 + round(rand(1,1).*10000) .*1000; %random seed for trial
        end
        
        sname = [stim_dir '/stim' num2str(S.stimno)];
        WriteStim(S, sname);
        
        AllS(S.stimno+1) = S;
        S.stimno = S.stimno+1;
    end
end

stimorder = repmat([0:S.stimno-1],rpts);
stimorder = stimorder(randperm(length(stimorder)));
if nargout > 0
    varargout{1} = AllS;
end
if nargout > 1
    varargout{2} = stimorder;
end

fid = fopen([stim_dir '/stimorder'],'w');
fprintf(fid,'%d ',stimorder);
fprintf(fid,'\n');
fclose(fid);

function WriteStim(S, sname)

fid = fopen(sname,'w');
fprintf(fid,'se=%d\n',S.se);
fprintf(fid,'exvals%d\n',S.se);
fclose(fid);


