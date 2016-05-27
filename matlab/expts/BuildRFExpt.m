function result = BuildRFExpt(varargin)
%Build Expt to compear RF responses to 100ms flashes with short/long ISIS.
%
%
result.abort = 0;
ntrials = [80 20]; %4:1 ratio probably best.  Need more of the RC to pick out sequences
trialratio = 4;
dirroot = '/local/expts/RFRC';
ops = -1:0.15:1;
type = 'longisi';

j = 1; 
while j <= length(varargin)
    if strncmpi(varargin{j},'abort',5)
        result.abort = 1;
        return;
    elseif strncmpi(varargin{j},'longisi',4)
        type = 'longisi';
    elseif strncmpi(varargin{j},'noisi',4)
        type = 'noisi';
    elseif strncmpi(varargin{j},'ntrials',2)
        j = j+1; 
        ntrials = varargin{j};
        if length(ntrials) == 1
            ntrials(2) = round(ntrials/trialratio);
        end
    elseif strncmpi(varargin{j},'ops',3)
        j = j+1;
        ops = varargin{j};
    end
    j = j+1;
end
nstim = length(ops) + 1;
nper = [20 4];
stimvals = [ops -1009];
nstim = length(stimvals);


Fr = 10;
stimvals = [ops -1009 -1009];
seq = ceil(rand(ntrials(1),nper(1)).*(nstim+1)); %extra blanks
bseq = ceil(rand(ntrials(2),nper(2)).*nstim);
isiframes = 40;
for j = 1:ntrials(1)+ntrials(2)
    stimfile = [dirroot '/stim' num2str(j-1)];
    fid = fopen(stimfile,'w');
    fprintf(fid,'nf=%.0f\n',Fr.*nper(1));
    fprintf(fid,'stimtag=%s\n',type);
    fprintf(fid,'xo=rx\nyo=ry\n\n',Fr.*nper(1));
    if j <= ntrials(1)
        fprintf(fid,'Fr=10\nOp:');
        for k = 1:size(seq,2)
            for f = 1:Fr
                fprintf(fid,' %.3f',stimvals(seq(j,k)));
            end
        end
    else
        fprintf(fid,'Fr=50\nOp:');
        for k = 1:size(bseq,2)
            t = j - ntrials(1);
            for f = 1:Fr
                fprintf(fid,' %.3f',stimvals(bseq(t,k)));
            end
            for f = 1:isiframes
                if strcmp(type,'longisi')
                fprintf(fid,' -1009');
                else
                fprintf(fid,' %.3f',stimvals(bseq(t,k)));
                end
            end
        end
    end
    fprintf(fid,'\n');
    fclose(fid);
end
for j = 1:ntrials(1)
end
astimorder = randperm(ntrials(1));
bstimorder = ntrials(1)+randperm(ntrials(2));
na = 40;
nb = round(na/trialratio);
ablk= 1:na;
bblk = 1:nb;
blocks = floor(ntrials(1)./na);
nb = length(bblk);
if blocks == 0
    stimorder = [astimorder bstimorder];
    stimorder = stimorder(1:ntrials(1));
else

for j = 1:blocks
    ao = (j-1) .* na;
    o = (j-1) .* (na+nb);
    bo = (j-1) .* nb;
    stimorder(o+ablk) = astimorder(ao+ablk);
    o = (j-1) .* (na+nb) + na;
    stimorder(o+bblk) = bstimorder(bo+bblk);
end
end
%stimorder([1:20 31:50 61:80 91:110]) = astimorder;
%stimorder([21:30 51:60 81:90 111:120]) = bstimorder;
%stimorder(1:40) = bstimorder;
stimfile = [dirroot '/stimorder'];
fid = fopen(stimfile,'w');
fprintf(fid,'%d ', stimorder-1);
fprintf(fid,'\n');
fclose(fid);

