function Expt = example(varargin)
%simple example that generates a dx X ce experiment
%but controlled from matlab
%N.B. will only work if basedir (where files are written) exists!!!!
%
%bgc/matlab/@stim/manAC.stm   contains the minimum .stm file necessary to
%run an experiment with this
basedir='/local/expts/rds'; % where stim0 ... stimn-1 are written
S.st = 'rds'; %this expt uses rds.
exptvars = {'dx' 'ce'}; %and changes dx and ce
nrpts = 5;

j = 1;
while j <= length(varargin)
    if strcmp(varargin{j},'dir')
        j = j+1;
        basedir = varargin{j};
    elseif strcmp(varargin{j},'nrpts')
        j = j+1;
        nrpts = varargin{j};
    end
    j = j+1;
end

Expt.stimdir = basedir; %returned to verg, tells it where to find stims

n = 0;
for dx = -0.1:0.02:0.1
    S.dx = dx;
  for ce = -1:2:1
      S.ce = ce;
      stim.WriteStim(basedir,n,S, exptvars);
      n = n+1;
  end
  Expt.S{n} = S; %Return a list of stims too
end
stim.WriteOrder(basedir,stim.SetOrder([0:n-1],nrpts), exptvars);