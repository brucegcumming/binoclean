function varargout = Smooth_Pursuit_RLS(varargin)
%AllS = BuildExpt(...  Makes stimulus description file for binoc
%This version does disparity/correlation subspace stimuli
%   ...,'dxvals', [dx],   give the list of dx vals for the subspace map
%   ...,'disps', [dx],   gives signal disparity values (usually one -, one +)
%   ..., 'acdisps', [ac] give disp values for the ac adaptors (first 100 frames) 
%   ..., 'signal' [x]  gives the signal strength valses (fraction of frames
%                      with signal disparity
%   ...,'ntrials', N, is the number of times each stimulus is presented
%   ...,'nrpts', R, is the number of times each exact (default 2 = twopass)

% stim_dir = '~/Desktop/testing/';
stim_dir = '/local/expts/smoothPursuit/';
if ~exist(stim_dir,'dir')
    fprintf('Making stim directory %s\n',stim_dir);
    system(sprintf('mkdir %s',stim_dir));
end

ntrials = 8; %number of times to repeat set
fp_vel = 2.5; %smooth pursuit velocity (deg/sec)
frame_dt = 0.01;

rpts = 1; %number of times to show each exact sequence
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'ori',3)
        j = j+1;
        or = varargin{j};
    elseif strncmpi(varargin{j},'nf',2)
        j = j+1;
        nf = varargin{j};
    elseif strncmpi(varargin{j},'fx',2)
        j = j+1;
        base_fx = varargin{j};
    elseif strncmpi(varargin{j},'fy',2)
        j = j+1;
        base_fy = varargin{j};
    elseif strncmpi(varargin{j},'ntrials',5)
        j = j+1;
        ntrials = varargin{j};
    elseif strncmpi(varargin{j},'nrpts',5)
        j = j+1;
        rpts = varargin{j};
    elseif strncmpi(varargin{j},'size',3)
        j = j+1;
        sacsize=varargin{j};
    end
    j = j+1;
end


if ~exist('or','var')
    error('Need to provide bar oriention')
end
if ~exist('nf','var')
    error('Need to provide nf')
end  
if ~exist('base_fx','var') | ~exist('base_fy','var')
    error('Need to provide fx and fy')
end  

start_disp = fp_vel*nf*frame_dt/2; %initial displacement of fp (deg)

stimvals{1} = {'fix','smooth'};
stimvals{2} = [0 90 180 270]; %poss pursuit directions (relative to bar ori)

S.stimno = 0;
S.sl = 0;
nstim = [length(stimvals{1}) length(stimvals{2}) ntrials/rpts];
for k = 1:nstim(2)
    for j = 1:nstim(1)
        move_angle = stimvals{2}(k) + or; %direction of fp motion
        Rmat = [cosd(move_angle) -sind(move_angle); sind(move_angle) cosd(move_angle)];
        start_fp = Rmat*[-start_disp 0]'; %apply rotation to get initial fp location
        S.fx = base_fx + start_fp(1);
        S.fy = base_fy + start_fp(2);
        
        S.Fa = mod(90 - move_angle,360); %convert to Fa coordinates
        
        if strcmp(stimvals{1}{j},'smooth')
            S.pi = fp_vel; %pursuit velocity in deg/sec
        else     
            S.pi = 0;
        end
        
        S.se = 1000 + round(rand(1,1).*10000) .*1000; %random seed for trial

        sname = [stim_dir '/stim' num2str(S.stimno)];
        WriteStim(S, sname);
        
        AllS(S.stimno+1) = S;
        S.stimno = S.stimno+1;
    end
end

f = fields(AllS);
for j = 1:length(AllS)
    fprintf('%d:',j-1)
    for k = 1:length(f)
        if isnumeric(AllS(j).(f{k}))
            fprintf(' %s=%.2f',f{k},AllS(j).(f{k}));
        end
    end
    fprintf('\n');
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
fprintf(fid,'Fa=%.1f\n',S.Fa);
fprintf(fid,'se=%d\n',S.se);
fprintf(fid,'pi=%.3f\n',S.pi);
fprintf(fid,'fx=%.1f\n',S.fx);
fprintf(fid,'fy=%.1f\n',S.fy);
fprintf(fid,'exvals%.3f %.1f %.1f %.1f\n',S.pi,S.Fa,S.fx,S.fy);
fclose(fid);


