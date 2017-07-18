function varargout = BuildExpt(varargin)
%AllS = BuildExpt(...  Makes stimulus description file for binoc
%This version does disparity/correlation subspace stimuli
%   ...,'dxvals', [dx],   give the list of dx vals for the subspace map
%   ...,'disps', [dx],   gives signal disparity values (usually one -, one +)
%   ..., 'acdisps', [ac] give disp values for the ac adaptors (first 100 frames) 
%   ..., 'signal' [x]  gives the signal strength valses (fraction of frames
%                      with signal disparity
%   ...,'ntrials', N, is the number of times each stimulus is presented
%   ...,'nrpts', R, is the number of times each exact (default 2 = twopass)

stimno= 1;
nf = 200;
j = 1;
stimvals{3} = [-0.1 0.1];
stimvals{2} = [-0.1 0.1];
stimmatrix = [];
stimvals{1} = [0 0.2 0.4 0.8];
distvals = -0.2:0.05:0.2;
ntrials = 10;
preframes = 100;
rpts = 2;
S.types = {'dx' 'ce'}; %these variable set frame by frame

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
    elseif strncmpi(varargin{j},'matrix',5)
        j = j+1;
        stimmatrix = varargin{j};
    elseif strncmpi(varargin{j},'nrpts',5)
        j = j+1;
        rpts = varargin{j};
    elseif strncmpi(varargin{j},'acdisps',5)
        j = j+1;
        stimvals{3} = varargin{j};
    elseif strncmpi(varargin{j},'signals',5)
        j = j+1;
        stimvals{1} = varargin{j};
    elseif strncmpi(varargin{j},'stimvals',5)
        j = j+1;
        stimvals = varargin{j};
    elseif strncmpi(varargin{j},'types',5)
        j = j+1;
        S.types = varargin{j};
    end
    j = j+1;
end

distw = length(distvals);
S.stimno = 0;
S.sl = 0;

if ~isempty(stimmatrix)
    for j = 1:size(stimmatrix,1)
        for k = 1:size(stimmatrix,2)
            S.vals{k} = stimmatrix(j,k);
            S.(S.types{k}) = stimmatrix(j,k);
        end
        S.stimno = j-1;
        WriteStim(S);
           AllS(j) = S;
    end
    S.stimno = j;
else
    nstim = [length(stimvals{1}) length(stimvals{2}) length(stimvals{3}) ntrials/rpts];
    for t = 1:nstim(4)
        for m = 1:nstim(3)
            for k = 1:nstim(2)
                for j = 1:nstim(1)
                    nsig = floor((stimvals{1}(j) .* (nf-preframes)));
                    S.vals{1} = distvals(ceil(rand(nf+1,1) .*distw));
                    S.vals{1}(1:preframes) = stimvals{2}(k);
                    sigframes = preframes + floor(rand(nsig,1) .* 100);
                    S.vals{1}(sigframes) = stimvals{3}(m);
                    S.vals{2}(1:preframes) = -1;
                    S.vals{2}(preframes+1:200) = 1;
                    S.ac = stimvals{2}(k);
                    S.Dc = stimvals{1}(j);
                    S.se = 1000 + S.stimno .*200;
                    S.(S.types{1}) = stimvals{1}(j);
                    S.(S.types{2}) = stimvals{2}(k);
                    S.signal = stimvals{1}(j) .* sign(S.(S.types{1}));
                    WriteStim(S);
                    
                    AllS(S.stimno+1) = S;
                    S.stimno = S.stimno+1;
                end
            end
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

fid = fopen('/local/manstim/stimorder','w');
fprintf(fid,'%d ',stimorder); 
fprintf(fid,'\n');
fclose(fid);

function WriteStim(S)
stimno= 1;
j = 1;


sname = ['/local/manstim/stim' num2str(S.stimno)];
fid = fopen(sname,'w');
if isfield(S,'signal')
    fprintf(fid,'psyv=%.4f\n',S.signal);
end
if isfield(S,'se')
    fprintf(fid,'se=%d\n',S.se);
end
fprintf(fid,'exvals');
for j = 1:length(S.types)
    fprintf(fid,'%.2f ',S.(S.types{j}));
end
fprintf(fid,'\n');
types = {'dx' 'ce'};
for k = 1:length(S.types)
    if length(S.vals{k}) > 1
        fprintf(fid,'%s:',S.types{k});
        for j = 1:length(S.vals{k})
            fprintf(fid,' %.2f',S.vals{k}(j));
        end
    else
        fprintf(fid,'%s=%.2f',S.types{k},S.vals{k}(1));
    end
    fprintf(fid,'\n');
end
fclose(fid);


