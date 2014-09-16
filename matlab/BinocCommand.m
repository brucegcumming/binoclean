function BinocCommand(str)
% BinocCommand(str) Sends a single commnad to binoclean
%useful to co-ordinate gamma calibration

DATA.verbose = 1;
DATA.ip = 'http://localhost:1110/';
if iscellstr(str)
    for j = 1:length(str)
        outprintf(DATA,str{j});
    end
else
    outprintf(DATA,str);
end
 



function outprintf(DATA,varargin)
 %send to binoc.  ? reomve comments  like in expt read? 
     str = sprintf(varargin{:});
     strs = split(str,'\n');
     for j = 1:length(strs)
         if ~isempty(strs{j})
             str = [DATA.ip strs{j}];
             if DATA.verbose
                 fprintf('%s\n',str);
             end
             ts = now;
             [bstr, status] = urlread(str,'Timeout',2);
             if ~isempty(bstr)
                 fprintf('Binoc replied with %s\n',bstr);
             elseif DATA.verbose
                 fprintf('Binoc returned in %.3f\n',mytoc(ts));
             end
         end
     end
