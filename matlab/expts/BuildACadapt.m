function varargout = BuildACadapt(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function varargout = BuildACadapt(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   AllS = BuildACadapt(...  Makes stimulus description file for binoc
%   !!!! ACadapt and BuildExpt are old and deprecated !!!!
%   
%   This version does disparity/correlation subspace stimuli
%   ...,'dxvals', [dx],   give the list of dx vals for the subspace map
%   ...,'disps', [dx],   gives signal disparity values (usually one -, one +)
%   ..., 'acdisps', [ac] give disp values for the ac adaptors (first 100 frames) 
%   ..., 'signal' [x]  gives the signal strength valses (fraction of frames
%                      with signal disparity
%   ...,'ntrials', N, is the number of times each stimulus is presented
%   ...,'nrpts', R, is the number of times each exact (default 2 = twopass)
%   ...,'ngap',N, puts N blank frames between adaptor and subspace map
%
%   version history
%       some time in the past: v1.0 AB
%       07/25/14:  added ngap to place user adjustable blank gap between
%       adaptor and subspace map.  User needs to work out preframes and nf
%       to have the desired ngap work out properly.  PLA


% set timer
tic;

% init vars with default params
stimno= 1; 
fz = 100;
dur=3;
j = 1;
psych=0;
write=1;
uncorr=1;
blank=1;
stimvals{3} = [0]; % for psychophysics, these are the signal disparities
stimvals{2} = [0]; % these are the anticorrelated adaptor disparities
stimvals{1} = [0]; % signal level (if not psych, this boosts the AC adaptor after preframes over)
dxvals = -1:0.1:1; % dx vals
ntrials = 50;
adaptcorr=-1;
Fr=2;
rpts = 2;
rng('shuffle');
ilac=0.5;
cleardir=0;
directory='/local/TEST';
ngap=0;

% parse user input
while j <= length(varargin)
    if strncmpi(varargin{j},'stimno',5)
        j = j+1;
        stimno = varargin{j};
    elseif strncmpi(varargin{j},'dxvals',5)
        j = j+1;
        dxvals = varargin{j};
    elseif strncmpi(varargin{j},'disps',5)
        j = j+1;
        stimvals{3} = varargin{j};
    elseif strncmpi(varargin{j},'ntrials',7)
        j = j+1;
        ntrials = varargin{j};
    elseif strncmpi(varargin{j},'nrpts',5)
        j = j+1;
        rpts = varargin{j};
    elseif strncmpi(varargin{j},'clear',5)
        cleardir=1;
    elseif strncmpi(varargin{j},'acdisps',5)
        j = j+1;
        stimvals{2} = varargin{j};
    elseif strncmpi(varargin{j},'signals',5)
        j = j+1;
        stimvals{1} = varargin{j};
    elseif strncmpi(varargin{j},'psych',4)
        psych=1;
    elseif strncmpi(varargin{j},'nf',4)
        j=j+1;
        nf=varargin{j};
    elseif strncmpi(varargin{j},'preframes',4)
        j=j+1;
        preframes=varargin{j};
    elseif strncmpi(varargin{j},'directory',3)
        j=j+1;
        directory=varargin{j};
    elseif strncmpi(varargin{j},'fz',3)
        j=j+1;
        fz=varargin{j};
    elseif strncmpi(varargin{j},'dur',3)
        j=j+1;
        dur=varargin{j};
    elseif strncmpi(varargin{j},'nowrite',4)
        write=0;
    elseif strncmpi(varargin{j},'adaptcorr',6)
        j=j+1;
        adaptcorr=varargin{j};
    elseif strncmpi(varargin{j},'ilac',4)
        j=j+1;
        ilac=varargin{j};
    elseif strncmpi(varargin{j},'blank',4)
        j=j+1;
        blank=varargin{j};
    elseif strncmpi(varargin{j},'uncorr',4)
        j=j+1;
        uncorr=varargin{j};
    elseif strncmpi(varargin{j},'ngap',4)
        j=j+1;
        ngap=varargin{j};
    elseif strncmpi(varargin{j},'Fr',2)
        j=j+1;
        Fr=varargin{j};
    end
    j = j+1;
end
if ~exist('nf','var')
    nf=dur*fz;
end
if uncorr
    dxvals=[dxvals -1005];
end
if blank
    dxvals=[dxvals -1009];
end
if ~exist('preframes','var')
    preframes=round(nf/2);
end
if ngap>0
    disp('***** ngap set *****')
    %PrintMsg('ngap set: %n frames will be shown between adapt period and subspace map',ngap,'color',[0 0 1])
end
if cleardir
    PrintMsg(0,'Clearing directory %s.',directory);
    delete([directory,'/stim*']);
else
    PrintMsg(0,'Writing to %s without clearing.',directory);
end
S.stimno = 0;
S.sl = 0;
%these variable set frame by frame
S.types = {'dx' 'ce' 'mycodes'};
if ~psych
    S.types=S.types(1:2);
end
nstim = [length(stimvals{1}) length(stimvals{2}) length(stimvals{3}) ceil(ntrials/rpts)];
PrintMsg(0,'%g Dc [%s]\nX %g acdx [%s]\nX %g dx [%s]\n(%g times each, to include %g repeats per stimulus) = %g stim files and %g trials.',...
    nstim(1),num2str(stimvals{1}),nstim(2),num2str(stimvals{2}),nstim(3),num2str(stimvals{3}),nstim(4)*rpts,rpts,prod(nstim),prod(nstim)*rpts);
for t = 1:nstim(4)
    for m = 1:nstim(3)
        for n = 1:nstim(2)
            for j = 1:nstim(1)
                % generated sigframes from a binomial distribution
                sigframes=(preframes+ngap)+find(rand(nf-(preframes+ngap),1)<stimvals{1}(j));
                %init mycodes
                codes(1:nf)=0;
                codes(1:preframes)=1;
                codes(sigframes)=2;
                dxseq = dxvals(ceil(rand(nf,1) .*length(dxvals))); 
                dxseq(1:preframes) = stimvals{2}(n);
                ceseq(1:preframes) = adaptcorr;                
                if psych
                    %signal during sigframes does not necessarily match preframes
                    dxseq(sigframes) = stimvals{3}(m); 
                else
                    %signal during sigframes matches preframes
                    dxseq(sigframes) = stimvals{2}(m);                   
                end
                
                if ilac>0.5
                    PrintMsg(0,'You set ilac > 0.5.  This means more than half of interleaves will be anticorrelated!  ','color',[1 0 0]);
                end
                % divide frames into corr and anticorr 
                ti = preframes+ngap+1:nf;
                ceseq(ti) = rand(1,nf-(preframes+ngap))>ilac;
                fi = ceseq(ti)==0;
                ceseq(ti(fi))=-1;
                clear ti fi
                
                %set blank gap if requested
                if ngap>0
                    codes(preframes+1:preframes+ngap) = 3;
                    dxseq(preframes+1:preframes+ngap) = -1009;
                end
                
                % set uncorrelated frames
                ceseq(dxseq==-1005)=0;
                % set blank frames   
                ceseq(dxseq==-1009)=-1009;
                
                if ~S.stimno && length(ceseq)>nf
                    PrintMsg(0,'Number of elements in sequence greater than nf: %s > %s !',num2str(length(ceseq)),num2str(nf),'color',[1 0 0]);
                end                    
                S.vals{1}=dxseq(1:nf);
                S.vals{2}=ceseq(1:nf);
                S.vals{3}=codes(1:nf);
                if Fr>1
                    for i=preframes+ngap+1:Fr:nf
                        for l=1:length(S.types)
                            S.vals{l}(i:min(i+Fr-1,nf))=S.vals{l}(i);                      
                        end
                    end
                end                   
                S.ac = stimvals{2}(n);
                S.Dc = stimvals{1}(j);
                S.se = 1000 + S.stimno .*200;
                S.dx = stimvals{3}(m);
                S.Fr=Fr;
                S.signal = stimvals{1}(j) .* sign(S.dx);
                if write
                    fid = WriteStim(S,directory,psych);
                    if fid<0
                        PrintMsg(0,'Could not write stimno %s to directory: %s        ',num2str(S.stimno),directory,'color',[1 0 0]);
                        return
                    end
                end
                AllS(S.stimno+1) = S;
                S.stimno = S.stimno+1;
            end
        end
    end
end
if psych
    % generate trial order
    stimorder = repmat([0:S.stimno-1],rpts);
    % randomize trial order
    stimorder = stimorder(randperm(length(stimorder))); 
else
    stimorder=[];
    for i=1:nstim(2)
        currtrials=find([AllS.ac]==stimvals{2}(i));
        for n=1:rpts
            stimorder=[stimorder currtrials(randperm(length(currtrials)))];
        end
    end
    stimorder = stimorder-1;    
end
if nargout > 0
    varargout{1} = AllS;
end
if nargout > 1
    varargout{2} = stimorder;
end
if write
    fid = fopen([directory,'/stimorder'],'w');
    fprintf(fid,'%d ',stimorder); 
    fprintf(fid,'\n');
    fclose(fid);
end
PrintMsg(0,'Took %s',timestr(toc));
end

function fid = WriteStim(S,directory,psych)
    
stimno= 1;
j = 1;
sname = [ [directory,'/stim'] num2str(S.stimno)];
fid = fopen(sname,'w');
if ispc && fid<0
    sname=['\' sname(2:end)];
    fid = fopen(sname,'w');    
end
if fid<0
    return
end
fprintf(fid,'psyv=%.4f\n',S.signal);
fprintf(fid,'se=%d\n',S.se);
fprintf(fid,'mo=back\n');
fprintf(fid,'st=rds\n');
fprintf(fid,'mo=fore\n');
fprintf(fid,'st=rds\n');
fprintf(fid,'exvals%.2f %.2f %.2f\n',S.dx,S.Dc,S.ac);
fprintf(fid,'dx=%0.3f\n',S.dx);
fprintf(fid,'Dc=%0.2f\n',S.Dc);
fprintf(fid,'Fr=%0.2f\n',S.Fr);
fprintf(fid,'sl=%d\n',S.sl);
fprintf(fid,'nf=%d\n',length(S.vals{1}));
if psych==0
    fprintf(fid,'sa=%d\n',0);
    fprintf(fid,'op=-afc\n');
end
types = {'dx' 'ce'};
for k = 1:length(S.types)
    fprintf(fid,'%s:',S.types{k});
    if strncmpi(S.types{k},'dx',2)
        S.vals{k}=myround(S.vals{k},3);
        if sum(myround(S.vals{k},1)==S.vals{k})==length(S.vals{k})
            ndec=1;
        elseif sum(myround(S.vals{k},2)==S.vals{k})==length(S.vals{k})
            ndec=2;
        elseif sum(myround(S.vals{k},3)==S.vals{k})==length(S.vals{k})
            ndec=3;
        end
    else
        ndec=0;
    end
    for j = 1:length(S.vals{k})
        fprintf(fid,[' %.',num2str(ndec),'f'],S.vals{k}(j));
    end
    fprintf(fid,'\n');
end
fclose(fid);
end

