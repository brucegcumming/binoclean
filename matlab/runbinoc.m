function runbinoc(varargin)
nloops = 10;

j = 1;
while j <= length(varargin)
    if strcmp(varargin{j},'nloop')
        j = j+1;
        nloops = varargin{j};
    elseif strcmp(varargin{j},'testgrating')
        BinocCommand({'st=grating' 'bc=0.5' 'co=1' 'sz=5' 'sf=2' 'nf=100'});
        BinocCommand('uf=/local/test/painttest');
        BinocCommand(sprintf('!runtest11 %d',nloops));
    end
    j = j+1;
end