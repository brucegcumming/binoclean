function varargout = Gamma_BLN_Expt(varargin)
%AllS = BuildExpt(...  Makes stimulus description file for binoc
%This version does disparity/correlation subspace stimuli
%   ...,'dxvals', [dx],   give the list of dx vals for the subspace map
%   ...,'disps', [dx],   gives signal disparity values (usually one -, one +)
%   ..., 'acdisps', [ac] give disp values for the ac adaptors (first 100 frames)
%   ..., 'signal' [x]  gives the signal strength valses (fraction of frames
%                      with signal disparity
%   ...,'ntrials', N, is the number of times each stimulus is presented
%   ...,'nrpts', R, is the number of times each exact (default 2 = twopass)

% stim_dir = '/Users/james/binoc_expts/gamma_BLnoise/stimFiles';
stim_dir = '/local/expts/gamma_BLnoise/';
if ~exist(stim_dir,'dir')
    fprintf('Making stim directory %s\n',stim_dir);
    system(sprintf('mkdir %s',stim_dir));
end

num_seqs = 5;
nf = 400;
j = 1;
stimvals{2} = {'ff','none','gback','grating'};
stimvals{1} = [1:num_seqs];
ntrials = 5; %number of times to repeat set
rpts = 1; %5 number of times to show each exact sequence

while j <= length(varargin)
    if strncmpi(varargin{j},'stimno',5)        stimno = varargin{j};
        j = j+1;

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
nstim = [length(stimvals{1}) length(stimvals{2}) ntrials/rpts];
for t = 1:nstim(3)
    for k = 1:nstim(2)
        for j = 1:nstim(1)
            cur_seq_num = stimvals{1}(j);
            cur_stim_type = stimvals{2}{k};
            
            if strcmp(cur_stim_type,'grating')
                S.st = 'grating';
                S.imi = [];
            else
                S.st = 'image';
                if strcmp(cur_stim_type,'ff')
                    S.imi = [1:nf]+cur_seq_num*1e3;
                else
                    S.imi = [1:nf]+cur_seq_num*1e3+1e4;
                end
            end
            
            if strcmp(cur_stim_type,'gback')
                S.Bs = 'grating';
            else
                S.Bs = 'none';
            end
            S.type = cur_stim_type;
            S.seq_num = cur_seq_num;
            
            sname = [stim_dir '/stim' num2str(S.stimno)];
            WriteStim(S, sname);
            
            AllS(S.stimno+1) = S;
            S.stimno = S.stimno+1;
        end
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
fprintf(fid,'st=%s\n',S.st);
if ~strcmp(S.st,'grating')
    fprintf(fid,'immode=binocular\n');    
    fprintf(fid,'imload=preload\n');
    fprintf(fid,'imi:');
for j = 1:length(S.imi)
    fprintf(fid,' %d',S.imi(j));
end
fprintf(fid,'\n');
end
fprintf(fid,'Bs=%s\n',S.Bs);
fprintf(fid,'exvals%d %s\n',S.seq_num,S.type);
fclose(fid);


