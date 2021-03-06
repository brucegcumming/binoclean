function verg(varargin)
%binoc
%GUI for running binoclean via pipe.

autoquit = 0;

if length(varargin) & ishandle(varargin{1})
    f = varargin{1};
    while ~isfigure(f)
        f = get(f,'parent');
    end
    DATA = get(f,'UserData');
    varargin = varargin(3:end);
else
    checkforrestart = 1;
    TOPTAG = 'vergwindow';
    it = findobj('Tag',TOPTAG,'type','figure');
    setdata = 0;
%just parse arguments here that need to be set before reading DATA from figure    
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'autoreopen',6)
        if j ==1 && ~isempty(it) %User changing after window opened
            DATA = get(it(1),'UserData');
            setdata = 1;
        end
        DATA.autoreopen =1;
        if length(varargin) == j+1          %final argument after autoreopen = line to resend
            j = j+1;
            DATA.reopenstr = varargin{j};
        end

    elseif strcmp(varargin{j},'autoquit')
        autoquit = 1;
    elseif strcmp(varargin{j},'new')
        checkforrestart = 0;
    elseif strcmp(varargin{j},'verbose')
        if length(varargin) > j && isnumeric(varargin{j+1})
            j = j+1;
            DATA.verbose = varargin{j};
        elseif exist('DATA','var')
            DATA.verbose = ones(size(DATA.verbose));
        else
            verbose = 1;
        end
        DATA.frombinocfid = fopen('/local/frombinoc.txt','a');
    elseif strcmp(varargin{j},'monitor')
        DATA.frombinocfid = fopen('/local/frombinoc.txt','a');
        DATA.perfmonitor = 1;

    end
    j = j+1;
end
if setdata
            set(it,'UserData',DATA);
end


it = findobj('Tag',TOPTAG,'type','figure');
if isempty(it)
    tt = TimeMark([], 'Start');
    DATA.tag.top = 'vergwindow';
    ts = now; 
    DATA = SetDefaults(DATA);
    DATA.name = strrep(DATA.vergversion,'verg.','Verg Ver ');

%open pipes to binoc 
% if a file is named in teh command line, then take all setting from there.
% Otherwise read from binoc
    if length(varargin) && exist(varargin{1},'file')
        DATA = OpenPipes(DATA, 0);
        if DATA.togglecodesreceived == 0
            cprintf('red','Binoclean did not send Toggle Codes\n');
        end
        tt = TimeMark(tt, 'Pipes');
        DATA.stimfilename = varargin{1};
        SendState(DATA); %params loaded from verg.setup, binoc.setup etc
        DATA = ReadStimFile(DATA, '/local/verg.setup'); %make sure these go to binoc
        DATA = ReadStimFile(DATA,varargin{1}, 'init');
        SendCode(DATA,'vve'); %send verg version
        tt = TimeMark(tt, 'Read');
        DATA.rptexpts = 0;  %can't set this in startup files, only quickmenus
        if exist(DATA.binoc{1}.lo,'file')
            DATA = ReadLogFile(DATA, DATA.binoc{1}.lo);
        end
        if checkforrestart
            DATA = LoadLastSettings(DATA,'interactive');
        end
        fprintf(DATA.outid,'QueryState\n');
        DATA = ReadFromBinoc(DATA);
        tt = TimeMark(tt, 'FromBinoc');

        j = 2;
        while j <= length(varargin)
            if ischar(varargin{j})
                fprintf(DATA.outid,'%s\n',varargin{j});
            end
            j = j+1;
        end
    else
        DATA = ReadVergFile(DATA, DATA.layoutfile);
        DATA = OpenPipes(DATA, 1);
        DATA.nexpts = 1;
        DATA.Expts{1} = ExptSummary(DATA);
    end
    
    DATA = InitInterface(DATA);
    tt = TimeMark(tt, 'Interface');
    CheckForUpdate(DATA);
    DATA = SetExptMenus(DATA);
    SetGui(DATA);
    tt = TimeMark(tt, 'Reset Interface');
    cmdfile = ['/local/' DATA.binoc{1}.monkey '/binoccmdhistory'];
    DATA.oldcmds = scanlines(cmdfile);
    id = strncmp('Cancel',DATA.oldcmds,5);
    xid = find(strncmp('Reopen',DATA.oldcmds,5));
    if ~isempty(xid)
        lastopenstr = strrep(DATA.oldcmds{xid(end)},'Reopened ','');
    else
        lastopenstr = 'No date';
    end
    id(xid) =1;
    xid = find(strncmp('?',DATA.oldcmds,1));
    id(xid) =1;
    DATA.oldcmds = DATA.oldcmds(~id);
    DATA.oldcmds{end+1} = sprintf('History from file (%s)',lastopenstr);
    
    DATA.cmdfid = fopen(cmdfile,'a');
    myprintf(DATA.cmdfid,'Reopened %s\n',datestr(now));
    set(DATA.toplevel,'UserData',DATA);
    if DATA.frombinocfid > 0
        TimeMark(tt,2);
    end
    DATA = CheckStateAtStart(DATA);
else
    DATA = get(it,'UserData');
end
end

%here parse varargin that require DATA to have been read
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{1},'close',5)
        if DATA.pipelog
            system([GetFilePath('perl') '/pipelog end']);
        end
        if isfield(DATA,'timerobj') & isvalid(DATA.timerobj)
            stop(DATA.timerobj);
        end
        for j = 2:length(DATA.windownames)
            CloseTag(DATA.windownames{j});
        end
        CloseTag(DATA.windownames{1});
        return;
    elseif strncmpi(varargin{j},'quick',5)
        j = j+1;
        DATA = ReadStimFile(DATA, varargin{j},'quickmenu');
        DATA = AddTextToGui(DATA, ['qe=' varargin{j}]);
        SetGui(DATA);
        DATA.optionflags.afc;
        set(DATA.toplevel,'UserData',DATA);
    elseif strcmp(varargin{j},'autoreopen')
        DATA.autoreopen = 1;
        set(DATA.toplevel,'UserData',DATA);
    elseif strcmp(varargin{j},'checkstart')
        DATA = CheckStateAtStart(DATA);
    end
    j = j+1;
end


if autoquit
    close(DATA.toplevel);
end


function binocprintf(DATA, varargin)
%call fprintf, but only if pipe is open    
    if DATA.outid > 0
        fprintf(DATA.outid, varargin{:});
    end
        

function DATA = CheckStateAtStart(DATA)
    if strcmp('NotSet',DATA.binoc{1}.ereset)
        str = 'You Can define A "reset" stimfile that is Run before loading each new Expt. Put ereset=path in verg.setup or your stimfile';
        msgbox(str);
    end
    if DATA.verbose(4)
    for j = 1:length(DATA.comcodes)
       if ~isfield(DATA.helpstrs,DATA.comcodes(j).code) 
           if ~strcmp('xx',DATA.comcodes(j).code)
               fprintf('No help for %s\n',DATA.comcodes(j).code);
           end
       end
    end
    end
    
function [DATA, codetype] = InterpretLine(DATA, line, varargin)

    
    
setlist = 0;  %% don't update gui for every line read.
codetype = 0;
frombinoc = 0;
sendtobinoc =0;
src = 'unknown';
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'from',4)
        src = varargin{j};
    elseif strncmpi(varargin{j},'tobinoc',4)
        sendtobinoc = 1;
    end
    j = j+1;
end
    
if nargin < 2 || isempty(line)
        return;
end
strs = textscan(line,'%s','delimiter','\n');

if DATA.verbose(1) && length(strs{1}) > 1
    fprintf('Reading %d lines\n',length(strs{1}));
end

for j = 1:length(strs{1})
 %   fprintf('%s\n', strs{1}{j});
    s = regexprep(strs{1}{j},'\s+\#.*$','');
    eid = strfind(s,'=');
    if ~isempty(eid)
        code = s(1:eid(1)-1);
        value = s(eid(1)+1:end);
    else
        code = s;
    end
    if DATA.verbose(2) && strcmp(src,'frombinoc')
            fprintf('%s**\n',strs{1}{j});
    end
    if sendtobinoc && DATA.outid > 0
        tline = CheckLineForBinoc(strs{1}{j});
        fprintf(DATA.outid,'%s\n',tline);
    end
    
    if strcmp(src,'fromstim') %Check for some old strings and update
        if strcmp(s,'immode=preload')
            fprintf('Substituting imload for immode');
            s = 'imload=preload';
        end
    end
    if length(s) == 0
    elseif strncmp(s,'!mat',4) && ~isempty(value)
        DATA.matexpres = [];
        if strcmp(src,'fromstim')
            DATA.matexpt = value;
            if strncmp(s,'!matnow',7)
                eval(value);                
            end
        else
            fprintf('Calling %s from %d\n',value,src); 
            DATA.matexpres = eval(value);
            DATA.matlabwasrun = 1;
        end
        SendCode(DATA, 'exp');
    elseif strncmp(s,'NewBinoc',7)
        if DATA.optionflags.do
            fprintf(DATA.outid,'\\go\n');
        end
    elseif strncmp(s,'ACK:',4)
%        t = regexprep(s(5:end),'([^''])''','$1'''''); %relace ' with '' for matlab
        msgbox(s(5:end),'Binoc Warning','warn');
    elseif strncmp(s,'confirm',7)
        yn = questdlg(s(8:end),'Update Check');
        if strcmp(yn,'Yes')
            fprintf('Confirm Yes\n');
            fprintf(DATA.outid,'confirmpopup=1\n');
        end
    elseif s(1) == '#' %defines stim code/label
        [a,b] = sscanf(s,'#%d %s');
%        a = a(1);
%        id = find(s == ' ');
%        DATA.comcodes(a).code = s(id(1)+1:id(2)-1);
%        DATA.comcodes(a).label = s(id(2)+1:end);
%        DATA.comcodes(a).const = a;
    elseif strncmp(s,'exvals',6)
        sv = sscanf(s(8:end),'%f');
        DATA.Trial.sv(1:length(sv)) = sv;
    elseif strncmp(s,'fontsiz',6)
        DATA.font.FontSize = str2double(value);
    elseif strncmp(s,'fontname',6)
        DATA.font.FontName = value;
    elseif strncmp(s,'layout',6)
        DATA.layoutfile = value;
    elseif strncmp(s,'localmatdir',6)
        DATA.localmatdir=value;
    elseif strncmp(s,'netmatdir',6)
        DATA.netmatdir=value;
    elseif strncmp(s,'oldelectrode=',10)
        estr = s(eid(1)+1:end);
        eid = find(strcmp(estr,DATA.electrodestrings));
        if isempty(eid)
            DATA.electrodestrings = {DATA.electrodestrings{:} deblank(estr)};
            DATA.electrodeid = length(DATA.electrodestrings);
        else
            DATA.electrodeid = eid(1);
        end
        DATA.binoc{1}.Electrode = estr;
        
    elseif strncmp(s,'read',4) %read a set of instructions
        fid = fopen(value,'r');
    elseif strncmp(s,'user',4)
        estr = s(eid(1)+1:end);
        DATA.userstrings = {DATA.userstrings{:} estr};
    elseif strncmp(s,'layout',6)
        DATA.layoutfile = value;
    elseif strncmp(s,'TOGGLEEND',9)
        DATA = CheckToggleCodes(DATA);
    elseif strncmp(s,'TOGGLE',6)
        id = strfind(s,' ');
        cc = s(id(1)+1:id(2)-1);
        if ~isfield(DATA.optionflags,cc)
            DATA.optionflags.(cc) = 0;
        end
        DATA.optionstrings.(cc) = s(id(2)+1:end);
        DATA.togglecodesreceived = DATA.togglecodesreceived+1;
    elseif strncmp(s,'pause',5)
        DATA.readpause = str2num(value);
 %       pause(DATA.readpause);
        DATA.pausetime = now;
    elseif strncmp(s,'rptexpts',6)
        DATA.rptexpts = sscanf(value,'%d');
    elseif strncmp(s,'STIMTYPE',6)
        id = strfind(s,' ');
        code = str2num(s(id(1)+1:id(2)-1))+1;
        DATA.stimulusnames{code} = s(id(2)+1:end);
    elseif strncmp(s,'SCODE',5)
        id = strfind(s,' ');
        icode = str2num(s(id(2)+1:id(3)-1))+1;
        label = s(id(3)+1:end);
        code = s(id(1)+1:id(2)-1);
        sid = strmatch(code,{DATA.strcodes.code},'exact');
        if isempty(sid)
            sid = length(DATA.strcodes)+1;
        end
        DATA.strcodes(sid).label = label;
        DATA.strcodes(sid).icode = icode;
        DATA.strcodes(sid).code = code;
    elseif strncmp(s,'CODE OVER',8)
        for j = 1:length(DATA.comcodes)
            if isempty(DATA.comcodes(j).code)
                DATA.comcodes(j).code = 'xx';
                DATA.comcodes(j).label = '';
                DATA.comcodes(j).const = NaN;
                DATA.comcodes(j).type = 'N';
                DATA.comcodes(j).group = 512+2048;
            else
               if ~isfield(DATA.helpstrs,code) && DATA.verbose(1)
                   fprintf('No help for %s\n',code);
               end
            end
        end
    elseif strncmp(s,'CODE',4)
        id = strfind(s,' ');
        code = str2num(s(id(2)+1:id(3)-1))+1;
        if ismember(code,[DATA.comcodes.code])
           x = 1; 
        end
        str = s(id(1)+1:id(2)-1);
        if ~strcmp(str,'xx') && sum(strcmp(str,{DATA.comcodes.code}))
            x = strcmp(str,{DATA.comcodes.code});
        end
       
        DATA.comcodes(code).label = s(id(3)+1:id(end)-2);
        DATA.comcodes(code).code = s(id(1)+1:id(2)-1);
        DATA.comcodes(code).const = code;
        DATA.comcodes(code).type = s(id(end)-1);
        DATA.comcodes(code).group = str2num(s(id(end)+1:end));
        try
        DATA.codeids.(DATA.comcodes(code).code) = code; %index of codes
        catch
            fprintf('Invalid field name %s\n',str);
        DATA.codeids.xx = code; %index of codes
        DATA.comcodes(code).code = 'xx';
        end
    elseif strncmp(s,'cwd=',4)
        DATA.cwd = value;
    elseif strncmp(s,'status',5)
        DATA.Statuslines{end+1} = s(8:end);
        if ishandle(DATA.statusitem)
            set(DATA.statusitem,'string',DATA.Statuslines,'listboxtop',length(DATA.Statuslines));
        end
        if DATA.inexpt == 0 && isfield(DATA,'toplevel')
            set(DATA.toplevel,'Name',s(8:end));
        end
        if strncmp(s,'status=Grid is',14)
            DATA = AddTextToGui(DATA,s(8:end));
        end
        fid = strfind(s,'Frames:');
        if ~isempty(fid) && ~isempty(DATA.Trials)
            nf = sscanf(s(fid(1)+8:end),'%d');
            DATA.Trials(length(DATA.Trials)).nf = nf;
        end
%        fprintf(s);
    elseif strncmp(s,'exps',4)
        ex = 1;
        DATA.expts{ex} = [];
        pid = strfind(s,'+');
        for k = 1:length(pid)
            if k == length(pid)
                x = s(pid(k)+1:end);
            else
                x = s(pid(k)+1:pid(k+1)-1);
            end
            if length(x) > 1
            eid = strmatch(x,{DATA.comcodes.code},'exact');
            DATA.expts{ex} = [DATA.expts{ex} eid];
            end
        end
        ex = 1;
            
    elseif strncmp(s,'EXPTSTART',8)
        DATA.inexpt = 1;
        tic; PsychMenu(DATA); 
        tic; SetGui(DATA,'set'); 
    elseif strncmp(s,'EXPTOVER',8) %called at end or cancel
        if DATA.inexpt %in case reopen pipes mied expt
            DATA.optionflags.do = 0;
        end
        DATA.inexpt = 0;
        DATA.matlabwasrun = 0;
        if DATA.nexpts > 0  %may be 0 here if verg is fired up after a crash
        DATA.Expts{DATA.nexpts}.End = now;
        DATA.Expts{DATA.nexpts}.last = length(DATA.Trials);
        end
%        tic; DATA = GetState(DATA); toc  %binoc sends state at end expt,
%        before sending ExptOver
        tic; PsychMenu(DATA); 
        tic; SetGui(DATA,'set'); 
        ShowStatus(DATA);
        if DATA.exptstoppedbyuser  
        %if user hist cancal/stop, dont repeat or move on to automatic next expt
            DATA.exptstoppedbyuser = 0;
            DATA.seqline = 0;
        elseif DATA.seqline > 0
            myprintf(DATA.cmdfid,'Sequence continuing from line %d',DATA.seqline);
            DATA = ContinueSequence(DATA);
        elseif DATA.exptnextline > 0
            DATA = ReadExptLines(DATA,{},'fromseq');
            DATA = RunButton(DATA,[],1);
        elseif DATA.rptexpts > 0
            outprintf(DATA,'#Nrpt is %d\n',DATA.rptexpts);
            DATA.rptexpts = DATA.rptexpts-1;
            it = findobj(DATA.toplevel,'Tag','RptExpts');
            set(it,'string',num2str(DATA.rptexpts));
            uipause(now, DATA.binoc{1}.seqpause, 'Fixed Delay for repeats');
            DATA = RunButton(DATA,[],1);
        end
    elseif strncmp(s,'Expts1',6)
        DATA.extypes{1} = sscanf(s(8:end),'%d');
        DATA.extypes{1} = DATA.extypes{1}+1;
        DATA = SetExptMenus(DATA);
    elseif strncmp(s,'Expts2',6)
        DATA.extypes{2} = sscanf(s(8:end),'%d');
        DATA.extypes{2} = DATA.extypes{2}+1;
        DATA = SetExptMenus(DATA);
    elseif strncmp(s,'Expts3',6)
        DATA.extypes{3} = sscanf(s(8:end),'%d');
        DATA.extypes{3} = DATA.extypes{3}+1;
        DATA = SetExptMenus(DATA);
    elseif strncmp(s,'expt',4)
        DATA = ReadStimFile(DATA, value, 'inread');
    elseif strncmp(s,'TESTOVER',8)
       if isfield(DATA,'reopenstr') && ~isempty(DATA.reopenstr) && DATA.optionflags.do
           binocprintf(DATA,'%s\n',DATA.reopenstr);
       end

    elseif strncmp(s,'TRES',4)
        if s(6) == 'G' || s(6) == 'W'
            a = sscanf(s(7:end),'%d');
        else
            a = 0;
        end
        if(s(6) == 'G' || s(6) == 'F')
            DATA.Trial.good = 1;
        elseif(s(6) == 'W')
            DATA.Trial.good = -1;
        else
            DATA.Trial.good = 0;
        end
        DATA.Trial.rw = DATA.binoc{1}.rw;
        DATA.Trial.RespDir = a(1);
        if length(a) > 1
            DATA.Trial.tr = a(2);
        end
        DATA = SetTrial(DATA, DATA.Trial);
        DATA.nt = DATA.nt+1;
        DATA.Trial.Trial = DATA.nt;
        id = findstr(s,' ');
        if length(id) > 1
            DATA.Trial.id = sscanf(s(id(2)+1:end),'%d');
        end
        if DATA.verbose(3)
            fprintf('%s t%dR%d Ex%s\n',s,DATA.nt,DATA.Trial.RespDir,sprintf(' %.3f',DATA.Trial.sv));
        end
        if isfield(DATA.Trial,'RespDir')
            DATA = PlotPsych(DATA);
        end
    elseif length(code) > 4 & strmatch(code,DATA.windownames,'exact')
        iw = strmatch(code,DATA.windownames);
        DATA.winpos{iw} = sscanf(value,'%d');
    elseif strncmp(s,'winpos=',7)
        DATA.winpos{1} = sscanf(s(8:end),'%d');
    elseif strncmp(s,'optionwinpos=',10)
        DATA.winpos{2} = sscanf(s(eid(1)+1:end),'%d');
    elseif strncmp(s,'softoffwinpos=',10)
        DATA.winpos{3} = sscanf(s(eid(1)+1:end),'%d');
    elseif strncmp(s,'penlogwinpos=',10)
        DATA.winpos{4} = sscanf(s(eid(1)+1:end),'%d');

    elseif strncmp(s,'STIMC ',6)
        DATA.trialcounts = sscanf(s(7:end),'%f');
        if length(DATA.trialcounts) < 8
            DATA.trialcounts(8) = 0;
        end     
        ShowStatus(DATA);
    elseif strncmp(s,'mo=fore',7)
        DATA.currentstim = 1;
    elseif strncmp(s,'mo=back',7)
        DATA.currentstim = 2;
    elseif strncmp(s,'mo=ChoiceU',10)
        DATA.currentstim = 3;
    elseif strncmp(s,'mo=ChoiceD',10)
        DATA.currentstim = 4;
    elseif strncmp(s,'over',4)
        DATA.over = 1;
    elseif strncmp(s,'pf=',3)
        s = strrep(s,'+2a','+afc');
        if s(end) == ':'
            s = s(1:end-1);
        end
        s = [s '+'];
        id = regexp(s,'[+-]');
        xid = strfind(s,':');
        id = union(id,xid);
        f = fields(DATA.optionflags);
        stimf = fields(DATA.stimflags{1});
        nflag = 1;
        if strncmp(s,'pf=0',4) %% reset list, rather than add
            DATA.showflagseq = {};
            nflag = 1;
        else
            nflag = length(DATA.showflagseq)+1;
        end
        codetype = 1;
        for k= 1:length(id)-1
            newcode = s(id(k)+1:id(k+1)-1);
            code = find(strcmp(newcode,f));
            isshown = sum(strcmp(newcode,DATA.showflagseq));
            if s(id(k)) == ':'
                codetype = 2;
            elseif codetype == 2 %need to look for these in stimglags
                code = strmatch(newcode,stimf);
            elseif id(k+1) < id(k)+2
                fprintf('Code too short %s\n',s(id(k):end));
            elseif isempty(code) && DATA.togglecodesreceived == 0
                DATA.showflags.(newcode) = 1;
                if ~isshown
                    DATA.showflagseq{nflag} = newcode;
                    nflag = nflag+1;
                end
                if DATA.togglecodesreceived
                fprintf('No Code for %s\n,',s(id(k):end));
                end
            elseif isempty(code)
%                fprintf('No Code for %s\n,',s(id(k):end));                
            elseif s(id(k)) == '+' && id(k+1)
                DATA.showflags.(f{code}) = 1;
                if ~isshown
               DATA.showflagseq{nflag} = f{code};
               nflag = nflag+1;
                end
            else
                if ~isempty(code)
                    DATA.showflags.(f{code}) = 0;
                end
            end
        end
        DATA.binoc{1}.pf = ShowFlagString(DATA);
    elseif strncmp(s,'helpfile=',9)
        s = s(10:end);
        id = strfind(s,'"');
        if ~isempty(id)
            n = [];
            lbl = s(2:id(end)-1);
            if isfield(DATA.helpfiles,'label')
            n = find(strcmp(lbl,{DATA.helpfiles.label}));
            end
            if isempty(n)
                n = length(DATA.helpfiles)+1;
            end
            DATA.helpfiles(n).filename = s(id(end)+1:end);
            DATA.helpfiles(n).label = s(2:id(end)-1);
        end
    elseif strncmp(s,'xyfsd',5)
        x = sscanf(value,'%f');
        DATA.binoc{1}.xyfsd = x(1);
        if length(x) == 4
            DATA.showxy = x(2:4);
        end
    elseif strncmp(s,'qe=',3)
        
        id = strfind(s,'"');
        if length(id) > 1
            submenu = s(id(1)+1:id(2)-1);
            s = s(id(end)+1:end);
        else
            submenu = '';
        s = s(4:end);
        end
        [a,b,c] = fileparts(s);
        b = [b c];
        id = [];
        if isfield(DATA.quickexpts,'filename') %check we don't alreayd have this
        id = find(strcmp(s,{DATA.quickexpts.filename}));
        end
        if isempty(id)
        n = length(DATA.quickexpts)+1;
        DATA.quickexpts(n).name = b;
        DATA.quickexpts(n).filename = s;
        DATA.quickexpts(n).submenu = submenu;
        end
    elseif strncmp(s,'et',2)
        DATA.exptype{1} = sscanf(s,'et=%s');
        DATA.binoc{1}.(code) = value;
    elseif strncmp(s,'e2',2)
        DATA.exptype{2} = sscanf(s,'e2=%s');
        DATA.binoc{1}.(code) = value;
    elseif strncmp(s,'e3',2)
        DATA.exptype{3} = sscanf(s,'e3=%s');
        DATA.binoc{1}.(code) = value;
    elseif strncmp(s,'nt=',3)
        DATA.nstim(1) = sscanf(s,'nt=%d');
        DATA.binoc{1}.(code) = str2num(value);
    elseif strncmp(s,'n2',2)
        DATA.nstim(2) = sscanf(s,'n2=%d');
        DATA.binoc{1}.(code) = str2num(value);
    elseif strncmp(s,'n3',2)
        DATA.nstim(3) = sscanf(s,'n3=%d');
        DATA.binoc{1}.(code) = str2num(value);
    elseif sum(strncmp(s,{'ei' 'i2' 'i3'},2)) %store incremenest in verg as strings. Then can have "lin/log"
        DATA.binoc{1}.(code) = value;
    elseif strncmp(s,'em',2)
        DATA.mean(1) = ReadVal(s,DATA);
        DATA.binoc{1}.em = DATA.mean(1);
    elseif strncmp(s,'m2',2)
        DATA.mean(2) = ReadVal(s,DATA);
        DATA.binoc{1}.m2 = DATA.mean(2);
    elseif strncmp(s,'m3',2)
        DATA.mean(3) = ReadVal(s,DATA);
        DATA.binoc{1}.m3 = DATA.mean(3);
    elseif strncmp(s,'uf=',3)
        DATA.datafile = s(4:end);
        DATA.binocstr.uf = DATA.datafile;
        DATA.binoc{1}.uf = DATA.datafile;
    elseif strncmp(s,'op',2)
        f = fields(DATA.optionflags);
        if strncmp(s,'op=0',4) %everything else off
            for k = 1:length(f) DATA.optionflags.(f{k}) = 0; end
        end
        s = strrep(s,'+2a','+afc');
        s = strrep(s,'-2a','-afc');
        s = [s '+'];
        id = regexp(s,'[+-]');
        
        for k = 1:length(id)-1
            code = strmatch(s(id(k)+1:id(k+1)-1),DATA.badnames);
            if length(code) == 1
                code = strmatch(DATA.badreplacenames{code},f);
            else
                code = find(strncmp(s(id(k)+1:id(k+1)-1),f,id(k+1)-id(k)-1));
                for j = 1:length(code)
                    if length(f{code(j)}) == id(k+1)-id(k)-1
                        code = code(j);
                        break;
                    end
                end
            end
            
            if isempty(code)
                fprintf('No Code for %s\n,',s(id(k):end-1));
            elseif s(id(k)) == '+'
            DATA.optionflags.(f{code}) = 1;
            else
            DATA.optionflags.(f{code}) = 0;
            end
        end
    elseif strncmp(s,'ch10',4) %Right eye XY
        DATA.showxy(1) = strfind('-+',s(5))-1;
        id = strfind(s,'fs');
        if length(id) == 1
            DATA.binoc{1}.xyfsd = sscanf(s(id(1)+2:end),'%f');
        end
    elseif strncmp(s,'ch11',4) %L eye XY
        DATA.showxy(2) = strfind('-+',s(5))-1;
    elseif strncmp(s,'ch12',4) %binoc XY
        DATA.showxy(3) = strfind('-+',s(5))-1;
    elseif regexp(s,'^ch[0-9]')
    elseif strncmp(s, 'stepperxy', 8)
    elseif strncmp(s, 'penwinxy', 8)
    elseif strncmp(s, 'optionwinxy', 8)
    elseif strncmp(s, 'slider', 6)
        id = strmatch(s(4:end),DATA.stimulusnames,'exact');

    elseif strncmp(s, 'st', 2)
        id = strmatch(deblank(s(4:end)),DATA.stimulusnames,'exact');
        if length(id) == 1
        DATA.stimtype(DATA.currentstim) = id;
        DATA.binocstr.st = deblank(s(4:end));
        DATA.binoc{DATA.currentstim}.st = deblank(s(4:end));
        end
    elseif sum(strcmp(code,{DATA.strcodes.code}))
        id = strfind(s,'=');
        if id
            sid = find(strcmp(code,{DATA.strcodes.code}));
            if isempty(sid)
                DATA.binocstr.(code)=s(id(1)+1:end);
            else
                DATA.binocstr.(DATA.strcodes(sid).code)=s(id(1)+1:end);
            end
        end
    elseif strncmp(s, 'Bs', 2)
             DATA.stimtype(2) = strmatch(s(4:end),DATA.stimulusnames,'exact');
             DATA.binoc{1}.Bs = DATA.stimulusnames{DATA.stimtype(2)};
    elseif strncmp(s, 'EDONE', 5) %finished listing expt stims
        if isfield(DATA,'toplevel')
            it = findobj(DATA.toplevel,'Tag','Expt3StimList','style','edit');
            if length(it) == 1
                set(it,'string',DATA.exptstimlist{3});
            end
            it = findobj(DATA.toplevel,'Tag','Expt2StimList','style','edit');
            if length(it) == 1
                ival = get(it,'value');
                ival = min([size(DATA.exptstimlist{2},2) ival]);
                if ival <1
                    ival = 1;
                end
                set(it,'string',DATA.exptstimlist{2},'value',ival);
            end
            
            it = findobj(DATA.toplevel,'Tag','Expt1StimList','style','edit');
            if length(it) == 1
                set(it,'string',DATA.exptstimlist{1});
            end
        end
        if isfield(DATA,'exptstimlist')
            for j = 1:length(DATA.exptstimlist)
                S = DATA.exptstimlist{j};
                for m = 1:length(S)
                    [val,n] = sscanf(S{m},'%f');
                    if n == 1
                        DATA.expvals{j}(m) = val;
                    end
                end
                
            end
        end
    elseif strncmp(s,'Unrecog',7)
        if DATA.verbose(4)
            fprintf('%s\n',s);
        end
        DATA.Statuslines{end+1} = s(8:end);
    elseif sum(strcmp(code,{DATA.comcodes.code}))
        cid = find(strcmp(code,{DATA.comcodes.code}));
        code = DATA.comcodes(cid(1)).code;
        id = strfind(s,'=');
        if id
%some variables are numeric internally, but best recorded via the matching code        
            if sum(strcmp(code,{'hxtype'}))
                vtype = 'C';
            else
                vtype = DATA.comcodes(cid(1)).type;
            end
            if  vtype == 'C'
                DATA.binoc{DATA.currentstim}.(code) = s(id(1)+1:end);
            else
                val = sscanf(s(id(1)+1:end),'%f');
                DATA.binoc{DATA.currentstim}.(code) = val;
            end
            codetype = DATA.comcodes(cid(1)).group;
            DATA = SetCode(DATA,code);
        end    
    elseif regexp(s,'^E[A-C][0-9,\-,C]') %don't let this catch other codes starting with E
        if strncmp(s,'EBCLEAR',5)
            DATA.exptstimlist{2} = {};
            DATA.nextras(2) = 0;
            DATA = CheckCustomStim(DATA,s,2);
        elseif strncmp(s,'ECCLEAR',5)
            DATA.exptstimlist{3} = {};
            DATA.nextras(3) = 0;
            DATA = CheckCustomStim(DATA,s,3);
        elseif strncmp(s,'EACLEAR',5)
            DATA.exptstimlist{1} = {};
            DATA.nextras(1) = 0;
            DATA = CheckCustomStim(DATA,s,1);
        elseif s(2) == 'C'
            n = sscanf(s(3:end),'%d');
            id = findstr(s,'=');
            if length(n)
                DATA.exptstimlist{3}{n(1)+1} = s(id(1)+1:end);
                if isfield(DATA,'toplevel')  && setlist
                    it = findobj(DATA.toplevel,'Tag','Expt3StimList');
                    if length(it) == 1
                        set(it,'string',DATA.exptstimlist{3});
                    end
                end
            end
        elseif s(2) == 'B'
            n = sscanf(s(3:end),'%d');
            id = findstr(s,'=');
            if length(n)
                DATA.exptstimlist{2}{n(1)+1} = s(id(1)+1:end);
                if isfield(DATA,'toplevel') && setlist
                    it = findobj(DATA.toplevel,'Tag','Expt2StimList','style','edit');
                    if length(it) == 1
                        ival = get(it,'value');
                        ival = min([size(DATA.exptstimlist{2},2) ival]);
                        set(it,'string',DATA.exptstimlist{2},'value',ival);
                    end
                end
            end
        elseif s(2) == 'A'
            n = sscanf(s(3:end),'%d');
            if n < 0 && isempty(DATA.exptstimlist{1})
                DATA.nextras(1) = abs(n(1));
            end
            id = findstr(s,'=');
            if length(n)
                DATA.exptstimlist{1}{n(1)+1+DATA.nextras(1)} = s(id(1)+1:end);
                if isfield(DATA,'toplevel') && setlist
                    it = findobj(DATA.toplevel,'Tag','Expt1StimList');
                    if length(it) == 1
                        set(it,'string',DATA.exptstimlist{1});
                    end
                end
            end
            if strncmp(s,'EACLEAR',5)
                DATA.exptstimlist{1} = {};
            end
        else
            
        end
    else
        id = strfind(s,'=');
        if id & s(1) ~= '!'
% If we get here, its a command not recognized byt binoc or by lines above.
%In general, Do NOT add these to binoc{1} - it allows the user to create
%abritrary fields there accidentally. Put then in binoc{5} (not send to binoc)
%However, catch codes that might be
%set in verg.setup before binoc has been started. 
            code = s(1:id(1)-1);
            code = strrep(code, 'electrode','Electrode');
            if isempty(strmatch(code, {'1t' '2t' '3t' '4t'})) %illegal names
                if sum(strcmp(code,{'ereset'}))
                    bid = DATA.currentstim;
                else
                    bid = 5;
                end
                code = deblank(code);
                val = sscanf(s(id(1)+1:end),'%f');
                if ~isempty(val)
                    DATA.binoc{bid}.(code) = val;
                else
                    DATA.binoc{bid}.(code) = s(id(1)+1:end);
                end
                SetCode(DATA,code);
            end
        end
    end
end



function DATA = SetCode(DATA,code)
%DATA = SetCode(DATA,val)
% Does additional steps needed for some codes, like 'Electrode'

if DATA.currentstim == 1
val = GetValue(DATA,code);
if strcmp(code,'Electrode')
    id = find(strcmp(val,DATA.electrodestrings));
    if isempty(id)
        DATA.electrodestrings{end+1} = deblank(val);
        DATA.electrodeid = length(DATA.electrodestrings);
    else
        DATA.electrodeid = id;
    end
end
end


function DATA = CheckCustomStim(DATA, s, n)
    if s(end) == '*'
        DATA.customstimlist(n) = 1;
    else
        DATA.customstimlist(n) = 0;
    end
    
function s = AddCustomStim(DATA, s, n)
    
    pre = {'EA' 'EB' 'EC'};
    o = 1+DATA.nextras(n);
    if DATA.customstimlist(n)
        for j = o:length(DATA.exptstimlist{n})
            s = [s sprintf('%s%d=%s\n',pre{n},j-o,DATA.exptstimlist{n}{j})];
        end
    end
    

function [code, codeid] = FindCode(DATA, s)
    code = '';
    codeid = 0;
    id = strfind(s,'=');
    if id
        code = s(1:id(1)-1);
        codeid = strmatch(code,{DATA.comcodes.code});
    else
        id = strmatch(s(1:2),{DATA.comcodes.code});
        codeid = id;
        if length(id) == 1
            code = DATA.comcodes(id).code;
        end
    end
        
function str =  ShowFlagString(DATA)    
    str = 'pf=';
    for j = 1:length(DATA.showflagseq)
        f = DATA.showflagseq{j};
        if DATA.showflags.(f)
            str = [str '+' f];
        end
    end
    
function DATA = CheckToggleCodes(DATA)    
    f = fields(DATA.showflags);
    of = fields(DATA.optionflags);
    
    for j = 1:length(f)
        if sum(strcmp(f{j},of)) == 0
            fprintf('Option %s Not supported\n',f{j});
            DATA.showflags = rmfield(DATA.showflags,f{j});
            id = find(strcmp(f{j},DATA.showflagseq));
            id = setdiff(1:length(DATA.showflagseq),id);
            DATA.showflagseq = DATA.showflagseq(id);
        end
    end

function DATA = ReadExptLines(DATA, strs, src)

    if isempty(strs)
        strs = DATA.explines
        firstline = 1;
    else
        firstline = 1+DATA.exptnextline;
    end

    for j = firstline:length(strs)
        tline = strs{j};
        if strncmp(tline,'next',4)
            DATA.exptnextline = j;
            break;
        end
        [DATA, type] = InterpretLine(DATA,tline, src);
        if DATA.perfmonitor
            myprintf(DATA.frombinocfid,'%s file %s\n',datestr(now),tline);
        end
  %if filename set before monkey, set monkeyname first
        if strncmp(tline,'uf=',3) && strcmp(DATA.binoc{1}.monkey,'none')
            DATA.binoc{1}.monkey = GetMonkeyName(DATA.datafile);
            SendCode(DATA,'monkey');
        end
        if DATA.over
            DATA.overcmds = {DATA.overcmds{:} tline};
        elseif DATA.outid > 0
            tline = CheckLineForBinoc(tline);
            fprintf(DATA.outid,'%s\n',tline);
        end
    end
    if j >= length(DATA.exptlines)
            DATA.exptnextline = 0;
    end
    if DATA.outid > 0
        fprintf(DATA.outid,'\neventcontinue\nEDONE\n');
    end
    DATA = ReadFromBinoc(DATA,'expect');
    for ex = 1:3
        if length(DATA.expts{ex})
            id = find(~ismember(DATA.expmenuvals{ex}, DATA.expts{ex}));
            DATA.expmenuvals{ex} = [DATA.expts{ex} DATA.expmenuvals{ex}(id)];
        end
        DATA = SetExptMenus(DATA);
    end
    
function line = CheckLineForBinoc(tline)
    if strncmp(tline,'op',2)
        tline = strrep(tline,'+2a','+afc');
    end
% more recent Spike2 seems not to need this
%But matlab needs it for writing to serial line
    if strncmp(tline,'uf',2)
%        tline = regexprep(tline,'\\\','\'); %dont go '\\' -> '\\\\'
%        tline = regexprep(tline,'\\','\'); %dont go '\\' -> '\\\\'
%        tline = regexprep(tline,'\','\\');
%beware fprintf('%s',tline) and fprintf(tline) behave differetnly with \\
        tline = regexprep(tline,'/','\\'); %Spike 2 needs \ not /
    else
        tline = regexprep(tline,'\','/');
    end
    tline = regexprep(tline,'\s+\#.*\n','\n'); %remove comments
    line = strrep(tline,'\s+\n','\n');
    
    
    
function DATA = ReadSetupFile(DATA, name, varargin)
fid = fopen(name,'r');
if fid > 0
    tline = fgets(fid);
    while ischar(tline)
        id = strfind(tline,'=');
        value = '';
        if ~isempty(id)
            value = tline(id+1:end);
        end
        if strncmpi(tline,'electrode=',8) && ~isempty(value)
            DATA.electrodestrings{1+length(DATA.electrodestrings)} = deblank(value);
        end
        if strncmp(tline,'tty2=',5) && ~isempty(value)
            DATA.servoport = deblank(value);
        end
        tline = fgets(fid);
    end
    fclose(fid);
end

function DATA = ReadStimFile(DATA, name, varargin)
   
    setall = 0;
    inread = 0;
    src = 'unknown';
    j = 1;
    while j <= length(varargin)
        if strncmpi(varargin{j},'inread',4)
            inread = 1;
        elseif strncmpi(varargin{j},'init',4)
            setall = 1;
        elseif strncmpi(varargin{j},'quickmenu',8)
            src = varargin{j};
        end
        j = j+1;
    end
%if this is the first load since running an expt, Call the reset
%file
if DATA.newexptdef == 0 && isfield(DATA.binoc{1},'ereset') && ~strcmp('NotSet',DATA.binoc{1}.ereset);
    fprintf('Resetting Expt with %s\n',DATA.binoc{1}.ereset);
    DATA.newexptdef = 1;
    DATA = ReadStimFile(DATA, DATA.binoc{1}.ereset);
end
outprintf(DATA,'#qe%s\n',name);

fid = fopen(name,'r');
if fid > 0
    if strcmp(src,'quickmenu') %undo some things whenever load new quick
        DATA.matexpt = []; 
    end
        
            
    if DATA.outid > 0 && inread == 0
        fprintf(DATA.outid,'\neventpause\nnewexpt\n');
    end
    for j = 2:length(DATA.overcmds) %commands to execute at and
            fprintf(DATA.outid,[DATA.overcmds{j} '\n']);
        end
    DATA.over = 0;
    DATA.overcmds = {};
    DATA.exptnextline = 0;
    a = textscan(fid,'%s','delimiter','\n');
    DATA.exptlines = a{1};
    fclose(fid);
    if strcmp(DATA.exptlines{1},'sequence')
        SequencePopup(DATA,DATA.exptlines(2:end),'popup');
    else
        DATA = ReadExptLines(DATA,a{1},'fromstim');
    end
else
    msgbox(sprintf('Can''t read %s',name),'Read Error','error');
end
if setall
    DATA = ReadVergFile(DATA, DATA.layoutfile);
end
DATA.newexptdef = 1;


function DATA = ReadVergFile(DATA, name, varargin)
%Read file htat only affects verg, not binoc (e.g. layout)
%so these lines are not send on to binoc   
    setall = 0;
    j = 1;
    while j <= length(varargin)
        if strncmpi(varargin{j},'init',4)
            setall = 1;
        end
        j = j+1;
    end
        
fid = fopen(name,'r');
if fid > 0
    tline = fgets(fid);
    while ischar(tline)
        DATA = InterpretLine(DATA,tline);
        tline = fgets(fid);
    end
    fclose(fid);
else
    msgbox(sprintf('Can''t read %s',name),'Read Error','error');
end




function SendState(DATA, varargin)

    sendview = 0;
    j = 1;
    while j <= length(varargin)
        if strncmpi(varargin{j},'All',4)
            sendview = 1;
        end
        j = j+1;
    end
    
    f = fields(DATA.binoc{1});
    
    if ~isfield(DATA,'codeids') %not connected to binoc
        return;
    end
    fprintf(DATA.outid,'\neventpause\n');
    
    
    fprintf(DATA.outid,'mo=fore\n');
    if sendview
        SendCode(DATA,{'px' 'py' 'vd'});
    end
    f = fields(DATA.binocstr);
    for j = 1:length(f)
        if length(DATA.binocstr.(f{j})) > 0
            fprintf(DATA.outid,'%s=%s\n',f{j},DATA.binocstr.(f{j}));
        end
    end
    fprintf(DATA.outid,'uf=%s\n',DATA.datafile);
    
    if DATA.showxy(3)
        fprintf(DATA.outid,'ch12+\n'); %R
    end
    if DATA.showxy(2)
        fprintf(DATA.outid,'ch11+\n'); %L
    end
    if DATA.showxy(1)
        fprintf(DATA.outid,'ch10+\n'); %B
    end

    if length(DATA.binoc) > 1 && isstruct(DATA.binoc{2})
    f = fields(DATA.binoc{2});
    fprintf(DATA.outid,'mo=back\n');
    fprintf(DATA.outid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(2)});

    for j = 1:length(f)
        if strmatch(f{j},DATA.redundantcodes,'exact')
        elseif ischar(DATA.binoc{2}.(f{j}))
        fprintf(DATA.outid,'%s=%s\n',f{j},DATA.binoc{2}.(f{j}));
        else
        fprintf(DATA.outid,'%s=%.6f\n',f{j},DATA.binoc{2}.(f{j}));
        end
    end
    end
    SendChoiceTargets(DATA.outid,DATA);
    fprintf(DATA.outid,'mo=fore\n');
    fprintf(DATA.outid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(1)});
    f = fields(DATA.binoc{1});
    for j = 1:length(f)
        if isfield(DATA.codeids,f{j})
            cid = DATA.codeids.(f{j});
        else
            cid = 1; 
        end
        if DATA.comcodes(cid).group > 511
            fprintf('Not sending %s\n',f{j});
        elseif strmatch(f{j},DATA.redundantcodes,'exact')
            fprintf('Not sending %s\n',f{j});
        elseif ischar(DATA.binoc{1}.(f{j}))
        fprintf(DATA.outid,'%s=%s\n',f{j},DATA.binoc{1}.(f{j}));
        else
        fprintf(DATA.outid,'%s=%s\n',f{j},sprintf('%.6f ',DATA.binoc{1}.(f{j})));
        end
    end
    fprintf(DATA.outid,'clearquick\n');
    for j = 1:length(DATA.quickexpts)
        if length(DATA.quickexpts(j).submenu)
            fprintf(DATA.outid,'qe="%s"%s\n',DATA.quickexpts(j).submenu,DATA.quickexpts(j).filename);
        else
            fprintf(DATA.outid,'qe=%s\n',DATA.quickexpts(j).filename);
        end
    end
    SendCode(DATA,'vve');
    SendCode(DATA,'optionflag');
    SendCode(DATA,'expts');
    if DATA.electrodeid > 0
        fprintf(DATA.outid,'Electrode=%s\n',DATA.electrodestrings{DATA.electrodeid});
    end
    
    fprintf(DATA.outid,'\neventcontinue\n');

    
function SendChoiceTargets(fid, DATA)
    if length(DATA.stimtype) < 3
        return;
    end
    if DATA.stimtype(3)
        fprintf(fid,'mo=ChoiceU\n');
        fprintf(fid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(3)});
        f = fields(DATA.binoc{3});
        for j = 1:length(f)
            [s, lbl] = CodeText(DATA, f{j},'ChoiceU');
            fprintf(fid,'%s\t#ChoiceU %s\n',s,lbl);
        end
%        StimToggleString(DATA,3);
    end
    if DATA.stimtype(4)
        fprintf(fid,'mo=ChoiceD\n');
        fprintf(fid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(4)});
        f = fields(DATA.binoc{4});
        for j = 1:length(f)
            [s, lbl] = CodeText(DATA, f{j},'ChoiceD');
            fprintf(fid,'%s\t#ChoiceD %s\n',s,lbl);
        end
 %       StimToggleString(DATA,3);
    end
    

function SaveExpt(DATA, name)
    bname = name;
    if strfind(name, '.stm')
        bname = strrep(name,'.stm','.bstm');
    else
        bname = [name '.bstm'];
    end
    if DATA.outid
    fprintf(DATA.outid,'\\savefile=%s\n',bname);
    end
    fid = fopen(name,'w');

    fprintf(fid,'mo=fore\n');
    fprintf(fid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(1)});
    fprintf(fid,'%s\n',CodeText(DATA, 'expts'));
    fprintf(fid,'%s\n',CodeText(DATA, 'nr'));
    fprintf(fid,'uf=%s\n',DATA.datafile);
    
    fprintf(fid,'mo=back\n');
    fprintf(fid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(2)});
    f = fields(DATA.binoc{2});
    for j = 1:length(f)
        [s, lbl] = CodeText(DATA, f{j},'back');
        fprintf(fid,'%s\t#Back %s\n',s,lbl);
    end
    SendChoiceTargets(fid, DATA);
    fprintf(fid,'mo=fore\n');
    fprintf(fid,'st=%s\n',DATA.stimulusnames{DATA.stimtype(1)});
    f = fields(DATA.binoc{1});
    for j = 1:length(f)
        [s, lbl, type] = CodeText(DATA, f{j});
        if bitand(type, 512) == 0
            fprintf(fid,'%s\t#%s\n',s,lbl);
        end
    end
    f = fields(DATA.binocstr);
    for j = 1:length(f)
        id = find(strcmp(f{j},{DATA.comcodes.code}));
        if length(id) == 1
            fprintf(fid,'%s=%s\t#%s\n', f{j}, DATA.binocstr.(f{j}),DATA.comcodes(id).label);
        else
            fprintf(fid,'#Error writing %s\n',f{j});
        end
    end
    fprintf(fid,'%s\n',CodeText(DATA, 'optionflag'));
    fprintf(fid,'%s\n',CodeText(DATA, 'pf'));
    for j = 1:length(DATA.quickexpts)
        if isempty(DATA.quickexpts(j).submenu)
        fprintf(fid,'qe=%s\n',DATA.quickexpts(j).filename);
        else
        fprintf(fid,'qe="%s"%s\n',DATA.quickexpts(j).submenu,DATA.quickexpts(j).filename);
        end
    end
    for j = 1:length(DATA.helpfiles)
        fprintf(fid,'helpfile="%s"%s\n',DATA.helpfiles(j).label,DATA.helpfiles(j).filename);
    end
    fclose(fid);
    fprintf('Saved %s\n',name);

function DATA = OpenPipes(DATA, readflag)
        
DATA.outpipe = '/tmp/binocinputpipe';
DATA.inpipe = '/tmp/binocoutputpipe';

if DATA.outid > 0
    fclose(DATA.outid);
end
if DATA.inid > 0
    fclose(DATA.inid);
end

[a, pstr] = system('ps -e | grep binoclean');
if isempty(strfind(pstr, 'binoclean.app'))
    msgbox('Binoc is Not Runnig');
    binocisrunning = 0;
else
    binocisrunning = 1;    
end
if exist(DATA.outpipe)  && binocisrunning
%if binoc crashed out leaving pipes behind, this will freeze.    
    DATA.outid = fopen(DATA.outpipe,'w');
else
    DATA.outid = 1;
end
if exist(DATA.inpipe) && binocisrunning
    DATA.inid = fopen(DATA.inpipe,'r');
else
    DATA.inid = 1;
end
fprintf(DATA.outid,'NewMatlab\n');
DATA = ReadFromBinoc(DATA,'reset','expect');
if readflag
fprintf(DATA.outid,'QueryState\n');
DATA = ReadFromBinoc(DATA,'expect');
end
SetGui(DATA,'set');
 
    
function DATA = GetState(DATA)
    fprintf(DATA.outid,'QueryState\n');
    tic; DATA = ReadFromBinoc(DATA);toc

function DATA = SetTrial(DATA, T)
    Trial = T;
    T.Start = now;
    nt = DATA.nt;
    if length(T.sv) && isfield(DATA,'exptype')
    DATA.Trials(nt).(DATA.exptype{1}) = T.sv(1);
    end
    if length(T.sv) > 1 && length(DATA.exptype) > 1
    DATA.Trials(nt).(DATA.exptype{2}) = T.sv(2);
    end
    if length(T.sv) > 2 && length(DATA.exptype) > 2
    DATA.Trials(nt).(DATA.exptype{3}) = T.sv(3);
    end
    f = fields(T);
    for j = 1:length(f)
        DATA.Trials(nt).(f{j}) = T.(f{j});
    end
    
    
function val = ReadVal(s, DATA)

    ccodes = {'ro' 'rx' 'ry'};
    truecodes = {'Ro' 'Rx' 'Ry'};
    
    id = strfind(s,'=');
    if isempty(id)
        s = s(3:end);
    else
        s = s(id(1)+1:end);
    end
    [val, n] = sscanf(s,'%f');
    if n == 0
        val = sscanf(s(3:end),'%f');
        if isempty(val)
            val = 0;
        end
        if strmatch(s(1:2),ccodes)
            id = strmatch(s(1:2),ccodes);
            val = val + DATA.binoc{1}.(truecodes{id});
        elseif strmatch(s(1:2),{'Rx' 'Ry'})
            val = val + DATA.binoc{1}.(s(1:2));
        end
    end

        
function S = SetField(S, F, x)
%Sets a field only if is doesn't exist
if ~isfield(S,F)
    S.(F) = x;
else
    x = S.(F);
end
    
function DATA = SetDefaults(DATA)

scrsz = get(0,'Screensize');
DATA.vergversion=vergversion();
DATA.matlabwasrun=0;
DATA.matexpres = [];
DATA.plotexpts = [];
DATA.completions = {};
DATA.newchar = 0;
DATA.newexptdef = 1;  %when load 1st file, don't do any resets
DATA.netmatdir= [GetFilePath('binoclean') '/matlab'];
DATA.localmatdir='/local/matlab';
DATA.pausetime = 0;
DATA.readpause = 0;
DATA.rptexpts = 0;
DATA.verg.layoutfile = '/local/verg.layout';
DATA.font.FontSize = 14;
DATA.font.FontName = 'Arial';
DATA.Coil.gain= [0 0 0 0];
DATA.Coil.phase= [4 4 4 4];
DATA.Coil.offset= [0 0 0 0];
DATA.Coil.so = [0 0 0 0];
DATA.Coil.CriticalWeight = 0;
DATA.layoutfile = '/local/verg.layout';
DATA.exptnextline = 0;
DATA.exptstoppedbyuser = 0;
DATA.pipelog = 0;
DATA.seqline = 0;
DATA.listmodified = [0 0 0];
DATA.Trial.Trial = 1;
DATA.windowcolor = [0.8 0.8 0.8];
DATA.Trial.sv = [];
DATA.psych.show = 1;
DATA.psych.trialresult = 0;
DATA.psych.blockmode = 'All';
DATA.psych.crosshairs = 1;
DATA.psych.blockid = [];
DATA.overcmds = {};
DATA.exptstimlist = { {} {} {} };
DATA.customstimlist = [0 0 ];
DATA.stimtypenames = {'fore' 'back' 'ChoiceU' 'ChoiceD'};
DATA.Statuslines = {};
DATA.statusitem = -1;
DATA.nt = 1;
DATA.exptype = [];
DATA.nexpts = 0;
DATA.Expts = {};
DATA.Trials = [];
DATA.showxy = [1 1 1]; %XY R, L, Conjugate crosses
DATA.currentstim = 1;  %foregr/backgre/Choice Targest
DATA.xyfsdvals = [1 2 5 10 20 40];
DATA.optionflags.ts = 0;
DATA.optionstrings.ts = 'Wurtz Task';
DATA.optionflags.do = 0;
DATA.optionstrings.do = 'Go';
DATA.showflags.ts = 1;
DATA.showflags.cf = 1;
DATA.showflagseq{1} = 'ts';
DATA.showflagseq{2} = 'cf';
DATA.stimflags{1}.pc = 1;
DATA.stimflags{1}.nc = 1;
DATA.stimflagnames.nc = 'Black Dots';
DATA.stimflagnames.pc = 'White Dots';
if ~isfield(DATA,'verbose')
    DATA.verbose = [0 0 0 0];
end
DATA = SetField(DATA,'matexpt','');
DATA = SetField(DATA,'perfmonitor',0);
DATA = SetField(DATA,'togglecodesreceived',0);
DATA = SetField(DATA,'autoreopen', 0);;

DATA.commands = {};
DATA.commandctr = 1;
DATA.historyctr = 0;
DATA.inexpt = 0;
DATA.datafile = [];
DATA.electrodestrings = {'Not Set'};
DATA.userstrings = {'bgc' 'ali' 'ink' 'agb'};
DATA.monkeystrings = {'Icarus' 'Junior Barnes' 'Lemieux' 'Pepper' 'Rufus' };
DATA.monkeystrs = {'ica' 'jbe' 'lem' 'ppr' 'ruf' };
DATA.binoc{1}.Electrode = 'default';
DATA.binoc{1}.monkey = 'none';
DATA.binoc{1}.lo = '';
DATA.binoc{1}.st = 'none'; % make sure this field comes early
DATA.penid = 0;
DATA.stimulusnames{1} = 'none';
DATA.stimulusnames{4} = 'grating';
DATA.stimulusnames{3} = 'rds';
DATA.stimulusnames{2} = 'gabor';
DATA.stimulusnames{5} = 'bar';
DATA.stimulusnames{6} = 'circle';
DATA.stimulusnames{7} = 'rectangle';
DATA.stimulusnames{8} = 'test';
DATA.stimulusnames{9} = 'square';
DATA.stimulusnames{10} = 'probe';
DATA.stimulusnames{11} = '2grating';
DATA.stimulusnames{12} = 'cylinder';
DATA.stimulusnames{13} = 'corrug';
DATA.stimulusnames{14} = 'sqcorrug';
DATA.stimulusnames{15} = 'twobar';
DATA.stimulusnames{16} = 'rls';
DATA.redundantcodes = {'Bh' 'Bc' 'Bs' 'Op' 'Pp' 'sO' 'bO' 'aOp' 'aPp' 'O2' 'lf' 'rf'};
DATA.stimlabels = {'Foregnd' 'Backgnd' 'ChoiceU/R' 'ChoiceD/L'};

DATA.badnames = {'2a' '4a' '72'};
DATA.badreplacenames = {'afc' 'fc4' 'gone'};

DATA.comcodes = [];
DATA.windownames = {'vergwindow' 'optionwindow' 'softoffwindow'  'codelistwindow' 'statuswindow' 'logwindow' 'helpwindow' 'sequencewindow' 'penlogwindow' 'electrodewindow'};
DATA.winpos{1} = [10 scrsz(4)-480 300 450];
DATA.winpos{2} = [10 scrsz(4)-680 400 50];  %options popup
DATA.winpos{3} = [600 scrsz(4)-100 600 150]; %softoff
DATA.winpos{4} = [600 scrsz(4)-600 400 500]; %code list
DATA.winpos{5} = [600 scrsz(4)-100 400 100]; %status
DATA.winpos{6} = [600 scrsz(4)-100 400 100]; %log
DATA.winpos{7} = [600 scrsz(4)-100 400 100]; %help
DATA.winpos{8} = [600 scrsz(4)-100 400 100]; %sequence
DATA.winpos{9} = [600 scrsz(4)-100 400 100]; %Penetraation log
DATA.winpos{10} = [600 scrsz(4)-100 400 100]; %Electrode Moving

DATA.outid = 0;
DATA.inid = 0;
DATA.cmdfid = 0;
DATA = SetField(DATA,'frombinocfid', 0);
DATA.tobinocfid = 0;
DATA.incr = [0 0 0];
DATA.nstim = [0 0 0];
DATA.quickexpts = [];
DATA.helpfiles = [];
DATA.stepsize = [20 10];
DATA.stepperpos = -2000;
DATA.tag.stepper = 'Stepper';
DATA.tag.softoff = 'Softoff';
DATA.tag.options = 'Options';
DATA.tag.penlog = 'Penetration Log';
DATA.tag.monkeylog = 'Monkey Log';
DATA.tag.codes = 'Codelist';
DATA.tag.psych = 'VergPsych';
DATA.tag.status = 'StatusWindow';
%make sure the size field is defined, then it comes before wi,hi
DATA.comcodes(1).label = 'Size';
DATA.comcodes(1).code = 'sz';
DATA.comcodes(1).const = 1;
DATA.comcodes(1).type = 'num';
DATA.comcodes(1).group = 1;
DATA.strcodes(1).label = 'Old Monitor file';
DATA.strcodes(1).code = 'oldmonitor';
DATA.strcodes(1).icode = 0; 

%Need to initialize values that verg might try to use 
%before reading values from binoclean
%Also define fields here that need to be send early in stream
% like sz - send before wi/hi so that is doen not override
DATA.binoc{1}.xo = 0;
DATA.binoc{1}.sz = 0;
DATA.binoc{2}.xo = 0;
DATA.binoc{1}.ePr = 0;
DATA.binoc{1}.adapter = 'None';
DATA.binoc{1}.uf = 'None';
DATA.binoc{1}.ei = '0';
DATA.binoc{1}.i2 = '0';
DATA.binoc{1}.i3 = '0';
DATA.binoc{1}.nr = 1;
DATA.binoc{1}.rw = 0;
DATA.binoc{1}.seqpause = 10;
DATA.binoc{1}.ereset = 'NotSet';

DATA.binocstr.monitor = '/local/monitors/Default';
DATA.completestr = '';
DATA.expts{1} = [];
DATA.expts{2} = [];
DATA.expts{3} = [];
DATA.expmenuvals{1} = [];
DATA.expmenuvals{2} = [];
DATA.expmenuvals{3} = [];
DATA.extypes{1} = [];
DATA.extypes{2} = [];
DATA.extypes{3} = [];
DATA.exptype{1} = 'e0';
DATA.exptype{2} = 'e0';
DATA.exptype{3} = 'e0';
DATA.stimtype(1) = 1;
DATA.stimtype(2) = 1;
DATA.nextras = [0 0 0];

DATA.electrodeid = 1;
DATA.mean = [0 0 0];
DATA.incr = [0 0 0];
DATA.servoport = []; %name of tty2 in /local/binoc.setup
DATA.servofig = 0;  %Figre # of servo control window.
DATA = ReadSetupFile(DATA, '/local/binoc.setup');
DATA = ReadStimFile(DATA, '/local/verg.setup');
[DATA.helpstrs, DATA.helpkeys] = ReadHelp(DATA);

for j = 1:3 
DATA.expmenucodes{j} = {};
DATA.expstrs{j} = {};
DATA.expmenuvals{j} = [];
end
for j = 1:length(DATA.comcodes)
    if ismember(DATA.comcodes(j).const,DATA.extypes{1})
        DATA.expstrs{1} = {DATA.expstrs{1}{:} DATA.comcodes(j).label};
        DATA.expmenuvals{1} = [DATA.expmenuvals{1} DATA.comcodes(j).const];
        DATA.expmenucodes{1} = {DATA.expmenucodes{1}{:} DATA.comcodes(j).code};
    end
    if ismember(DATA.comcodes(j).const,DATA.extypes{2})
        DATA.expstrs{2} = {DATA.expstrs{2}{:} DATA.comcodes(j).label};
        DATA.expmenuvals{2} = [DATA.expmenuvals{2} DATA.comcodes(j).const];
    end
    if ismember(DATA.comcodes(j).const,DATA.extypes{3})
        DATA.expstrs{3} = {DATA.expstrs{3}{:} DATA.comcodes(j).label};
        DATA.expmenuvals{3} = [DATA.expmenuvals{3} DATA.comcodes(j).const];
    end
end


function [strs, Keys] = ReadHelp(DATA)
 
    strs = {};
    Keys = [];
    helpfile = [DATA.localmatdir '/helpstrings.txt'];
    fid = fopen(helpfile,'r');
    Keys.extras =[];
    if fid > 0
    a = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    txt = a{1};
    code = [];
    lastcode = code;
    for j = 1:length(txt)
        code = regexprep(txt{j},'\s.*','');
        if code(1) == '+'  %optionflag help
            str = regexprep(txt{j},code,'');
            code = code(2:end);
            Keys.options.(code) = str;
        elseif txt{j}(1) == '#' && ~isempty(lastcode)
            if isfield(Keys.extras,lastcode)
                Keys.extras.(lastcode){end+1} = txt{j}(2:end);
            else
                Keys.extras.(lastcode){1} = txt{j}(2:end);
            end
        elseif ~isempty(code) && txt{j}(1) ~= '#'
            if isfield(strs,code) && DATA.verbose(4)
                fprintf('%s help duplicated\n',code);
            end
            str = regexprep(txt{j},code,'');
            if strfind(str,'#')
                keyword = regexprep(str,'.*#','');
                Keys.KeyWords.(code) = keyword;
            else
                Keys.KeyWords.(code) = '';
            end     
            str = regexprep(str,'#.*','');
            strs.(code) =  str;
            lastcode = code;
        end
    end
    end
    
    
 function DATA = SetExptMenus(DATA)

    
    
if isfield(DATA,'exptstimlist')
    for j = 1:length(DATA.exptstimlist)
        S = DATA.exptstimlist{j};
        for m = 1:length(S)
            [val,n] = sscanf(S{m},'%f');
            if n == 1
            DATA.expvals{j}(m) = val;
            end
        end
    end
end



for m = 1:3
    if length(DATA.expmenuvals{m}) > 0
        DATA.expstrs{m} = {DATA.comcodes(DATA.expmenuvals{m}).label};
        DATA.expmenucodes{m} = {DATA.comcodes(DATA.expmenuvals{m}).code};
    else
    DATA.expmenucodes{m} = {};
    DATA.expstrs{m} = {};
    DATA.expmenuvals{m} = [];
    for j = 1:length(DATA.extypes{m})
        id = find([DATA.comcodes.const] == DATA.extypes{m}(j));
        if length(id) == 1
            DATA.expstrs{m} = {DATA.expstrs{m}{:} DATA.comcodes(id).label};
            DATA.expmenuvals{m} = [DATA.expmenuvals{m} DATA.comcodes(id).const];
            DATA.expmenucodes{m} = {DATA.expmenucodes{m}{:} DATA.comcodes(id).code};
        end
    end
    end
end

   
if isfield(DATA,'toplevel') %GUI is up
it = findobj(DATA.toplevel,'Tag','Expt1List');
set(it,'string',DATA.expstrs{1});
it = findobj(DATA.toplevel,'Tag','Expt2List');
set(it,'string',DATA.expstrs{2});
it = findobj(DATA.toplevel,'Tag','Expt3List');
e2 = get(it,'value');
if e2 > length(DATA.expstrs{3})
    set(it,'value',1);
end
set(it,'string',DATA.expstrs{3});
end

function ShowStatus(DATA)

    persistent oldcount;
    if isempty(oldcount)
        oldcount = 0;
    end
    status = 1;
    if DATA.inexpt  && DATA.nexpts > 0
        str = datestr(DATA.Expts{DATA.nexpts}.Start);
        str = ['Started ' str(13:17)];
    elseif DATA.nexpts > 0
        if isfield(DATA.Expts{DATA.nexpts},'End')
            str = datestr(DATA.Expts{DATA.nexpts}.End);
            str = ['Ended ' str(13:17)];
        else
            str = 'Expt not over But In Expt!';
        end
    else
        status = 0;
        str = ['No Trials Run'];
    end
    if isfield(DATA,'trialcounts') && length(DATA.trialcounts) > 7
    s = sprintf('Trials %d/%d Bad%d Late%d  Rw%.1f Ex:%d/%d %s',...
    DATA.trialcounts(1),DATA.trialcounts(2),DATA.trialcounts(3),DATA.trialcounts(4),...
    DATA.trialcounts(8),DATA.trialcounts(6),DATA.trialcounts(7),str);
    else
        s = str;
    end

if isfield(DATA,'toplevel')
    set(DATA.toplevel,'Name',s);
end
if status >0 && DATA.trialcounts(8) ~= oldcount
    fprintf('%s\n',s);
end
if isfield(DATA,'trialcounts')
    oldcount = DATA.trialcounts(8);
end


function DATA = InitInterface(DATA)

    scrsz = get(0,'Screensize');
    cntrl_box = figure('Position', DATA.winpos{1},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{1},'Name',DATA.name,'menubar','none');
                set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);
                set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);


    if isfield(DATA.showflags,'do')
    DATA.showflags = rmfield(DATA.showflags,'do');
    end
    f = fields(DATA.showflags);
    nc = 5;
    tagc = 6;%# of columns for toggles
    nr = 19 + ceil((1+length(f))./tagc);
    cw = 0.99/nc;
    DATA.toplevel = cntrl_box;
    
    lst = jcontrol(gcf,'javax.swing.JTextField',...
                    'Units','normalized',...
                    'Position',[0.01 0.01 0.98 1./nr]);

    set(lst, 'KeyPressedCallback', {@jTextKey});
    lst.setFocusable(true);
    lst.setFocusTraversalKeysEnabled(false)
%    lst.KeyPressedCallback = @jTextKey
    lst.setBackground(java.awt.Color(1,1,1))
%     set(lst, 'String', '',...            
%         'HorizontalAlignment','left',...
%         'Callback', {@TextEntered}, 'Tag','NextButton',...
%         'units','norm', 'Position',[0.01 0.01 0.98 1./nr],...
%          'KeyReleasedCallBack', @JtextKey);
    DATA.txtui = lst;
%        'KeyPressFcn',@TextKey,
    
    
    bp = [0.01 1.01./nr 3.5./nc 6/nr];
    lst = uicontrol(gcf, 'Style','list','String', 'Command History',...
        'HorizontalAlignment','left',...
        'Max',10,'Min',0,...
        'Tag','CommandHistory',...
        'callback',@TextList,...
'units','norm', 'Position',bp);
   DATA.txtrec = lst;
   
    xp = bp(1)+bp(3);
    bp(1) = bp(1)+bp(3);
    bp(2) = 2./nr;
    bp(3) = cw/3;
    bp(4) = 1./nr;
    [a,j] = min(abs(DATA.binoc{1}.xyfsd - DATA.xyfsdvals));
    uicontrol(gcf,'style','text','string','FSD',  'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3)=0.99-bp(1);
    uicontrol(gcf,'style','pop','string',num2str(DATA.xyfsdvals'), ...
        'units', 'norm', 'position',bp,'value',j,'Tag','FSD','callback',{@SetExpt, 'fsd'});

     bp(3) = cw/2;
    bp(2) = 3./nr;
    bp(1) = xp;
    uicontrol(gcf,'style','checkbox','string','XYR',  'Tag', 'XYR', 'value', DATA.showxy(1), 'units', 'norm', 'position',bp, 'callback', {@OtherToggles, 'XYR'});
    
    bp(1) = bp(1)+bp(3);
    uicontrol(gcf,'style','checkbox','string','XYL',  'Tag', 'XYL', 'value', DATA.showxy(2), 'units', 'norm', 'position',bp, 'callback', {@OtherToggles, 'XYL'});
    bp(1) = bp(1)+bp(3);
    uicontrol(gcf,'style','checkbox','string','XYB',  'Tag', 'XYB', 'value', DATA.showxy(3), 'units', 'norm', 'position',bp, 'callback', {@OtherToggles, 'XYB'});

    
    bp(1) = 0.01;
    bp(2) = 8./nr;
    bp(3) = 0.1;
    bp(4) = 1./nr;
    uicontrol(gcf,'style','text','string','File',  'units', 'norm', 'position',bp);

    
    
    bp(1) = bp(1)+bp(3);
    bp(3) = 1-bp(1)-0.1;
    uicontrol(gcf,'style','edit','string',DATA.datafile, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','DataFileName','callback',{@TextGui, 'uf'});
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.1;
            uicontrol(gcf,'style','pushbutton','string','Open', ...
        'Callback', {@OpenUffFile, 1}, 'Tag','UffButton',...
        'units', 'norm', 'position',bp,'value',1);
    
    
    bp(1) = 0.01;
    bp(2) = 7./nr;
    bp(3) = 0.15;
    bp(4) = 1./nr;
    uicontrol(gcf,'style','text','string','Comment',  'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 1-bp(1);
    uicontrol(gcf,'style','edit','string','', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Comment','callback',{@TextGui, 'cm'});

    
    bp(2) = 11./nr;
    bp(1) = 0.01;
    bp(4) = 1./nr;
    bp(3) = cw;
        uicontrol(gcf,'style','pushbutton','string','Finish', ...
        'Callback', {@RunButton, 2}, 'Tag','StopButton',...
        'units', 'norm', 'position',bp,'value',1);
    bp(2) = 10./nr;
    bp(3) = cw/2;
         uicontrol(gcf,'style','Text','string','Rpt', ...
        'units', 'norm', 'position',bp,'value',1);
    bp(2) = 10./nr;
    bp(1) = cw/2;
         uicontrol(gcf,'style','edit','string',num2str(DATA.rptexpts), ...
             'Tag','RptExpts','Callback',@TextGui,...
        'units', 'norm', 'position',bp,'value',1);

    bp(2) = 12./nr;
    bp(1) = 0.01;
    bp(4) = 1./nr;
    bp(3) = cw/4;
         uicontrol(gcf,'style','Text','string','N', ...
        'units', 'norm', 'position',bp,'value',1);
    bp(1) = bp(3);
    bp(3) = 0.75*cw;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.nr), 'Tag', 'binoc.nr', 'units', 'norm',...
        'callback',{@TextGui, 'nr'},'position',bp);
    
    
    
    cmenu = uicontextmenu;
    uimenu(cmenu,'label','Apply to Expt 1 (cntrl-g)','Callback',{@EditValsMenu, 'apply'});
    uimenu(cmenu,'label','Cancel (Esc)','Callback',{@EditValsMenu, 'cancel'});
    
    bp(3) = 1./nc;
    bp(2) = 9./nr;
    bp(4) = 4/nr;
    bp(1) = 0.02+cw;
 %elsewhere use findobj to get this item, so only use the tag once
    a= uicontrol(gcf,'style','edit','string',DATA.exptstimlist{1}, 'min',1,'max',5,...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt1StimList','keypressfcn',@EditText,'callback',@TextCallback);
    set(cmenu,'UserData',a,'tag','Expt1StimList');
    set(a,'uicontextmenu',cmenu);

    
    cmenu = uicontextmenu;
    uimenu(cmenu,'label','Apply to Expt2 (cntrl-g)','Callback',{@EditValsMenu, 'apply2'});
    uimenu(cmenu,'label','Cancel (Esc)','Callback',{@EditValsMenu, 'cancel'});
    bp(1) = bp(1)+bp(3)+0.01;
    a = uicontrol(gcf,'style','edit','string',num2str(DATA.nstim(2)),  'min',1,'max',5,...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt2StimList','keypressfcn',@EditText);
    bp(1) = bp(1)+bp(3)+0.01;
    set(cmenu,'UserData',a,'tag','Expt2StimList');
    set(a,'uicontextmenu',cmenu);

    cmenu = uicontextmenu;
    uimenu(cmenu,'label','Apply to Expt3 (cntrl-g)','Callback',{@EditValsMenu, 'apply3'});
    uimenu(cmenu,'label','Cancel (Esc)','Callback',{@EditValsMenu, 'cancel'});
    a = uicontrol(gcf,'style','edit','string',num2str(DATA.nstim(3)),  'min',1,'max',5, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt3StimList','keypressfcn',@EditText,'callback',@TextCallback);
    set(cmenu,'UserData',a,'tag','Expt3StimList');
    set(a,'uicontextmenu',cmenu);
    
    
    bp(1) = 0.01;
    bp(2) = bp(2)+bp(4);
    bp(3) = cw;
    bp(4) = 1.2/nr;
    uicontrol(gcf,'style','text','string','N stim',  'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = cw;
    uicontrol(gcf,'style','edit','string',num2str(DATA.nstim(1)), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt1Nstim','callback',{@TextGui, 'nt'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.nstim(2)), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt2Nstim','callback',{@TextGui, 'n2'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.nstim(3)), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt3Nstim','callback',{@TextGui, 'n3'});

    bp(1) = 0.01;
    bp(2) = bp(2)+bp(4);
    bp(3) = cw;
    uicontrol(gcf,'style','text','string','Incr',  'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = cw;
    uicontrol(gcf,'style','edit','string',DATA.binoc{1}.ei, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt1Incr','callback',{@TextGui, 'ei'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',DATA.binoc{1}.i2, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt2Incr','callback',{@TextGui, 'i2'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',DATA.binoc{1}.i3, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt3Incr','callback',{@TextGui, 'i3'});

    bp(1) = 0.01;
    bp(2) = bp(2)+bp(4);
    bp(3) = cw;
    uicontrol(gcf,'style','text','string','Mean',  'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = cw;
    uicontrol(gcf,'style','edit','string',num2str(DATA.mean(1)), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt1Mean','callback',{@TextGui, 'em'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.mean(2)), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt2Mean','callback',{@TextGui, 'm2'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.mean(3)), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt3Mean','callback',{@TextGui, 'm3'});

    
    bp(1) = 0.01;
    bp(2) = bp(2)+bp(4);
    bp(3) = cw;
    
    uicontrol(gcf,'style','pushbutton','string','Run', ...
        'Callback', {@RunButton, 1}, 'Tag','RunButton',...
        'units', 'norm', 'position',bp,'value',1);
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = cw;
    uicontrol(gcf,'style','pop','string',DATA.expstrs{1}, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt1List','callback',{@SetExpt, 'et'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pop','string',DATA.expstrs{2}, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt2List','callback',{@SetExpt, 'e2'});
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pop','string',DATA.expstrs{3}, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Expt3List','callback',{@SetExpt, 'e3'});
    
    bp(1) = 0.01;
    bp(2) = bp(2)+bp(4);
    bp(3) = cw;
    a = uicontrol(gcf,'style','text','string','Foreground',  'units', 'norm', 'Tag','CurrentStimLabel','position',bp);     
    cmenu = uicontextmenu;
    uimenu(cmenu,'label','Edit ForeGround','Callback',{@StimulusSelectMenu, 'fore'});
    uimenu(cmenu,'label','Edit BackGround','Callback',{@StimulusSelectMenu, 'back'});
    uimenu(cmenu,'label','Edit Choice Icon (U/R)','Callback',{@StimulusSelectMenu, 'ChoiceU'});
    uimenu(cmenu,'label','Edit Choice Icon (D/L)','Callback',{@StimulusSelectMenu, 'ChoiceD'});
    set(a,'uicontextmenu',cmenu);
    
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = cw;
    uicontrol(gcf,'style','pop','string',DATA.stimulusnames, ...
        'units', 'norm', 'position',bp,'value',DATA.stimtype(1),'Tag','ForegroundType','callback',{@SetExpt, 'st'});
    bp(1) = bp(1)+bp(3)+0.01;
    a = uicontrol(gcf,'style','text','string','Backgnd',  'units', 'norm', 'Tag','BackgrStimLabel','position',bp);     
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pop','string',DATA.stimulusnames, ...
        'units', 'norm', 'position',bp,'value',DATA.stimtype(2),'Tag','BackgroundType','callback',{@SetExpt, 'bs'});

    

    bp(1) = 0.01;
    bp(2) = 1-1/nr;
    bp(4) = 1./nr;
    bp(3) = 1./tagc;
    uicontrol(gcf,'style','checkbox','string','Go', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','do','callback',@GoToggle);
    f = fields(DATA.showflags);
    allf = fields(DATA.optionflags);
    if isfield(DATA,'showflagseq')
        f = DATA.showflagseq;
        nrows = ceil(length(f)./tagc)./nr; %fraction of window height needed for tags
    else
        nrows = 2/nr;
    end
    
    
    cmenu = uicontextmenu;
    f = fields(DATA.optionstrings);
    of = fields(DATA.optionflags);
    amenu = uimenu(cmenu,'Label','General');
    for j = 1:length(f)
        if strncmp(of{j},'lbl',3)
            amenu = uimenu(cmenu,'Label',DATA.optionstrings.(f{j}));
        else
            h = uimenu(amenu,'label',DATA.optionstrings.(f{j}),'Callback',{@OptionMenu, f{j}},'tag',f{j});
            if DATA.optionflags.(f{j})
                set(h,'checked','on');
            end
        end
    end
    set(cmenu,'tag','OptionContextMenu');
    
    f = f(find(~strcmp('do',f)));
    ymin = 1-1./nr - nrows;
    ymin = 1 - nrows;
    for j = 1:length(f)
        id = strmatch(f{j},allf);
        if length(id) == 1
            str = DATA.optionstrings.(allf{id});
        else
            str = num2str(j);
        end
        bp(2) = bp(2)-bp(4);
        if bp(2) < ymin
            bp(1) = bp(1)+bp(3);
            bp(2) = 1- 1./nr;
        end
        if isfield(DATA.optionflags,f{j})
            h = uicontrol(gcf,'style','checkbox','string',str, ...
                'units', 'norm', 'position',bp,'value',DATA.optionflags.(f{j}),'Tag',f{j},'callback',{@HitToggle, f{j}});
            set(h,'uicontextmenu',cmenu);
        end

    end
    bp(3) = 1/nc;
    
    hm = uimenu(cntrl_box,'Label','File','Tag','BinocFileMenu');
    uimenu(hm,'Label','Close','Callback',{@verg, 'close'});
    uimenu(hm,'Label','Close Verg and Binoc','Callback',{@MenuHit, 'bothclose'});
    uimenu(hm,'Label','Save','Callback',{@SaveFile, 'current'});
    uimenu(hm,'Label','Save As...','Callback',{@SaveFile, 'saveas'});
    sm = uimenu(hm,'Label','Preferences');
    uimenu(sm,'Label','Save Layout','Callback',{@SaveFile, 'layout'});
    uimenu(sm,'Label','Choose Font','Callback',{@MenuHit, 'choosefont'});
    uimenu(sm,'Label','Update local .m files','Callback',{@SaveFile, 'update'});
    sm = uimenu(hm,'Label','Today Slots');
    for j = 1:8
    uimenu(sm,'Label',['Expt' num2str(j)],'Callback',{@SaveSlot, j});
    end
    sm = uimenu(hm,'Label','Recover','Callback',{@RecoverFile, 'toplist'});
    x = uimenu(sm,'Label','List','Callback',{@RecoverFile, 'list'});
    uimenu(sm,'Label','eo.stm','Callback',{@RecoverFile, 'eo.stm'});
    uimenu(sm,'Label','eb.stm','Callback',{@RecoverFile, 'eb.stm'});
    uimenu(sm,'Label','0.stm','Callback',{@RecoverFile, '0stim'});
    uimenu(sm,'Label','1.stm','Callback',{@RecoverFile, '2stim'});
    uimenu(sm,'Label','Just Read id/se from last','Callback',{@RecoverFile, 'loadlast'});
    set(DATA.toplevel,'UserData',DATA);
            RecoverFile(x,[],'list');    
    hm = uimenu(cntrl_box,'Label','Quick','Tag','QuickMenu');
    BuildQuickMenu(DATA, hm);
        hm = uimenu(cntrl_box,'Label','&Pop','Tag','PopMenu');
%    uimenu(hm,'Label','Stepper','Callback',{@StepperPopup});
%currently can do everything in binoc. Stick with this til need something
%new....
    subm = uimenu(hm,'Label','&Windows');
    uimenu(subm,'Label','&Options','Callback',{@OptionPopup},'accelerator','O');
    uimenu(subm,'Label','Penetration Log','Callback',{@PenLogPopup});
    uimenu(subm,'Label','Monkey Log','Callback',{@MonkeyLogPopup, 'popup'});
    uimenu(subm,'Label','List Codes','Callback',{@CodesPopup, 'popup'},'accelerator','L');
    uimenu(subm,'Label','Status Lines','Callback',{@StatusPopup, 'popup'});
    uimenu(subm,'Label','Psych Window','Callback',{@MenuHit, 'showpsych'});
    uimenu(subm,'Label','Electrode Control','Callback',{@ElectrodePopup, 'popup'});
    subm = uimenu(cntrl_box,'Label','Pipes');
    uimenu(subm,'Label','Reopen Pipes','Callback',{@ReadIO, 6});
    uimenu(subm,'Label','reopenserial','Callback',{@SendStr, '\reopenserial'});
    uimenu(subm,'Label','Test','Callback',{@TestIO});
    uimenu(subm,'Label','Read','Callback',{@ReadIO, 1});
    uimenu(subm,'Label','GetState','Callback',{@ReadIO, 2});
    uimenu(subm,'Label','NewStart','Callback',{@ReadIO, 3});
    uimenu(subm,'Label','Stop Timer','Callback',{@ReadIO, 4});
    sm = uimenu(subm,'Label','Start Timer','Callback',{@ReadIO, 5},'foregroundcolor',[0 0 0.5]);
    sm = uimenu(subm,'Label','Verbose');
    xm = uimenu(sm,'Label','To Binoc', 'Callback', {@SetVerbose, 1});
    SetMenuCheck(xm, DATA.verbose(1));
    xm = uimenu(sm,'Label','From Binoc','Callback', {@SetVerbose, 2});
    SetMenuCheck(xm, DATA.verbose(2));
    xm = uimenu(sm,'Label','Trial Data', 'Callback',{@SetVerbose, 3});
    SetMenuCheck(xm, DATA.verbose(3));
    xm = uimenu(sm,'Label','verg', 'Callback',{@SetVerbose, 4});
    SetMenuCheck(xm, DATA.verbose(4));
    xm = uimenu(sm,'Label', 'All Off', 'Callback', {@SetVerbose, 0});

    sm = uimenu(subm,'Label','Try Pipes','Callback',{@ReadIO, 8},'foregroundcolor','r');
    subm = uimenu(hm,'Label','&Software Offset');
    uimenu(subm,'Label','&Null','Callback',{@SendStr, 'sonull'},'accelerator','E');
    uimenu(subm,'Label','Edit','Callback',{@SoftoffPopup, 'popup'});
    uimenu(subm,'Label','Clear','Callback',{@SendStr, '\clearsoftoff'});
    uimenu(hm,'Label','Run Sequence of expts','Callback',{@SequencePopup, 'popup'});
    uimenu(hm,'Label','Pause Expt','Callback',{@SendStr, '\pauseexpt'});
    uimenu(hm,'Label','Center stimulus','Callback',{@SendStr, 'centerstim'});
    uimenu(hm,'Label','Clear Drawn Lines','Callback',{@SendStr, '!clearlines'});
    uimenu(hm,'Label','BlackScreen (shake)','Callback',{@MenuHit, 'setshake'},'accelerator','B');
    uimenu(hm,'Label','pipelog','Callback',{@MenuHit, 'pipelog'});
    uimenu(hm,'Label','freereward','Callback',{@MenuHit, 'freereward'},'accelerator','R');
    hm = uimenu(cntrl_box,'Label','Mark');

    
    hm = uimenu(cntrl_box,'Label','Help','Tag','HelpMenu');
    BuildHelpMenu(DATA, hm);

    DATA.timerobj = timer('timerfcn',{@CheckInput, DATA.toplevel},'period',1,'executionmode','fixedspacing');
    
    set(DATA.toplevel,'UserData',DATA);
    start(DATA.timerobj);

function ShowHelp(a,b,file)

  DATA = GetDataFromFig(a);
  cntrl_box = findobj('Tag',DATA.windownames{7},'type','figure');
  if isempty(cntrl_box)
  cntrl_box = figure('Position', DATA.winpos{7},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{7},'Name','HelpText','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);
        set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);

    
    lst = uicontrol(gcf, 'Style','edit','String', 'HelpText',...
        'HorizontalAlignment','left',...
        'Max',10,'Min',0,...
        'Tag','HelpText',...
'units','norm', 'Position',[0.01 0.01 0.99 0.99]);
  else
      lst = findobj(cntrl_box,'Tag','HelpText')
      figure(cntrl_box);
  end
  try
      fid = fopen(file,'r');
      fclose(fid)
      txt = textread(file,'%s','delimiter','\n');
      set(lst,'string',txt);
  catch
      fprintf('%s\n',lasterr)
  end

   function BuildHelpMenu(DATA, hm)
        
   uimenu(hm,'Label','List All Codes','Callback',{@CodesPopup, 'popup'},'accelerator','L');
   uimenu(hm,'Label','List Codes with Help','Callback',{@CodesPopup, 'popuphelp'});
   for j = 1:length(DATA.helpfiles)
        uimenu(hm,'Label',DATA.helpfiles(j).label,'Callback',{@ShowHelp, DATA.helpfiles(j).filename});
    end
   uimenu(hm,'Label',sprintf('Version %s',strrep(DATA.vergversion,'verg.','')));
 
  function OptionMenu(a,b,tag)     
      DATA = GetDataFromFig(a);
      on = get(a,'checked');
      f = get(a,'tag')
      if strcmp(on,'on');
          set(a,'checked','off');
          DATA.optionflags.(f) = 0;
      else
          set(a,'checked','on');
          DATA.optionflags.(f) = 1;
      end
      SendCode(DATA, 'optionflag');
   
  function BuildQuickMenu(DATA, hm)
        
    if isfield(DATA.quickexpts,'submenu')
    subs = unique({DATA.quickexpts.submenu});
    for j = 1:length(subs)-1
        sm(j) = uimenu(hm,'Label',subs{j+1});
    end
    for j = 1:length(DATA.quickexpts)
        k = strmatch(DATA.quickexpts(j).submenu,subs);
        if k > 1
            uimenu(sm(k-1),'Label',DATA.quickexpts(j).name,'Callback',{@verg, 'quick', DATA.quickexpts(j).filename});
        else
            uimenu(hm,'Label',DATA.quickexpts(j).name,'Callback',{@verg, 'quick', DATA.quickexpts(j).filename});
        end
    end
    end
    uimenu(hm,'Label','Today','Tag','TodayQuickList');
    uimenu(hm,'Label','Add...','Tag','AddToQuickList','callback',{@AddQuickMenu});

function AddQuickMenu(a,b)
    DATA = GetDataFromFig(a);
    [name, path] = uigetfile(['/local/' DATA.binoc{1}.monkey '/stims/*.*']);
    j = length(DATA.quickexpts)+1;
    DATA.quickexpts(j).name = name;
    DATA.quickexpts(j).filename = [path '/' name];
    if name
        hm = get(a,'parent');
        uimenu(hm,'Label',DATA.quickexpts(j).name,'Callback',{@verg, 'quick', DATA.quickexpts(j).filename});
    end
    
function SetElectrode(a,b, ei)
    DATA = GetDataFromFig(a);
    DATA.electrodeid = ei;
    SetMenuCheck(a,[], ei);
    SendCode(DATA, 'Electrode');
    set(DATA.toplevel,'UserData',DATA);
    
function MenuHit(a,b, arg)
    DATA = GetDataFromFig(a);
    if strcmp(arg,'bothclose')
        fprintf(DATA.outid,'\\quit\n');
        if DATA.pipelog
            system([GetFilePath('perl') '/pipelog end']);
        end
        if isfield(DATA,'timerobj') & isvalid(DATA.timerobj)
            stop(DATA.timerobj);
        end
        for j = 2:length(DATA.windownames)
            CloseTag(DATA.windownames{j});
        end
        CloseTag(DATA.windownames{1}); %%close main window last
    elseif strcmp(arg,'choosefont')
        fn = uisetfont;
        DATA.font = fn;
        set(DATA.toplevel,'UserData',DATA);
    elseif strcmp(arg,'freereward')
        fprintf(DATA.outid,'freerwd\n');
    elseif strcmp(arg,'pipelog')       
        [a, prefix] = fileparts(DATA.binoc{1}.psychfile);
        prefix = regexprep(prefix,'[0-9][0-9][A-Z][a-z][a-z]20[0-9][0-9]','');
        prefix = regexprep(prefix,'DATE$','');
        system([GetFilePath('perl') '/pipelog ' DATA.binoc{1}.monkey ' ' prefix ' &']);
        DATA.pipelog = 1;
        DATA = AddTextToGui(DATA,['Pipelog ' prefix]);
    elseif strcmp(arg,'setshake')
        fprintf(DATA.outid,'usershake\n');
        
    elseif strcmp(arg,'showpsych')
        DATA.psych.blockmode = 'Current';
        PlotPsych(DATA);
        set(DATA.toplevel,'UserData',DATA);
    end
    
    
 function SetExpt(a,b, type)
     DATA = GetDataFromFig(a);
     val = get(a,'value');
     str = get(a,'string');
    if strmatch(type,'et')
        fprintf(DATA.outid,'et=%s\n',DATA.comcodes(DATA.expmenuvals{1}(val)).code);
    elseif strmatch(type,'e2')
        fprintf(DATA.outid,'e2=%s\n',DATA.comcodes(DATA.expmenuvals{2}(val)).code);
    elseif strmatch(type,'e3')
        fprintf(DATA.outid,'e3=%s\n',DATA.comcodes(DATA.expmenuvals{3}(val)).code);
    elseif strmatch(type,'fsd')
        if iscellstr(str)
        fprintf(DATA.outid,'\\xyfsd=%s\n',str{val});
    else
        fprintf(DATA.outid,'\\xyfsd=%s\n',str(val,:));
        end
    elseif strmatch(type,{'st' 'bs'})
        id = strmatch(type,{'st' 'bs'});
        if val > 0
        DATA.stimtype(id) = val;
        fprintf(DATA.outid,'mo=%s\n',DATA.stimtypenames{id});
        fprintf(DATA.outid,'st=%s\n',DATA.stimulusnames{val});
        DATA.currentstim = id;
        SetGui(DATA);
        else
            fprintf('Cant set stim < 1\n');
        end
    end
    set(DATA.toplevel,'UserData',DATA);

    
function DATA = LoadLastSettings(DATA, varargin)
%DATA = LoadLastSettings(DATA, varargin)
% reads state variables from expt backup files to restosr
% state - including se, id, penetraion details, ed.
% Only does this if the backup is less than half an hour old
% ...,'force')  overrides time test
    interactive = 0;
    j = 1;
    go  = 0;
    while j <= length(varargin)
        if strncmpi(varargin{j},'force',5)
            go = 1;
        elseif strncmpi(varargin{j},'interactive',5)
            interactive = 1;
        end
        j = j+1;
    end
    
        rfile = ['/local/' DATA.binoc{1}.monkey '/lean*.stm'];
        d = mydir(rfile);
        if isempty(d)
            return;
        end
        [a,id] = max([d.datenum]);
        d = d(id);
        if now - d.datenum < 0.5/24 %less than an half an hour old - read in settings
            go = 1;
            if interactive 
                yn = questdlg(sprintf('Looks like you are re-starting Mid expt. Do you want to reload id/se from %s',d.filename),'Binoc has been working','Yes','No','Yes');
                if ~strcmp(yn,'Yes')
                    go = 0;
                end
            end
        end
        if go
            txt = scanlines(d.name);
            for s = {'id' 'se' 'ed' 'Rx' 'Ry' 'Ro' 'Rw' 'Rh' 'Xp' 'Yp' 'Pn' 'Electrode' 'hemi' 'ui' 'ePr' 'eZ' 'monkey' 'coarsemm' 'adapter'}
            id = find(strncmp(s,txt,length(s{1})));
            if ~isempty(id)
                cprintf('blue','Setting %s from %s\n',txt{id(1)},d.name);
                DATA = InterpretLine(DATA, txt{id(1)},'tobinoc');
            end
            end
        end
    
function RecoverFile(a, b, type)
    DATA = GetDataFromFig(a);
%        fprintf('Recover called with %s\n',type);
    if strmatch(type,{'list'});
        rfile = ['/local/' DATA.binoc{1}.monkey '/lean*.stm'];
        d = dir(rfile);

        if isempty(d)
            return;
        end
        if strcmp(type,'list')
        hm = get(a,'parent');
        else
            hm = a;
        end
        c = get(hm,'Children');
        delete(c);
        uimenu(hm,'Label','List','callback',{@RecoverFile, 'list'});
        [a,id] = sort([d.datenum]);
        d = d(id);
        uimenu(hm,'Label',['Just Restore Pen/Expt Settings from ' d(end).name],'callback',{@RecoverFile, 'loadlast'});
        for j = 1:length(d)
            uimenu(hm,'Label',[d(j).name d(j).date(12:end)],'callback',{@RecoverFile, d(j).name(5:end)});
        end
    elseif strmatch(type,{'eo.stm' 'eb.stm' '0.stm' '1.stm' '2.stm' '3.stm' '4.stm' '5.stm'})
        rfile = ['/local/' DATA.binoc{1}.monkey '/lean' type];
        dfile = ['/local/' DATA.binoc{1}.monkey '/lean.today'];
        copyfile(rfile,dfile);
        DATA = ReadStimFile(DATA, dfile);
        set(DATA.toplevel,'UserData',DATA);
    elseif strcmp(type,'loadlast')
        DATA = LoadLastSettings(DATA,'noninteractive','force');
        set(DATA.toplevel,'UserData',DATA);
    else
        if DATA.verbose(4)
            fprintf('Recover called with %s\n',type);
        end
    end
    
    
function ReadSlot(a,b,id)
    DATA = GetDataFromFig(a);
    quickname = sprintf('/local/%s/q%dexp.stm', DATA.binoc{1}.monkey,id);
    DATA = ReadStimFile(DATA, quickname);
    set(DATA.toplevel,'UserData',DATA);
    

    
function SaveSlot(a,b,id)
    DATA = GetDataFromFig(a);
    lb = sprintf('Expt%d: %s %s',id,DATA.stimulusnames{DATA.stimtype(1)},DATA.exptype{1});
    if ~strcmp(DATA.exptype{2},'e0')
        lb = [lb 'X' DATA.exptype{2}];
    end
    if ~strcmp(DATA.exptype{3},'e0')
        lb = [lb 'X' DATA.exptype{3}];
    end
    if DATA.optionflags.fS
        lb = [lb 'RC'];
    end
    set(a,'Label',lb);
    fprintf(DATA.outid,'quicksave%d\n',id);
    AddTodayMenu(DATA, id, lb);

function AddTodayMenu(DATA, id,label)
    
    tag = sprintf('TodaySlot%d',id);
    it = findobj(DATA.toplevel,'Tag',tag);
    if isempty(it)
        it = findobj(DATA.toplevel,'Tag','TodayQuickList');
        if length(it) == 1
            uimenu(it,'Label',label,'callback',{@ReadSlot, id},'Tag',tag);
        end
    else
        set(it,'Label',label);
    end
    
function CheckForUpdate(DATA)
    CheckFileUpdate([DATA.netmatdir '/verg.m'],[DATA.localmatdir '/verg.m']);
    CheckFileUpdate([DATA.netmatdir '/helpstrings.txt'],[DATA.localmatdir '/helpstrings.txt']);
    CheckFileUpdate([DATA.netmatdir '/DownArrow.mat'],[DATA.localmatdir '/DownArrow.mat'],'new');
    CheckFileUpdate([DATA.netmatdir '/vergversion.m'],[DATA.localmatdir '/vergversion.m']);

    
 function CheckFileUpdate(src, tgt, chkmode)
     if nargin < 3
        chkmode = 'change';
     end
    a = dir(src);
    b = dir(tgt);
    if isempty(a)
        fprintf('Missing %s - cant check update\n',src);
        return;
    end
    if isempty(b) %target does not exist - just copy
            try  %This often produces permission error
                copyfile(src,tgt);
            catch ME
                cprintf('errors',ME.message);
                fprintf('Error copying %s\n',tgt);
            end
    end
    if strncmp(chkmode,'new',3)         
        return;
    end
    if ~isempty(a) && ~isempty(b) && a.datenum > b.datenum
        yn = questdlg(sprintf('%s is newer. Copy to %s?',src,tgt),'Update Check','Yes','No','Yes');
        if strcmp(yn,'Yes')
            try  %This will produce and error becuase verg.m is in use. But the copy succeeds
                copyfile(src,tgt);
            catch ME
                cprintf('errors',ME.message);
                fprintf('possible error copying %s\n',tgt);
            end
        end
    end
    
    
function SaveFile(a,b,type)

    DATA = GetDataFromFig(a);
    if ~isfield(DATA,'stimfilename')
        DATA.stimfilename = ['/local/' DATA.binoc{1}.monkey '/stims/auto.stm'];
    end
    if strcmp(type,'current')
        filename = DATA.stimfilename;
        if exist(filename,'file')
            bakfile = [filename '.bak'];
            a = copyfile(filename,bakfile)
            if a
                fprintf('Saved backup in %s\n',bakfile);
            else
                fprintf('Couldnt save backup %s\n',bakfile)
            end
        end
        SaveExpt(DATA, filename);
    elseif strcmp(type,'update')
        CheckForUpdate(DATA)
    elseif strcmp(type,'layout')
        SaveLayout(DATA, DATA.layoutfile);
    elseif strcmp(type,'saveas')
        [a,b,c] = fileparts(DATA.stimfilename);
        if isempty(c)
            DATA.stimfilename = [DATA.stimfilename '.stm'];
        end
        [outname, path] = uiputfile(DATA.stimfilename, 'Save Expt As');
        if outname ~= 0
        SaveExpt(DATA, [path '/' outname]);
        end
    end
    
function SaveLayout(DATA, name)  

    fid = fopen(name,'w');
    for j = 1:length(DATA.winpos)
        it = findobj('tag',DATA.windownames{j},'type','figure');
        if length(it) == 1
            DATA.winpos{j} = get(it,'position');
        end
        fprintf(fid,'%s=%s\n',DATA.windownames{j},sprintf('%d ',DATA.winpos{j}));
    end
    fclose(fid);

function TextCallback(a,b)
    SendManualVals(a);

    
function SendManualVals(a, b)
% a can be a handel to the list, or
% a is DATA and b is the tag
    if ishandle(a)
        DATA = GetDataFromFig(get(a,'parent'));
        tag = get(a,'Tag');
    elseif nargin > 1
        DATA = a;
        tag = b;
        a = findobj(DATA.toplevel,'Tag',tag,'type','uicontrol');
    end
    str = get(a,'string');
    if strcmp(tag,'Expt2StimList')
        c = 'EB';
        o = 1+DATA.nextras(2);
    elseif strcmp(tag,'Expt3StimList')
        c = 'EC';
        o = 1+DATA.nextras(3);
    else
        o = 1+DATA.nextras(1);
        if size(str,2) > DATA.nt
            yn = questdlg('Nstim mismatch','That will Change N stims','OK','Cancel','OK');
        end
        c = 'EA';
    end

    for j = o:length(str)
            fprintf(DATA.outid,'%s%d=%s\n',c,j-o,str{j});
    end
    fprintf(DATA.outid,'EDONE\n');
     
    
function StimulusSelectMenu(a,b, fcn)
    DATA = GetDataFromFig(a);
    txt = ['mo=' fcn];
    DATA = InterpretLine(DATA, txt,'tobinoc');
    SetGui(DATA);
    set(DATA.toplevel,'UserData',DATA);
    
function EditValsMenu(a,b, fcn)
if strncmpi(fcn,'apply',5)
    SendManualVals(get(get(a,'parent'),'UserData'));
elseif strcmpi(fcn,'cancel')
    f = get(a,'parent');
    DATA = GetDataFromFig(get(f,'parent'));
    SendCode(DATA,'nt');
end
    
function EditText(a,b)
     sendvals = 0;
    DATA = get(gcf,'UserData');  %this only called from main window
    tag = get(a,'tag');
    e = find(strcmp(tag,{'Expt1StimList' 'Expt2StimList' 'Expt3StimList'}));
    DATA.listmodified(e) = 1;
     if double(b.Character) == 13
         str = get(a,'string');
     end
     
     if strcmp(b.Modifier,'control')
         if b.Key == 'g'
            sendvals = 1;
         end
     end
     if strcmp(b.Key,'escape')
         SendCode(DATA,'nt'); %makes binoc resend expt vals
     end
     
     if sendvals
         SendManualVals(a);
    end
     set(DATA.toplevel,'UserData',DATA);
    
   
 function EditList(a,b)
     id = get(a,'value')
     str = get(a,'string');
     c = get(a,'UserData');
     sendvals = 0;
%c(1) is index of current char
%c(2) is current line
%nb if this is changed with the mouse, watch out!
     DATA = GetDataFromFig(get(a,'parent'));
     
     
     
     if length(c) > 1 && c(2) ~= id  %line #changed
         c(1) = 0;
     end
     if isempty(c) || c(1) == 0;
         c= 1;
         str{id} = ' ';
     else
         c(1) = c(1)+1;
         if length(c) > 1
             set(a,'value',c(2));
             id = c(2);
         end
     end
     if double(b.Character) == 13
         newstr = input('Edit Values','Expt 1', length(str),str);
         c(1) = 0;
         set(a,'UserData',[c(1)]);
         sendvals = 1;
     elseif strcmp(b.Key,'downarrow')
         c(1) = 0;
         set(a,'UserData',[c(1) (id+1)]);
         sendvals = 1;
     elseif strcmp(b.Key,'uparrow')
         c(1) = 0;
         set(a,'UserData',[c(1) (id-1)]);
         sendvals = 1;
     elseif ~isempty(b.Character)
             if strcmp(b.Key,'backspace')
                 str{id} = ' ';
             else
                str{id}(c(1)) = b.Character;
             end
             set(a,'string',str);
             set(a,'UserData',[c(1) id],'value',id);
     end

if sendvals
    tag = get(a,'Tag');
    if strcmp(tag,'Expt2StimList')
        c = 'EB';
    elseif strcmp(tag,'Expt3StimList')
        c = 'EC';
    else
        c = 'EA';
    end

    for j = 1:length(str)
            fprintf(DATA.outid,'%s%d=%s\n',c,j-1,str{j});
    end
    fprintf(DATA.outid,'EDONE\n');
end

     fprintf('%d:%s %d (C%d)\n',id,str{id},get(a,'value'),c(1));
     
function MenuGui(a,b)
     DATA = GetDataFromFig(a);
     strs = get(a,'string');
     val = get(a,'value');
     if iscellstr(strs)
     str = strs{val};
     else
     str = strs(val,:);
     end
     tag = get(a,'Tag');
     switch tag
         case 'ElectrodeType'
             DATA.binoc{1}.Electrode = str;
             DATA.electrodeid = val;
     end
     set(DATA.toplevel,'UserData',DATA);
     
     
 function TextGui(a,b, type)
     DATA = GetDataFromFig(a);
     str = get(a,'string');
     if nargin == 2
         type = get(a,'Tag');
     end
     switch type
         case 'RptExpts'
             DATA.rptexpts = str2num(str);
             set(DATA.toplevel,'UserData',DATA);
         case 'cm'
             fprintf(DATA.outid,'cm=%s\n',str);
             LogCommand(DATA,sprintf('cm=%s',str));
             set(a,'string','');
         case 'nt'
             DATA.nstim(1) = str2num(str);
             fprintf(DATA.outid,'nt=%d\n',DATA.nstim(1));
             ReadFromBinoc(DATA);
         case 'n2'
             DATA.nstim(2) = str2num(str);
             fprintf(DATA.outid,'n2=%d\n',DATA.nstim(2));
             ReadFromBinoc(DATA);
         case 'n3'
             DATA.nstim(3) = str2num(str);
             fprintf(DATA.outid,'n3=%d\n',DATA.nstim(3));
             ReadFromBinoc(DATA);
         case 'em'
             DATA.mean(1) = str2num(str);
             fprintf(DATA.outid,'em=%.8f\n',DATA.mean(1));
             ReadFromBinoc(DATA);
         case 'm2'
             DATA.mean(2) = str2num(str);
             fprintf(DATA.outid,'m2=%.8f\n',DATA.mean(2));
             ReadFromBinoc(DATA);
         case 'm3'
             DATA.mean(3) = str2num(str);
             fprintf(DATA.outid,'m3=%.8f\n',DATA.mean(3));
             ReadFromBinoc(DATA);
         case {'ei' 'i2' 'i3'}
             fprintf(DATA.outid,'%s=%s\n',type,str);
             ReadFromBinoc(DATA);
         case 'st'
             DATA.stimtype(1) = strmatch(str,DATA.stimulusnames);
             set(DATA.toplevel,'UserData',DATA);
         case 'bs'
             DATA.stimtype(2) = strmatch(str,DATA.stimulusnames);
             set(DATA.toplevel,'UserData',DATA);
         case 'uf'
             DATA = InterpretLine(DATA, ['uf=' str],'fromgui','tobinoc');
             set(DATA.toplevel,'UserData',DATA);
         otherwise
             DATA.binoc{DATA.currentstim}.(type) = str2num(str);
             fprintf(DATA.outid,'%s=%s\n',type,str);
             ReadFromBinoc(DATA);
             
             
     end
             
 function outprintf(DATA,varargin)
 %send to binoc.  ? reomve comments  like in expt read? 
 
     if DATA.outid
         fprintf(DATA.outid,varargin{:});
     end
     
 function myprintf(fid,varargin)
     if fid > 0
         fprintf(fid,varargin{:});
     end
     
 function SendStr(a,b, str)
     DATA = GetDataFromFig(a);
     fprintf(DATA.outid,'%s\n',str);
     DATA = ReadFromBinoc(DATA);
     SetGui(DATA);
    
     
 function ReadIO(a,b, flag)
     DATA = GetDataFromFig(a);

     
     if flag == 2
         fprintf(DATA.outid,'QueryState\n');
        DATA = ReadFromBinoc(DATA);   
        SetGui(DATA);
     elseif flag == 3
         stop(DATA.timerobj)
         fprintf(DATA.outid,'NewMatlab\n');
        DATA = ReadFromBinoc(DATA,'reset');   
        SetGui(DATA);
        start(DATA.timerobj);
     elseif flag == 4
        stop(DATA.timerobj)
     elseif flag == 5
        DATA = ReadFromBinoc(DATA,'reset');   
        fprintf(DATA.outid,'\neventcontinue\nEDONE\n');
        if ~strcmp(get(DATA.timerobj,'Running'),'on')
        start(DATA.timerobj);
        end
     elseif flag == 6
        stop(DATA.timerobj);
         DATA = OpenPipes(DATA, 0);
         SendState(DATA,'all');
         fprintf(DATA.outid,'QueryState\n');
        DATA = ReadFromBinoc(DATA,'verbose2','expect');   
        start(DATA.timerobj);
        
     elseif flag == 7 %obsolete
         if DATA.verbose(1) > 0
             DATA.verbose(1) = 0;
             set(a,'Label','verbose pipes');
         else
             DATA.verbose = 2;
             set(a,'Label','Quiet pipes');
             if DATA.frombinocfid <= 0
                 DATA.frombinocfid = fopen('/local/frombinoc.txt','a');
             end

         end
         fprintf(DATA.outid,'verbose=%d\n',DATA.verbose(2));
         set(DATA.toplevel,'UserData',DATA);
     elseif flag == 8
        DATA = ReadFromBinoc(DATA,'reset','verbose2');
     else
        DATA = ReadFromBinoc(DATA);   
        SetGui(DATA);
     end
        CheckTimer(DATA);

function SetVerbose(a,b, flag)
     DATA = GetDataFromFig(a);

     if flag == 0
         DATA.verbose = zeros(size(DATA.verbose));
         SetMenuCheck(a,'exclusive', 1);
     else
         DATA.verbose(flag) = ~DATA.verbose(flag);
         if DATA.verbose(flag)
             set(a,'checked','on');
         else
             set(a,'checked','off');
         end             
     end
     set(DATA.toplevel,'UserData',DATA);
        
 function DATA = CheckExptMenus(DATA)
     new = 0;
     for j = 1:3
         it = findobj(DATA.toplevel,'Tag',['Expt' num2str(j) 'List']);
         id = strmatch(DATA.exptype{j},DATA.expmenucodes{j},'exact');
         if isempty(id)
             DATA.expmenucodes{j} = {DATA.expmenucodes{j}{:} DATA.exptype{j}};
             a = find(strcmp(DATA.exptype{j},{DATA.comcodes.code}));
             if isempty(a)
                 str = 'Unknown';
             else
                 str = DATA.comcodes(a).label;
             end
             DATA.expstrs{j}{end+1} = str;
             set(it,'string',DATA.expstrs{j});
             new = new+1;             
         end
     end
if new
    set(DATA.toplevel,'UserData',DATA);
end
        
 function SetGui(DATA,varargin)
     if ~isfield(DATA,'toplevel')
         return;
     end
     j = 1;
     while j <= length(varargin)
         if strncmpi(varargin{j},'set',3)
             set(DATA.toplevel,'UserData',DATA);
         end
         j = j+1;
     end
    DATA= CheckExptMenus(DATA);
    SetTextItem(DATA.toplevel,'Expt1Nstim',DATA.nstim(1));
    SetTextItem(DATA.toplevel,'Expt2Nstim',DATA.nstim(2));
    SetTextItem(DATA.toplevel,'Expt3Nstim',DATA.nstim(3));
    SetTextItem(DATA.toplevel,'Expt1Incr',DATA.binoc{1}.ei);
    SetTextItem(DATA.toplevel,'Expt2Incr',DATA.binoc{1}.i2);
    SetTextItem(DATA.toplevel,'Expt3Incr',DATA.binoc{1}.i3);
    SetTextItem(DATA.toplevel,'Expt1Mean',DATA.mean(1));
    SetTextItem(DATA.toplevel,'Expt2Mean',DATA.mean(2));
    SetTextItem(DATA.toplevel,'Expt3Mean',DATA.mean(3));
    SetTextItem(DATA.toplevel,'DataFileName',DATA.binoc{1}.uf);
    SetTextItem(DATA.toplevel,'binoc.nr',DATA.binoc{1}.nr);
    SetTextItem(DATA.toplevel,'RptExpts',DATA.rptexpts);
    id = strmatch(DATA.exptype{1},DATA.expmenucodes{1},'exact');
    SetMenuItem(DATA.toplevel, 'Expt1List', id);
    id = strmatch(DATA.exptype{2},DATA.expmenucodes{2},'exact');
    SetMenuItem(DATA.toplevel, 'Expt2List', id);
    id = strmatch(DATA.exptype{3},DATA.expmenucodes{3},'exact');
    SetMenuItem(DATA.toplevel, 'Expt3List', id);
    SetMenuItem(DATA.toplevel, 'ForegroundType', DATA.stimtype(1));
    SetMenuItem(DATA.toplevel, 'BackgroundType', DATA.stimtype(2));
    SetToggleItem(DATA.toplevel, 'XYR', DATA.showxy(1));
    SetToggleItem(DATA.toplevel, 'XYL', DATA.showxy(2));
    SetToggleItem(DATA.toplevel, 'XYB', DATA.showxy(3));
    it= findobj(DATA.toplevel,'Tag','CurrentStimLabel');
    set(it,'string',DATA.stimlabels{DATA.currentstim});
    if DATA.currentstim > 1
        set(it,'backgroundcolor','r');
    else
        set(it,'backgroundcolor', DATA.windowcolor);
    end
    it = findobj(DATA.toplevel,'Tag','RunButton');
    if DATA.inexpt
        set(it,'string','Cancel');
    elseif DATA.optionflags.ts
        set(it,'string','Store');
    else
        set(it,'string','Run','backgroundcolor',DATA.windowcolor);
        if ~DATA.optionflags.py  %%Human Psych
            set(it,'backgroundcolor','r');
        end
    end
    
    ot = findobj('tag',DATA.windownames{2},'type','figure');
       f = fields(DATA.optionflags);
       for j = 1:length(f)
           if length(ot) == 1
               it = findobj(ot,'Tag',f{j});
               set(it,'value',DATA.optionflags.(f{j}));
           end
           it = findobj(DATA.toplevel,'Tag',f{j});
           if length(it) == 1
           set(it,'value',DATA.optionflags.(f{j}));
           end
       end
    ot = findobj('tag',DATA.windownames{3},'type','figure');
    SetSoftOffWindow(DATA,ot);
    
    [a,j] = min(abs(DATA.binoc{1}.xyfsd - DATA.xyfsdvals));
    ot = findobj(DATA.toplevel,'tag','FSD','type','uicontrol');
    set(ot,'value',j);

    ot = findobj(DATA.toplevel,'tag','OptionContextMenu');
    if ~isempty(ot);
        m = get(ot,'children');
        for k = 1:length(m)
        c = get(m(k),'children');
        for j = 1:length(c)
            tag = get(c(j),'tag');
            if isfield(DATA.optionflags,tag) && DATA.optionflags.(tag)
                set(c(j),'checked','on');
            else
                set(c(j),'checked','off');
            end
        end
        end
    end
    
    
    

 function SetTextItem(top, tag, value, varargin)
 it = findobj(top,'Tag',tag);
 if ~isempty(it)
     if ischar(value)
     set(it,'string',value);
     else
     set(it,'string',num2str(value));
     end
 end

 function SetToggleItem(top, tag, value, varargin)
 it = findobj(top,'Tag',tag);
 if ~isempty(it)
     set(it,'value',value);
 end
 
function SetMenuItem(top, tag, value, varargin)
if length(value) == 1
     it = findobj(top,'Tag',tag);
     if ~isempty(it)
         str = get(it,'string');
         if value > size(str,1)
             fprintf('Value %d out of range for %s\n',value, tag);
         else
             set(it,'value',value);
         end
     end
elseif length(value) > 1
     it = findobj(top,'Tag',tag);
     if ~isempty(it)
         set(it,'value',value(1));
     end
end

function CheckInput(a,b, fig, varargin)
    DATA = get(fig,'UserData');
    if DATA.servofig
        ServoDrive('readposition','quiet');
    end
    ReadFromBinoc(DATA, 'auto');
    if DATA.verbose(1) > 1
    fprintf('Timer read over at %s\n',datestr(now));
    end
    
    
 
 function DATA = ReadFromBinoc(DATA, varargin)
     global rbusy;
     persistent lastts;
     persistent lasttnone;
     
     if isempty(lastts)
         lastts = 0;
         lasttnone = 0;
     end
     verbose = DATA.verbose;
     autocall = 0;
     expecting = 0;
     j = 1;
     while j <= length(varargin)
         if strncmpi(varargin{j},'verbose',5)
             verbose(1) = 1;
             if strncmpi(varargin{j},'verbose2',8)
                 verbose = ones(size(verbose));
             end
         elseif strncmpi(varargin{j},'auto',4)
             autocall = 1;
         elseif strncmpi(varargin{j},'expecting',5)
            expecting = 1;
         elseif strncmpi(varargin{j},'reset',5)
             rbusy = 0;
         elseif ischar(varargin{j})
             fprintf('%s',varargin{j});
         end
         j = j+1;
     end
     if rbusy > 0
         fprintf('ReadBinoc busy at %s since %s\n',datestr(now),datestr(rbusy));
         return;
     end
     ts = now;
     rbusy = ts;    
         
     if DATA.outid <= 1
         return;
     end
     if verbose(2)
     fprintf('%s:',datestr(now,'HH:MM:SS.FFF'))
     end
     myprintf(DATA.frombinocfid,'ReadBinoc%s\n',datestr(now));
     fprintf(DATA.outid,'whatsup\n');
     a = fread(DATA.inid,14);
     if verbose(2)
         fprintf('OK\n');
     end
     if expecting && strcmp(char(a'),'SENDING000000')
         fprintf('0 Bytes, but expect input. Trying again.\n');
         a = fread(DATA.inid,14);
     end
     rbusy = 0;
     if DATA.frombinocfid > 0 && ~isempty(a)
         fprintf(DATA.frombinocfid,'%s %s',datestr(now),char(a'));
     end
     if strncmp(char(a'),'SENDINGstart1',12)
        a = fread(DATA.inid,14);
        nbytes = sscanf(char(a'),'SENDING%d');
        fprintf('Start String\n');
     elseif strncmp(char(a'),'SENDING',7)
         nbytes = sscanf(char(a'),'SENDING%d');
         lastts = ts;
     else
         s = char(a');
         if ts - lasttnone > 5 /(24 * 60 * 60)
             fprintf('No Bytes %s %s\n',s,datestr(ts));
             lasttnone = ts;
         end
         if length(s)
             id = strfind(s,'SENDING')
             if length(id)
                 fprintf('Found SENDING at char %d\n',id);
                 nbytes = sscanf(s(id(1)),'SENDING%d')
             else
                 a = s(end);
                 while char(a) ~= 'G' | strcmp(s(end-6:end),'SENDING') == 0
                     a = fread(DATA.inid,1);
                     s = [s char(a)];
                 end
                 a = fread(DATA.inid,7);
                 nbytes = sscanf(char(a'),'%d');
                 fprintf('Read %s\n',s);
             end
         else
             nbytes = 0;
             %if binoc has resstarted, reopen pipes
             d = dir('/tmp/binocisnew');
             if isfield(d,'datenum')
                 if d.datenum > lastts || isempty(lastts)
                     lastts = ts;
                     if DATA.autoreopen
                         fprintf('Reopening pipes\n');
                         pause(1);
                         ReadIO(DATA,[],6);
                         if isfield(DATA,'reopenstr') && ~isempty(DATA.reopenstr)
                             binocprintf(DATA,'%s\n',DATA.reopenstr);
                         end
                     else
                         fprintf('Binoc Restarted - reopen pipes\n');
                     end
                 end
             end
         end
     end
     if verbose(2)
     fprintf('Need %d bytes\n',nbytes);
     end
     if nbytes > 0
         a = fread(DATA.inid,nbytes);
         if verbose(2)
         fprintf('%s',char(a'));
         fprintf('Read %d bytes took %.2f\n',length(a),mytoc(ts));
         end
         myprintf(DATA.frombinocfid,'Read %d bytes at %s\n',nbytes,datestr(now));
         myprintf(DATA.frombinocfid,'%s',char(a'));
         DATA = InterpretLine(DATA,char(a'),'frombinoc');
         if isfield(DATA,'toplevel')
             set(DATA.toplevel,'UserData',DATA);
         end
         myprintf(DATA.frombinocfid,'Finished at %s\n',datestr(now));
         lastts = ts;
     end
     rbusy = 0;
     
function OpenUffFile(a,b, type)
        DATA = GetDataFromFig(a);
        fprintf(DATA.outid,'\\openuff\n');


function Expt = ExptSummary(DATA)
    Expt.first = DATA.Trial.Trial;
    Expt.Stimvals.et = DATA.exptype{1};
    Expt.Stimvals.e2 = DATA.exptype{2};
    Expt.Stimvals.e3 = DATA.exptype{3};
    Expt.Stimvals.ei = DATA.incr(1);
    Expt.Stimvals.i2 = DATA.incr(2);
    Expt.Stimvals.i3 = DATA.incr(3);
    Expt.Stimvals.st = DATA.stimulusnames{DATA.stimtype(1)};
    Expt.Stimvals.Bs = DATA.stimulusnames{DATA.stimtype(2)};
    Expt.Start = now;

        
function DATA = RunButton(a,b, type)
        DATA = GetDataFromFig(a);
        fprintf('Run Hit Inexpt %d, type %d\n',DATA.inexpt,type);
        DATA.newexptdef = 0;
        DATA.matexpres = [];
        if type == 1
            if DATA.inexpt == 0 %sarting a new one. Increment counter
                if DATA.optionflags.exm && ~isempty(DATA.matexpt)
                    fprintf('Running %s\n',DATA.matexpt);
                    DATA.matexpres = eval(DATA.matexpt);
                    SendCode(DATA,'exp');
                end
                if DATA.listmodified(1)
                    SendManualVals(DATA,'Expt1StimList');
                end
                if DATA.listmodified(2)
                    SendManualVals(DATA,'Expt2StimList');
                end
                if DATA.listmodified(3)
                    SendManualVals(DATA,'Expt3StimList');
                end
                DATA.listmodified = [0 0 0];
                fprintf(DATA.outid,'\\expt\n');
                DATA.nexpts = DATA.nexpts+1;
                DATA.Expts{DATA.nexpts} = ExptSummary(DATA);
                DATA.optionflags.do = 1;
                DATA.exptstoppedbyuser = 0;
                DATA = ReadFromBinoc(DATA);
                %            DATA = GetState(DATA);
            else
                DATA.rptexpts = 0;
                fprintf(DATA.outid,'\\ecancel\n');
                DATA = AddTextToGui(DATA,'Cancelled','norec');
                if DATA.nexpts > 0
                DATA.Expts{DATA.nexpts}.last = DATA.Trial.Trial;
                DATA.Expts{DATA.nexpts}.End = now;
                end
                DATA.optionflags.do = 0;
                DATA.exptstoppedbyuser = 1;
            end
        elseif type == 2
            fprintf(DATA.outid,'\\estop\n');
            DATA.rptexpts = 0;
            DATA.Expts{DATA.nexpts}.last = DATA.Trial.Trial;
            DATA.Expts{DATA.nexpts}.End = now;
            ti = 1 + DATA.Trial.Trial-DATA.Expts{DATA.nexpts}.first;
            DATA.optionflags.do = 0;
            DATA = AddTextToGui(DATA,['Stopped after ' num2str(ti) ' Trials']);
            DATA.exptstoppedbyuser = 1;
        end
%if expt is over, EXPTOVER should be received. - query state then
%    DATA = GetState(DATA);
%    DATA = ReadFromBinoc(DATA);
    set(DATA.toplevel,'UserData',DATA);
    
    SetGui(DATA);
    CheckTimer(DATA);
     
    function TestIO(a,b)
        
        DATA = GetDataFromFig(a);
 %       if DATA.outid > 0
 %           fclose(DATA.outid);
 %       end
        %fclose('all');
        if ~isfield(DATA,'outpipe')
            DATA = OpenPipes(DATA, 1);
        end
        if DATA.outid <= 0
        DATA.outid = fopen(DATA.outpipe,'w');
        end
        fprintf(DATA.outid,'ed+10\n');
%        fclose(DATA.outid);
%        DATA.outid = 0;
        set(DATA.toplevel,'UserData',DATA);
        
function ElectrodeMoved(F, pos) %called by ServoDrive
%ServoDrive sends position in microns. Binoc wants mm            
if ~isfigure(F) %if verg was close before servowindow
    return;
end
DATA = get(F, 'UserData');
if strcmp(pos,'close') %Servo Contoller Closing
    DATA.servofig = 0;
    set(DATA.toplevel,'UserData',DATA);
else
    outprintf(DATA,'!seted=%.3f\n',pos./1000);
end

function ElectrodePopup(a,b, fcn, varargin)
  DATA = GetDataFromFig(a);

  if ~isempty(DATA.servoport)
      X = ServoDrive('ttyname',DATA.servoport,'callback',{@ElectrodeMoved, DATA.toplevel});
      DATA.servofig = X.toplevel;
      set(DATA.toplevel,'UserData',DATA);
  end
  

 
function PenLogPopup(a,b)
  DATA = GetDataFromFig(a);
  cntrl_box = findobj('Tag',DATA.windownames{9},'type','figure');
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
if length(DATA.winpos{9}) ~= 4
    DATA.winpos{9} = get(DATA.toplevel,'position');
end
cntrl_box = figure('Position', DATA.winpos{9},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{9},'Name','Penetration Log','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
            set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);
    set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);

    nr = 5;
    nc = 7;
    bp = [0.01 0.99-1/nr 1./nc 0.98./nr];

    

    
    bp(1) = 0.01;
    bp(3) = 0.3;
    uicontrol(gcf,'style','text','string','Penetration Number', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.98./nc;
    
    uicontrol(gcf,'style','edit','string',num2str(GetValue(DATA,'Pn')), ...
        'units', 'norm', 'position',bp,'Tag','Pn','callback',{@TextGui, 'Pn'});

    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = 0.1;
    uicontrol(gcf,'style','text','string','X', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.98./nc;
    uicontrol(gcf,'style','edit','string',num2str(GetValue(DATA,'Xp')), ...
        'units', 'norm', 'position',bp,'Tag','Xp','callback',{@TextGui, 'Xp'});
    
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = 0.1;
    uicontrol(gcf,'style','text','string','Y', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.98./nc;
    uicontrol(gcf,'style','edit','string',num2str(GetValue(DATA,'Yp')), ...
        'units', 'norm', 'position',bp,'Tag','Yp','callback',{@TextGui, 'Yp'});

    bp(1) = 0.01;
    bp(2) = bp(2)-1./nr;
    uicontrol(gcf,'style','text','string','Electrode', ...
        'units', 'norm', 'position',bp);

    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = 3./nc;
   uicontrol(gcf,'style','pop','string',DATA.electrodestrings, ...
        'units', 'norm', 'position',bp,'value',DATA.electrodeid,'Tag','ElectrodeType','callback',{@MenuGui});
 
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = 0.2;
    uicontrol(gcf,'style','text','string','Impedance', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 1./nc;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.eZ), ...
        'units', 'norm', 'position',bp,'Tag','Impedance','callback',{@MenuGui});
    

    
    bp(2) = bp(2)-1./nr;
    bp(1) = 0.01;
    bp(3) = 0.9./nc;
    uicontrol(gcf,'style','text','string','User', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','userlabel');
    bp(1) = 1./nc;
    bp(3) = 1.9./nc;
    id = find(strcmp(DATA.binoc{1}.ui,DATA.userstrings));
    if isempty(id)
        id = 1;
    end
    uicontrol(gcf,'style','pop','string',DATA.userstrings, ...
        'units', 'norm', 'position',bp,'value',id,'Tag','Experimenter','callback',{@MenuGui});

    bp(1) = 3./nc;
    bp(3) = 0.9./nc;
    uicontrol(gcf,'style','text','string','Monkey', ...
        'units', 'norm', 'position',bp);

    bp(1) = bp(1)+bp(3);
    bp(3) = 1.9./nc;
    id = find(strcmp(DATA.binoc{1}.monkey,DATA.monkeystrs));
    if isempty(id)
        id = 1;
    end
    uicontrol(gcf,'style','pop','string',DATA.monkeystrings, ...
        'units', 'norm', 'position',bp,'value',id,'Tag','Monkey','callback',{@MenuGui});

    bp(2) = bp(2)-1./nr;
    bp(1) = 0.01;
    bp(3) = 0.2;
    uicontrol(gcf,'style','text','string','Tube Protrusion', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.1;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.ePr), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','protrudes','callback',{@MenuGui});

    bp(1) = bp(1)+bp(3);
    bp(3) = 0.2;
    uicontrol(gcf,'style','text','string','Coarse mm', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.1;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.coarsemm), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','coarsemm','callback',{@MenuGui});

    bp(1) = bp(1)+bp(3);
    bp(3) = 0.2;
    uicontrol(gcf,'style','text','string','Adapter', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.2;
    uicontrol(gcf,'style','edit','string',DATA.binoc{1}.adapter, ...
        'units', 'norm', 'position',bp,'value',1,'Tag','adapter','callback',{@MenuGui});

    bp(2) = bp(2)-1./nr;
    bp(1) = 0.01;
    bp(3) = 0.2;
    
    
    id = find(strcmp(DATA.binoc{1}.hemi,{'Left' 'Right' 'NotSet'}));
    if isempty(id)
        id = 1;
    end
    uicontrol(gcf,'style','text','string','Hemisphere', ...
        'units', 'norm', 'position',bp);
    bp(1) = bp(1)+bp(3);
    bp(3) = 0.2;
    uicontrol(gcf,'style','pop','string','Left|Right|Unknown', ...
        'units', 'norm', 'position',bp,'value',id,'Tag','hemisphere','callback',{@MenuGui});
    
    bp(1) = 0.99-bp(3);
    uicontrol(gcf,'style','pushbutton','string','Apply', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','Penset','callback',@OpenPenLog);
    bp(1) = bp(1)-bp(3)-0.01;
    uicontrol(gcf,'style','pushbutton','string','Plot', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','PlotPen','callback',@OpenPenLog);
    hm = uimenu(gcf,'label','Mark');
    uimenu(hm,'label','Entered Brain','callback',{@MarkComment 'Entered Brain'});
   
    
set(gcf,'CloseRequestFcn',{@CloseWindow, 9});

function MarkComment(a,b,txt);
  DATA = GetDataFromFig(a);
  outprintf(DATA,'cm=%s\n',txt);
        

function OptionPopup(a,b)
  DATA = GetDataFromFig(a);
  cntrl_box = findobj('Tag',DATA.windownames{2},'type','figure');
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
if length(DATA.winpos{2}) ~= 4
    DATA.winpos{2} = get(DATA.toplevel,'position');
end
f = fields(DATA.optionflags);
nc = 4;
nr = ceil((length(f)+nc-1)/nc);
scrsz = get(0,'Screensize');
cntrl_box = figure('Position', DATA.winpos{2},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{2},'Name','Options','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);
            set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);

bp = [0.01 0.99-1/nr 1./nc 1./nr];
for j = 1:length(f)
    bp(1) = floor((j-1)/nr) .* 1./nc;
    bp(2) = 1- ((1+rem(j-1,nr)) .* 1./nr);
    if strncmp('lbl',f{j},3)
    uicontrol(gcf,'style','text','string',[DATA.optionstrings.(f{j}) ':'], ...
        'units', 'norm', 'position',bp,'value',DATA.optionflags.(f{j}),'Tag',f{j},...
        'callback',{@HitToggle, f{j}},'foregroundcolor','r');
    else
    uicontrol(gcf,'style','checkbox','string',[DATA.optionstrings.(f{j}) '(' f{j} ')'], ...
        'units', 'norm', 'position',bp,'value',DATA.optionflags.(f{j}),'Tag',f{j},'callback',{@HitToggle, f{j}});
    end
end
nf = j;
f = fields(DATA.stimflags{1});
for j = 1:length(f)
    str = DATA.stimflagnames.(f{j});
    k = nf+j; 
    bp(1) = floor(k/nr) .* 1./nc;
    bp(2) = 1- (rem(k,nr) .* 1./nr);
    uicontrol(gcf,'style','checkbox','string',str, ...
        'units', 'norm', 'position',bp,'value',DATA.stimflags{1}.(f{j}),'Tag',f{j},'callback',{@StimToggle, f{j}});

end

function CodesPopup(a,b, type)  

  DATA = GetDataFromFig(a);
  src = a;
  if isnumeric(type) | strmatch(type,{'bycode' 'bylabel' 'bygroup' 'numeric' 'printcodes' 'byhelp'},'exact')
      lst = findobj(get(get(a,'parent'),'parent'),'Tag','CodeListString');
      if isnumeric(type)
          if type == 8
            set(lst,'string','Codes controlling PsychoPhysics/Reward/Eye movement');
          else
          end
          id = find(bitand([DATA.comcodes.group],type) > 0);
        [c,b] = sort({DATA.comcodes(id).code});
        b = id(b);
      elseif strcmp(type,'printcodes')
          F = get(a,'parent');
         [outname, path] = uiputfile([DATA.localmatdir '/BinocCodes.txt'], 'Save Binoc Codes');
         if ~ischar(outname) %user cancelled
             return;
         end
         it = findobj(F,'tag','CodeListString');
         txt = get(it,'String');
         fid = fopen(outname,'w');
         for j = 1:size(txt,1)
             fprintf(fid,'%s\n',deblank(txt(j,:)));
             code = regexprep(txt(j,:),'\s.*','');
             if isfield(DATA.helpkeys.extras,code)
                 for k = 1:length(DATA.helpkeys.extras.(code))
                     fprintf(fid,'     %s\n',DATA.helpkeys.extras.(code){k});
                 end
             end
         end
         fclose(fid);
         return;
      elseif strcmp(type,'bycode')
          set(lst,'string','Alphabetical by code.  :* = more help with mouse click');
          [c,b] = sort({DATA.comcodes.code});
      elseif strcmp(type,'bylabel')
          set(lst,'string','Alphabetical by Label :* = more help with mouse click');
          [c,b] = sort({DATA.comcodes.label});
      elseif strcmp(type,'byhelp')
          set(lst,'string','Alphabetical by Help :* = more help with mouse click');
          f = fields(DATA.helpstrs);
          for j = 1:length(f)
              helpstr{j} = DATA.helpstrs.(f{j});
              cid(j) = find(strcmp(f{j},{DATA.comcodes.code}));
          end
          [c, b] = sort(helpstr);
          b = cid(b);
      elseif strcmp(type,'bygroup')
          set(lst ,'string','Groups: :* = more help with mouse click');
          id = find(bitand(1,[DATA.comcodes.group]));
          [c,b] = sort({DATA.comcodes(id).code});
          labels{1} = 'Stimulus Rendering';
          id = find(bitand(2,[DATA.comcodes.group]));
          [c,d] = sort({DATA.comcodes(id).code});
          labels{2} = 'Psychophysics/Reward';
          b = [b 0 d];
          id = find(bitand(4,[DATA.comcodes.group]));
          [c,d] = sort({DATA.comcodes(id).code});
          labels{3} = 'Group 3';
          b = [b 0 d];
          id = find(bitand(8,[DATA.comcodes.group]));
          [c,d] = sort({DATA.comcodes(id).code});
          labels{4} = 'Group 4';
          b = [b 0 d];
          id = find(bitand(16,[DATA.comcodes.group]));
          [c,d] = sort({DATA.comcodes(id).code});
          labels{5} = 'Group 5';
          b = [b 0  d];
      else
          set(lst,'string','Numerical');
          b = 1:length(DATA.comcodes);
      end
      nl=1;
      a = get(lst,'string');
      nlab = 0;
      nc = 0;
      for j = 1:length(b)
          if b(j) == 0
              code = '';
          else
              code = DATA.comcodes(b(j)).code;
          end
          if ~strcmp(code,'xx')
          ns = max([5 - length(code) 1]);          
          ns = 1+ round(ns-1) .* 1.6;
          nc = nc+1;
          if b(j) > 0
              s = sprintf('%s%*s%s',code,ns,' ',DATA.comcodes(b(j)).label);
          else
              nlab = nlab+1;
              a(nc+nl,1) = ' ';
              nl = nl+1;
              s = labels{nlab};
          end
          if isfield(DATA.helpstrs,code)
              if isfield(DATA.helpkeys.extras,code)
                  s = [s '*   ;*  ' DATA.helpstrs.(code)];
              else
                  s = [s '   ;   ' DATA.helpstrs.(code)];
              end
              keys{j+nl} = DATA.helpkeys.KeyWords.(code);
          end
          a(nc+nl,1:length(s)) = s;
          a(nc+nl,2+length(s):end) = 0;
          end
      end
      a = a(1:nc+nl,:);
      cmenu = uicontextmenu;
      set(cmenu,'UserData',lst);
      uimenu(cmenu,'label','Help','Callback',{@CodeListMenu, 'Help'});
      a = AddOptionHelp(DATA,a);
      set(lst,'string',a);
      setappdata(GetFigure(lst),'HelpKeyList',keys);
      setappdata(GetFigure(lst),'OldText',a);
      %set(lst,'uicontextmenu',cmenu);    
      
  end
  if ~strncmp(type,'popup',5)
      return;
  end
  cntrl_box = findobj('Tag',DATA.windownames{4},'type','figure');
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
  cntrl_box = figure('Position', DATA.winpos{4},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{4},'Name','Code list','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);
        set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);

    hm = uimenu(cntrl_box,'Label','List by');
    sm = uimenu(hm,'Label','By Code','callback',{@CodesPopup, 'bycode'});
    sm = uimenu(hm,'Label','By Label','callback',{@CodesPopup, 'bylabel'});
    sm = uimenu(hm,'Label','By Group','callback',{@CodesPopup, 'bygroup'});
    sm = uimenu(hm,'Label','Psych/Reward','callback',{@CodesPopup, 8 });
    sm = uimenu(hm,'Label','Numerical','callback',{@CodesPopup, 'numeric'});
    sm = uimenu(hm,'Label','Help','callback',{@CodesPopup, 'byhelp'});
    helpmenu = sm;
    hm = uimenu(cntrl_box,'Label','Print','callback',{@CodesPopup, 'printcodes'});
    hm = uimenu(cntrl_box,'Label','Search');
    sm = uimenu(hm,'Label','Ignore case','callback',{@SearchList, 'IgnoreCase'},'Tag','IgnoreCase','checked','on');
    
    uicontrol(gcf,'style','pop','string','Search: All|Search: Codes|Search: Labels|Search: Help','tag','SearchMode',...
        'units','norm', 'Position',[0 0.01 0.3 0.08]);

    srch = uicontrol(gcf, 'Style','edit','String', '',...
        'callback', @SearchList, ...
        'units','norm', 'Position',[0.3 0.01 0.99 0.08]);

    lst = uicontrol(gcf, 'Style','list','String', 'Code List :* = more help with mouse click',...
        'HorizontalAlignment','left',...
        'Max',10,'Min',0,...
        'Tag','CodeListString',...
        'callback',@HelpHit,...
        'units','norm', 'Position',[0.01 0.085 0.99 0.91]);
a = get(lst,'string');
nc = 1;
keys = {};
for j = 1:length(DATA.comcodes)
    code = DATA.comcodes(j).code;
    if ~strcmp(code,'xx')
        ns = max([5 - length(code) 1]);
        ns = 1+ round(ns-1) .* 1.6;
        s = sprintf('%s%*s%s',code,ns,' ',DATA.comcodes(j).label);
        if isfield(DATA.helpstrs,code)
            s = [s '  : ' DATA.helpstrs.(code)];
            keys{j} = DATA.helpkeys.KeyWords.(code);
        end
        nc = nc+1;
        a(nc,1:length(s)) = s;
    else
        nc = nc;
    end
end
a = AddOptionHelp(DATA,a);

set(lst,'string',a);
setappdata(GetFigure(lst),'HelpKeyList',keys);
setappdata(GetFigure(lst),'OldText',a);

if strcmp(type,'popuphelp')
    CodesPopup(helpmenu,b,'byhelp');
end

function HelpHit(a,b)
DATA = GetDataFromFig(a);

str = get(a,'string');
l = get(a,'value');
code = str(l,:);
code = regexprep(code,'\s.*','');
fpos = get(GetFigure(a),'position');
if isfield(DATA.helpkeys.extras,code)
    cm = uicontextmenu;
    X = DATA.helpkeys.extras.(code);
    for j = 1:length(X)
        uimenu(cm,'label',X{j});
    end
    set(cm,'position', [50 fpos(4)/2],'visible','on');
end

function a = AddOptionHelp(DATA,a)
        
if isfield(DATA.helpkeys,'options')
    s = 'Binary options (op=+xx to set. op=-xx to unset)';
    a(end+1,1:length(s)) = s;
    
    f = fields(DATA.optionflags);
    for j = 1:length(f)
        if isfield(DATA.helpkeys.options,f{j})
            s = sprintf('+%s %s   ;   %s',f{j},DATA.optionstrings.(f{j}),DATA.helpkeys.options.(f{j}));
        else
            s = sprintf('+%s %s\n',f{j},DATA.optionstrings.(f{j}));
        end
        a(end+1,1:length(s)) = s;
    end

         
    f = fields(DATA.helpkeys.options);
    for j = 1:length(f)
        s = sprintf('+%s %s',f{j},DATA.helpkeys.options.(f{j}));
        a(end+1,1:length(s)) = s;
    end
end

function ToggleCheck(a)
    if strcmp(get(a,'checked'),'off')
        set(a,'checked','on');
    else
        set(a,'checked','off');
    end

function SearchList(a,b, varargin)

    
    tag = get(a,'tag');
    if strcmp(tag,'IgnoreCase')
        ToggleCheck(a);
        return;
    end
    newpattn = 0;
    pttn = get(a,'string');
    lastpttn = get(a,'UserData');
    set(a,'UserData',pttn);    
    F = get(a,'parent');
    findn = getappdata(F,'findn');
    it = findobj(F,'tag','CodeListString');
    if isempty(findn) %hit return again
        findn = 1;
    elseif ~strcmp(pttn,lastpttn)%new serach
        newpattn = 1;
    else
        setappdata(F,'findn',[]);
        if isappdata(F,'OldText')
            txt = getappdata(F,'OldText');
            set(it,'string',txt);
            set(F,'Name','Code List');
            return;
        end
    end
    if strcmp(pttn, lastpttn)
        findn = findn+1;
    end
    
    ignorecase = 0;
    mit = findobj(F,'tag','IgnoreCase');
    if strcmp(get(mit,'checked'),'on')
        ignorecase = 1;
    end
    sm = findobj(F,'tag','SearchMode');
    searchmode = get(sm,'value');
    if newpattn
        txt = getappdata(F,'OldText');
    else
        txt = get(it,'String');
        setappdata(F,'OldText',txt);
    end
    keys = getappdata(F,'HelpKeyList');
    keys{size(txt,1)+1} = '';
    found = [];
    for j = 1:size(txt,1)
        t = txt(j,:);
        if isempty(strfind(t,':'))
            t = [t ' : '];
        end
        if searchmode == 2 %just codes
            s = regexprep(t,'\s.*','');
        elseif searchmode == 3 %just labels
            s = regexprep(t,'\s(.*):.*','$1');
        elseif searchmode == 4 %just help
            s = regexprep(t,'.* : ','');
        else
            s = [txt(j,:) keys{j}];
        end
        if ignorecase
            x = strfind(lower(s),lower(pttn));
        else
            x = strfind(s,pttn);
        end
        if ~isempty(x)
            found(j) = 1;
        end
    end
    found = find(found);
    if ~isempty(found)
       if findn > length(found)
           findn = 1;
       end
       if length(found) == 0
%           set(it,'value',found(findn));
       else
           str = sprintf('%d matches for %s',length(found),pttn);
           txt(1,1:length(str)) = str;
           txt(1,(length(str)+1):end) = ' ';
           set(it,'value',1);
           set(it,'string',txt([1 found],:));
       end
        set(F,'Name',sprintf('%d Matches for %s',length(found),pttn));
    else
        set(F,'Name',sprintf('No Matches for %s',pttn));
    end
    setappdata(F,'findn',findn);
    
function StatusPopup(a,b, type)  

  DATA = GetDataFromFig(a);
  if ~strcmp(type,'popup')
      return;
  end
  cntrl_box = findobj('Tag',DATA.windownames{5},'type','figure');
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
  cntrl_box = figure('Position', DATA.winpos{5},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{5},'Name','Status Lines from binoc','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);

    lst = uicontrol(gcf, 'Style','list','String', 'Code List',...
        'HorizontalAlignment','left',...
        'Max',10,'Min',0,...
         'Tag','NextButton',...
'units','norm', 'Position',[0.01 0.01 0.99 0.99]);
set(lst,'string',DATA.Statuslines);
DATA.statusitem = lst;
set(DATA.toplevel,'UserData',DATA);

function DATA = RunExptSequence(DATA, str, line)

    nread = 0;
    DATA.matlabwasrun = 0;
    if ~iscellstr(str)
        str = cellstr(str);
    end
    runlines = find(strncmp('!expt',str,5));
    if isempty(runlines)
        warndlg('Sequence must contain !expt','Sequence file error');
        lastline = 1;
    else
        lastline = runlines(end);
    end
    firstline = line;
 
    if line > lastline
        if DATA.rptexpts > 0
            DATA.rptexpts = DATA.rptexpts-1;
            line = 1;
        else
            DATA.seqline = 0;
            return;
        end
    end
    if ischar(str)
        astr = str;
        clear str;
        for j = 1:size(astr,1)
            str{j} = deblank(astr(j,:));
        end
    end
for j = line:length(str)
    nread = 1+j-line;
    DATA = InterpretLine(DATA,str{j},'fromseq');
    uipause(DATA.pausetime,DATA.readpause,'Pause in sequence');
    DATA.readpause = 0;
    if strcmp(str{j},'!expt')
%need to do this before sending !expt to binoc, so that UserData is set
% before binoc calls back with settings
        if firstline > 1
            uipause(now, DATA.binoc{1}.seqpause,'Fixed Sequence Pause');
        end
%if mat was called in the sequence file, don't want it overridden by the matept file        
        if DATA.optionflags.exm && ~isempty(DATA.matexpt) && DATA.matlabwasrun == 0
            fprintf('Running %s\n',DATA.matexpt);
            DATA.matexpres = [];
            DATA.matexpres = eval(DATA.matexpt);
            DATA.matlabwasrun = 1;
            SendCode(DATA,'exp');
        end
        myprintf(DATA.cmdfid,'!expt line %d',j);
        DATA.nexpts = DATA.nexpts+1;
        DATA.Expts{DATA.nexpts} = ExptSummary(DATA);
        DATA.seqline = j;
        set(DATA.toplevel,'UserData',DATA);
        outprintf(DATA,'#From RunSequence\n');
        outprintf(DATA,'%s\n',str{j}); %this runs expt in binoc
        return;
    end
    if ~sum(strncmp(str{j},'expt',4)) %don't send these lines to binoc
        if DATA.outid > 0
            fprintf(DATA.outid,'%s #RunSeq\n',str{j});
        end
    end
    DATA = LogCommand(DATA, str{j});
end

function uipause(start, secs, msg)

    if secs <= 0
        return;
    end
    days = secs/(24 * 60 * 60);
    wh = waitbar(0,sprintf('%.1f sec %s at %s',secs,msg,datestr(start)));
    while (now - start) < days
        dt = (now - start)/days;
        wdur = (now-start) * (24 * 60 * 60);
        waitbar(dt,wh,sprintf('%.1f/%.1f sec %s at %s',wdur,secs,msg,datestr(start)));
    end
    delete(wh);


function DATA = ContinueSequence(DATA)
  cntrl_box = findobj('Tag',DATA.windownames{8},'type','figure');
  lst = findobj(cntrl_box,'Tag','SequenceList');
  DATA = RunExptSequence(DATA,get(lst,'string'),DATA.seqline+1);

function DATA = LogCommand(DATA, str, varargin)
    j = 1;
    reccmd = 1;
    d = [' #' datestr(now,'HH:MM')];
    while  j <= length(varargin)
        if strcmp(varargin{j},'norec')
            reccmd = 0;
        elseif strcmp(varargin{j},'notime')
            d = '';
        end
        j = j+1;
    end

    if reccmd
    DATA.commands = {DATA.commands{:} str};
    DATA.commandctr = length(DATA.commands)+1;
    end
    
    if DATA.cmdfid > 0
        fprintf(DATA.cmdfid,'%s%s\n',str,d);
    end
    if nargout == 0
        set(DATA.toplevel,'UserData',DATA);
    end

function SequencePopup(a,exptlines,type)

  DATA = GetDataFromFig(a);
  cntrl_box = findobj('Tag',DATA.windownames{8},'type','figure');
  if ~strcmp(type,'popup')
      if strcmp(type,'run')
          lst = findobj(cntrl_box,'Tag','SequenceList');
          RunExptSequence(DATA,get(lst,'string'),1);
      end
      return;
  end
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
  
  nr=10; nc=4;
  cntrl_box = figure('Position', DATA.winpos{8},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{8},'Name','Expt Sequence','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);

        bp(1) = 0.01;
bp(2) = 1-1./nr;
bp(3) = 1./nc;
bp(4) = 1./nr;
uicontrol(gcf,'style','pushbutton','string','Run', ...
    'Callback', {@SequencePopup, 'run'} ,...
    'units', 'norm', 'position',bp,'value',1);

lst = uicontrol(gcf, 'Style','edit','String', 'sequence',...
        'HorizontalAlignment','left',...
        'Max',10,'Min',0,...
         'Tag','SequenceList',...
'units','norm', 'Position',[0.01 0.01 0.99 0.99-1./nr]);
set(lst,'string',exptlines);
set(DATA.toplevel,'UserData',DATA);


function CodeListMenu(a,b,c)
    lst = get(get(a,'parent'),'userdata');
    strs = get(lst,'string')
    line = get(lst,'value');
    code = regexprep(strs(line,:),' .*','');
    DATA = GetDataFromFig(lst);
    if ~isfield(DATA,'helpdata')
        DATA.helpdata = loadhelp('/local/binochelp.txt');
    end
    id = find(strcmp(code,DATA.helpdata.codes));
    if ~isempty(id)
       helpdlg(DATA.helpdata.help{id},code); 
    else
       helpdlg(sprintf('No Help on %s :(',code),code); 
    end
    
function helpdata = loadhelp(name)
    
    fid = fopen(name,'r');
    if (fid > 0)
        a = textscan(fid,'%s','delimiter','\n');
    end
    txt = a{1};
    hlp = [];
    nh = 0;
    for j = 1:length(txt)
        if txt{j}(1) == ':'
            id = strfind(txt{j},':');
            if nh > 0
                helpdata.codes{nh} = code;
                helpdata.help{nh} = hlp;
            end
            nh = nh+1;
            code = txt{j}(id(1)+1:id(2)-1);
            hlp = txt{j}(id(2):end);
            
        else 
            hlp = [hlp txt{j}];
        end
        helpdata.codes{nh} = code;
        helpdata.help{nh} = hlp;
    end
        

function DATA = ReadLogFile(DATA, name)

    fid = fopen(name,'r');
    if fid < 0
        fprintf('Cannot Read %s\n',name);
        return;
    end
    s = textscan(fid,'%s','delimiter','\n');
    s = s{1};
    for j = length(s):-1:1
        if strncmp(s{j},'Saved',5)
            j = 0;
            break;
        elseif strncmp(s{j},'Gain',4)
            DATA.Coil.gain = sscanf(s{j}(6:end),'%f');
        elseif strncmp(s{j},'Offset',6)
            DATA.Coil.offset = sscanf(s{j}(8:end),'%f');
        elseif strncmp(s{j},'Phase',5)
            DATA.Coil.phase = sscanf(s{j}(7:end),'%f');
        elseif strncmp(s{j},'CriticalWeight',14)
            DATA.Coil.CriticalWeight = sscanf(s{j}(15:end),'%f');
        elseif strncmp(s{j},'so',2)
            DATA.Coil.so = sscanf(s{j}(4:end),'%f');
        elseif strncmp(s{j},'we',2)
            we = sscanf(s{j}(3:end),'%f');
            DATA.binoc{1}.we = we(1);
            if length(we) > 1
                DATA.Coil.CriticalWeight = we(2);
            end
        end
    end
    
function MonkeyLogPopup(a,b, type, channel)
  DATA = GetDataFromFig(a);
  

  if DATA.Coil.gain(1) == 0 %not read yet
      DATA = ReadLogFile(DATA, DATA.binoc{1}.lo);
  end
  
  if ~strcmp(type,'popup')
  value = str2num(get(a,'string'));

  id = strmatch(type,{'RH' 'LH' 'RV' 'LV' 'save' 'clear' 'popup'});
  if strncmp(type,'Offset',6)
      DATA.Coil.offset(channel) = value;
  elseif strncmp(type,'getsoft',5)
      DATA.Coil.so = DATA.binoc{1}.so;
     SetTextItem(gcf,'RH',DATA.binoc{1}.so(1));
     SetTextItem(gcf,'LH',DATA.binoc{1}.so(2));
     SetTextItem(gcf,'RV',DATA.binoc{1}.so(3));
     SetTextItem(gcf,'LV',DATA.binoc{1}.so(4));
  elseif strncmp(type,'applysoft',8)
      DATA.binoc{1}.so = DATA.Coil.so;
      SendCode(DATA,'so');
  elseif strncmp(type,'CriticalWeight',8)
      DATA.Coil.CriticalWeight = value;
  elseif strncmp(type,'phase',5)
      DATA.Coil.phase(channel) = value;
  elseif strncmp(type,'Gain',4)
      DATA.Coil.gain(channel) = value;
  elseif strncmp(type,'offset',6)
      DATA.Coil.offset(channel) = value;
  elseif strncmp(type,'soft',4)
      DATA.Coil.so(channel) = value;
  elseif strmatch(type,'savelog')
      fid = fopen(DATA.binoc{1}.lo,'a');
      if fid > 0
      fprintf(fid,'Saved: %s\n',datestr(now));
      fprintf(fid,'so%s\n',sprintf(' %.2f',DATA.Coil.so));
      fprintf(fid,'Gain%s\n',sprintf(' %.2f',DATA.Coil.gain));
      fprintf(fid,'Offset%s\n',sprintf(' %.2f',DATA.Coil.offset));
      fprintf(fid,'Phase%s\n',sprintf(' %.2f',DATA.Coil.phase));
      if strmatch(type,'savelog')
          fprintf(fid,'we%.2f %.2f\n',DATA.binoc{1}.we,DATA.Coil.CriticalWeight);
      end
      fclose(fid);
      fprintf('Saved to %s\n',DATA.binoc{1}.lo);
      end
  end
  set(DATA.toplevel,'UserData',DATA);
      return;
  end
  cntrl_box = findobj('Tag',DATA.windownames{6},'type','figure');
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
if length(DATA.winpos{6}) ~= 4
    DATA.winpos{6} = get(DATA.toplevel,'position');
end
cntrl_box = figure('Position', DATA.winpos{6},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{6},'Name','monkeylog','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);
            set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);
nr = 7;
nc=6;

bp = [0.01 0.99-1/nr .99/nc 1./nr];


    bp = [2/nc 0.99-1/nr 0.99./nc 1./nr];
uicontrol(gcf,'style','text','string','RH', ...
        'units', 'norm', 'position',bp,'value',1);
             bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','text','string','LH', ...
        'units', 'norm', 'position',bp,'value',1);


             bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','text','string','RV', ...
        'units', 'norm', 'position',bp,'value',1);

         bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','text','string','LV', ...
        'units', 'norm', 'position',bp,'value',1);

    bp(1) = bp(1)+bp(3)+0.01;
        bp = [0.01 0.99-2/nr 1.99/nc 1./nr];
     uicontrol(gcf,'style','text','string','SoftOff', ...
        'units', 'norm', 'position',bp,'value',1);   

bp = [2/nc 0.99-2/nr 0.99./nc 1./nr];
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.so(1)), ...
        'Callback', {@MonkeyLogPopup, 'soft', 1},'Tag','RH',...
        'units', 'norm', 'position',bp);


bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.so(2)), ...
        'Callback', {@MonkeyLogPopup, 'soft' 2},'Tag','LH',...
        'units', 'norm', 'position',bp);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.so(3)), ...
        'Callback', {@MonkeyLogPopup, 'soft', 3},'Tag','RV',...
        'units', 'norm', 'position',bp);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.so(4)), ...
        'Callback', {@MonkeyLogPopup, 'soft' 4},'Tag','LV',...
        'units', 'norm', 'position',bp);    

        bp = [0.01 0.99-3/nr 1.99/nc 1./nr];
     uicontrol(gcf,'style','text','string','Gain', ...
        'units', 'norm', 'position',bp,'value',1);   

bp = [2/nc 0.99-3/nr 0.99/nc 1./nr];
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.gain(1)), ...
        'Callback', {@MonkeyLogPopup, 'GainRH', 1},'Tag','GainRH',...
        'units', 'norm', 'position',bp);
   
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.gain(2)), ...
        'Callback', {@MonkeyLogPopup, 'GainLH', 2},'Tag','GainLH',...
        'units', 'norm', 'position',bp);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.gain(3)), ...
        'Callback', {@MonkeyLogPopup, 'GainRV', 3},'Tag','GainRV',...
        'units', 'norm', 'position',bp);
    
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.gain(4)), ...
        'Callback', {@MonkeyLogPopup, 'GainLV' 4},'Tag','GainLV',...
        'units', 'norm', 'position',bp);    

    bp = [0.01 0.99-4/nr 1.99/nc 1./nr];
     uicontrol(gcf,'style','text','string','Phase', ...
        'units', 'norm', 'position',bp,'value',1);   
bp = [2/nc 0.99-4/nr 0.99/nc 1./nr];
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.phase(1)), ...
        'Callback', {@MonkeyLogPopup, 'phaseRH', 1},'Tag','phaseRH',...
        'units', 'norm', 'position',bp);
   
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.phase(2)), ...
        'Callback', {@MonkeyLogPopup, 'phaseLH', 2},'Tag','phaseLH',...
        'units', 'norm', 'position',bp);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.phase(3)), ...
        'Callback', {@MonkeyLogPopup, 'phaseRV', 3},'Tag','phaseRV',...
        'units', 'norm', 'position',bp);
    
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.phase(4)), ...
        'Callback', {@MonkeyLogPopup, 'phaseLV', 4},'Tag','phaseLV',...
        'units', 'norm', 'position',bp);    
    
    
    bp = [0.01 0.99-5/nr 1.99/nc 1./nr];
     uicontrol(gcf,'style','text','string','Offset', ...
        'units', 'norm', 'position',bp,'value',1);   
    bp = [2/nc 0.99-5/nr 0.99/nc 1./nr];
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.offset(1)), ...
        'Callback', {@MonkeyLogPopup, 'offsetRH', 1},'Tag','offsetRH',...
        'units', 'norm', 'position',bp);
    
   
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.offset(2)), ...
        'Callback', {@MonkeyLogPopup, 'offsetLH', 2},'Tag','offsetLH',...
        'units', 'norm', 'position',bp);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.offset(3)), ...
        'Callback', {@MonkeyLogPopup, 'offsetRV', 3},'Tag','offsetRV',...
        'units', 'norm', 'position',bp);
    
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.offset(4)), ...
        'Callback', {@MonkeyLogPopup, 'offsetLV', 4},'Tag','offsetLV',...
        'units', 'norm', 'position',bp);    

bp(2) = bp(2)- 1./nr;
bp(1) = 0.01;
    it = uicontrol(gcf,'style','text','string','Weight', ...
    'units', 'norm', 'position',bp,'value',1);
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.we(1)), ...
        'Callback', {@MonkeyLogPopup, 'Weight'},'Tag','Weight',...
        'units', 'norm', 'position',bp);

bp(1) = bp(1)+bp(3)+0.01;
    it = uicontrol(gcf,'style','text','string','Critical Weight', ...
    'units', 'norm', 'position',bp,'value',1);bp(1) = bp(1)+bp(3)+0.01;

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.Coil.CriticalWeight), ...
        'Callback', {@MonkeyLogPopup, 'CriticalWeight'},'Tag','CriticalWeight',...
        'units', 'norm', 'position',bp);

    bp(1) = 0.01;
bp(2) = bp(2)- 1./nr;
uicontrol(gcf,'style','pushbutton','string','Save', ...
    'Callback', {@MonkeyLogPopup, 'savelog'} ,...
    'units', 'norm', 'position',bp,'value',1);
bp(1) = bp(1)+bp(3)+0.01;
bp(3) = 2./nc;
    uicontrol(gcf,'style','pushbutton','string','Apply Softoff', ...
        'Callback', {@MonkeyLogPopup, 'applysoft'} ,...
        'units', 'norm', 'position',bp,'value',1);
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pushbutton','string','Use Current Softoff', ...
        'Callback', {@MonkeyLogPopup, 'getsoft'} ,...
        'units', 'norm', 'position',bp,'value',1);
    
set(gcf,'CloseRequestFcn',{@CloseWindow, 6});

function SetSoftOffWindow(DATA, a)
    if ~isfigure(a)
        return;
    end
     SetTextItem(a,'RH',DATA.binoc{1}.so(1));
     SetTextItem(a,'LH',DATA.binoc{1}.so(2));
     SetTextItem(a,'RV',DATA.binoc{1}.so(3));
     SetTextItem(a,'LV',DATA.binoc{1}.so(4));

function SoftoffPopup(a,b, type)
  DATA = GetDataFromFig(a);
  
  
  id = strmatch(type,{'RH' 'LH' 'RV' 'LV' 'null' 'clear' 'popup' 'set'});
  if isempty(id)'
      return;
  elseif id < 5
      DATA.binoc{1}.so(id) = str2num(get(a,'string'));
      SendCode(DATA, 'so');
      set(DATA.toplevel,'UserData',DATA);
  elseif id == 5 || id ==8
      if id == 5
     fprintf(DATA.outid,'sonull\n');
     DATA = ReadFromBinoc(DATA);
      end
      SetSoftOffWindow(DATA, gcf);
  elseif id == 6
     fprintf(DATA.outid,'so=0 0 0 0\n');
     SetTextItem(gcf,'RH',0);
     SetTextItem(gcf,'LH',0);
     SetTextItem(gcf,'RV',0);
     SetTextItem(gcf,'LV',0);
  end
  
  if ~strcmp(type,'popup')
      return;
  end
  cntrl_box = findobj('Tag',DATA.windownames{3},'type','figure');
  if ~isempty(cntrl_box)
      figure(cntrl_box);
      return;
  end
if length(DATA.winpos{3}) ~= 4
    DATA.winpos{3} = get(DATA.toplevel,'position');
end
cntrl_box = figure('Position', DATA.winpos{3},...
        'NumberTitle', 'off', 'Tag',DATA.windownames{3},'Name','Softoff','menubar','none');
    set(cntrl_box,'UserData',DATA.toplevel);
        set(cntrl_box,'DefaultUIControlFontSize',DATA.font.FontSize);
        set(cntrl_box,'DefaultUIControlFontName',DATA.font.FontName);

nr = 2;
nc=6
bp = [0.01 0.99-1/nr 0.115 1./nr];
    uicontrol(gcf,'style','text','string','RH', ...
        'units', 'norm', 'position',bp,'value',1);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.so(1)), ...
        'Callback', {@SoftoffPopup, 'RH'},'Tag','RH',...
        'units', 'norm', 'position',bp);
   
         bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','text','string','LH', ...
        'units', 'norm', 'position',bp,'value',1);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.so(2)), ...
        'Callback', {@SoftoffPopup, 'LH'},'Tag','LH',...
        'units', 'norm', 'position',bp);
    
         bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','text','string','RV', ...
        'units', 'norm', 'position',bp,'value',1);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.so(3)), ...
        'Callback', {@SoftoffPopup, 'RV'},'Tag','RV',...
        'units', 'norm', 'position',bp);
    
         bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','text','string','LV', ...
        'units', 'norm', 'position',bp,'value',1);

bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.binoc{1}.so(4)), ...
        'Callback', {@SoftoffPopup, 'LV'},'Tag','LV',...
        'units', 'norm', 'position',bp);    

bp(1) = 0.01;
bp(2) = bp(2)- 1./nr;

    uicontrol(gcf,'style','pushbutton','string','Null', ...
        'Callback', {@SoftoffPopup, 'null'} ,...
        'units', 'norm', 'position',bp,'value',1);
    
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pushbutton','string','Clear', ...
        'Callback', {@SoftoffPopup, 'clear'} ,...
        'units', 'norm', 'position',bp,'value',1);

bp(3) = 2./nc;
bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pushbutton','string','Save to log', ...
        'Callback', {@MonkeyLogPopup, 'save'} ,...
        'units', 'norm', 'position',bp,'value',1);
    
set(gcf,'CloseRequestFcn',{@CloseWindow, 3});


function CloseWindow(a,b,wid)
  DATA = GetDataFromFig(a);
  x = get(a, 'position');
  DATA.winpos{wid} = x;
  if isfigure(DATA.toplevel)
  set(DATA.toplevel,'UserData',DATA);
  end
  delete(a);
        
    
function StepperPopup(a,b)
  DATA = GetDataFromFig(a);
  cntrl_box = findobj('Tag',DATA.tag.stepper,'type','figure');
if ~isempty(cntrl_box)
    figure(cntrl_box);
    return;
end
scrsz = get(0,'Screensize');
cntrl_box = figure('Position', [10 scrsz(4)-480 300 450],...
        'NumberTitle', 'off', 'Tag',DATA.tag.stepper,'Name','Stepper','menubar','none');
    nr = 6;
    bp = [0.01 0.99-1/nr 0.1 1./nr];
    uicontrol(gcf,'style','pushbutton','string','+', ...
        'Callback', {@Stepper, 1, 1},...
        'units', 'norm', 'position',bp,'value',1);
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pushbutton','string','-', ...
        'Callback', {@Stepper, -1, 1},...
        'units', 'norm', 'position',bp,'value',1);
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = 0.3;
    uicontrol(gcf,'style','pop','string','10|20|50|100|200', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','StepSize1');
    bp(1) = 0.01;
    bp(2) = bp(2) - bp(4)-0.01;
    uicontrol(gcf,'style','pushbutton','string','+', ...
        'Callback', {@Stepper, 1, 2},...
        'units', 'norm', 'position',bp,'value',1);
    bp(1) = bp(1)+bp(3)+0.01;
    uicontrol(gcf,'style','pushbutton','string','-', ...
        'Callback', {@Stepper, -1, 2},...
        'units', 'norm', 'position',bp,'value',1);
    bp(1) = bp(1)+bp(3)+0.01;
    bp(3) = 0.3;
    uicontrol(gcf,'style','edit','string','10', ...
        'units', 'norm', 'position',bp,'value',1,'Tag','StepSize2');
    bp(1) = 0.01;
    bp(2) = bp(2) - bp(4)-0.01;
    uicontrol(gcf,'style','edit','string',num2str(DATA.stepperpos), ...
        'units', 'norm', 'position',bp,'value',1,'Tag','StepperPosition');
    set(cntrl_box,'UserData',DATA.toplevel);
    
function Stepper(a,b, step, type)
    DATA = GetDataFromFig(a);
    sfig = get(a,'parent');
    it = findobj(sfig,'Tag','StepSize1');
    DATA.stepsize(1) = Menu2Val(it);
    it = findobj(sfig,'Tag','StepSize2');
    DATA.stepsize(2) = Text2Val(it);
    if step > 0
        s = sprintf('ed+%.3f\n',DATA.stepsize(type));
    else
        s = sprintf('ed-%.3f\n',DATA.stepsize(type));
    end
    fprintf(DATA.outid,'%s\n',s);
    if DATA.penid > 0
        fprintf(DATA.penid,'%s\n',s);
    end
        
    ReadFromBinoc(DATA);
    
function val = Menu2Val(it)
val = NaN;
if isempty(it)
    return;
end
j = get(it(1),'value');
s = get(it(1),'string');
val = str2num(s(j,:));

function val = Menu2Str(it)
val = '';
if isempty(it)
    return;
end
j = get(it(1),'value');
s = get(it(1),'string');
if iscellstr(s)
    val = s{j};
else
val = s(j,:);
end

function OpenPenLog(a,b, varargin)
    DATA = GetDataFromFig(a);
    F = get(a,'parent');
    btn = get(a,'tag');
    if strcmp(btn,'Penset')
        DATA.binoc{1}.Xp = Text2Val(findobj(F,'Tag','Xp'));
        DATA.binoc{1}.Yp = Text2Val(findobj(F,'Tag','Yp'));
        DATA.binoc{1}.Pn = Text2Val(findobj(F,'Tag','Pn'));
        DATA.binoc{1}.ePr = Text2Val(findobj(F,'Tag','protrudes'));
        DATA.binoc{1}.eZ = Text2Val(findobj(F,'Tag','Impedance'));
        DATA.binoc{1}.adapter = get(findobj(F,'Tag','adapter'),'string');
        DATA.binoc{1}.hemi = Menu2Str(findobj(F,'Tag','hemisphere'));
        DATA.binoc{1}.ui = Menu2Str(findobj(F,'Tag','Experimenter'));
        DATA.binoc{1}.coarsemm = Menu2Str(findobj(F,'Tag','coarsemm'));
        SendCode(DATA,{'Pn' 'Xp' 'Yp' 'ui' 'Electrode' 'adapter' 'eZ' 'ePr' 'hemi' 'coarsemm'});
        if DATA.outid
            fprintf(DATA.outid,'!openpen');
        end
    elseif strcmp(btn,'PlotPen')
        name = sprintf('/local/%s/pen%d.log',DATA.binoc{1}.monkey,DATA.binoc{1}.Pn);
        GetFigure('Pen');
        hold off;
        PlotOnePen(name,'allcomments');
    end
    %writing to pen log fone in binoc
    if 0 
    if DATA.penid > 0
        fclose(DATA.penid);
    end
    name = sprintf('/local/%s/pen%d.log',DATA.binoc{1}.monkey,DATA.binoc{1}.pe);
    DATA.penid = fopen(name,'a');
    fprintf(DATA.penid,'Penetration %d at %.1f,%.1f Opened %s\n',DATA.binoc{1}.pe,DATA.binoc{1}.px,DATA.binoc{1}.py,datestr(now));
    fprintf(DATA.penid,'Electrode %s\n',DATA.binoc{1}.Electrode);
    end
    set(DATA.toplevel,'UserData',DATA);
    
    
    
function val = Text2Val(it)
val = NaN;
if isempty(it)
    return;
end
s = get(it,'string');
val = str2num(s);

        
function GoToggle(a,b)       
    DATA = GetDataFromFig(a);
    go = get(a,'value');
    if go
      fprintf(DATA.outid,'\\go\n');
    else
      fprintf(DATA.outid,'\\stop\n');
    end
    DATA.optionflags.do  = go;
    set(DATA.toplevel,'UserData',DATA);
    
function HitToggle(a,b, flag)       
    DATA = GetDataFromFig(a);
%    flag = get(a,'Tag');
    DATA.optionflags.(flag) = get(a,'value');
    s = 'op=';
    f = fields(DATA.optionflags);
    for j = 1:length(f)
        if DATA.optionflags.(f{j})
            s = [s '+' f{j}];
        else
%            s = [s '-' f{j}];
        end
    end
    fprintf('op=0\n%s\n',s);
    fprintf(DATA.outid,'op=0\n%s\n',s);
    ReadFromBinoc(DATA);
    CheckTimer(DATA);
    SetGui(DATA,'set');
 
   
    
function SendCode(DATA, code)
    
    if iscellstr(code)
        for j = 1:length(code)
            SendCode(DATA,code{j});
        end
            return;
    end
    if strncmp(code,'Electrode',8)
        if length(DATA.binoc{1}.Electrode)
            fprintf(DATA.outid,'Electrode=%s\n',DATA.binoc{1}.Electrode);
        elseif DATA.electrodeid > 0
            fprintf(DATA.outid,'Electrode=%s\n',DATA.electrodestrings{DATA.electrodeid});
        end
    elseif strcmp(code,'exp')
        if isfield(DATA.matexpres,'stimdir')
            fprintf(DATA.outid,'exp=%s\n',DATA.matexpres.stimdir);
        end
    else
        s = CodeText(DATA, code);
        if length(s)
            fprintf(DATA.outid,'%s\n',s);
        end
    end
    
function val = GetValue(DATA,code)    
%Gets value of a code

if isfield(DATA.binoc{1},code)
    val = DATA.binoc{1}.(code);
else
    val = NaN;
end
    
function [s, lbl, type] = CodeText(DATA,code, varargin)
s = [];
lbl = [];
type = 0;

cstim = DATA.currentstim;
j = 1;
while j <= length(varargin)
    if strncmpi(varargin{j},'back',4)
        cstim = 2;
    elseif strncmpi(varargin{j},'ChoiceU',7)
        cstim = 3;
    elseif strncmpi(varargin{j},'ChoiceD',7)
        cstim = 4;
    end
    j = j+1;
end

if strcmp(code,'optionflag')
        s = 'op=';
        f = fields(DATA.optionflags);
        for j = 1:length(f)
            if DATA.optionflags.(f{j})
                s = [s '+' f{j}];
            else
    %            s = [s '-' f{j}];
            end
        end
        s = sprintf('op=0\n%s\n',s);
        s= [s sprintf('%s',StimToggleString(DATA,DATA.currentstim))];
    elseif strcmp(code,'nr')
        s = sprintf('%s=%d',code,DATA.binoc{1}.nr);
    elseif strmatch(code,{'nt' 'n2' 'n3'})
        id = strmatch(code,{'nt' 'n2' 'n3'});
        s = sprintf('%s=%d',code,DATA.nstim(id));
    elseif strmatch(code,{'et' 'e2' 'e3'})
        id = strmatch(code,{'et' 'e2' 'e3'});
        s = sprintf('%s=%s',code,DATA.exptype{id});
    elseif strcmp(code,'expts')
        s = sprintf('et=%s\nei=%sf\nem=%.6f\nnt=%d\n',DATA.exptype{1},DATA.binoc{1}.ei,DATA.mean(1),DATA.nstim(1));
        s = [s sprintf('e2=%s\ni2=%s\nm2=%6f\nn2=%d\n',DATA.exptype{2},DATA.binoc{1}.i2,DATA.mean(2),DATA.nstim(2))];
        s = [s sprintf('e3=%s\ni3=%s\nm3=%.6f\nn3=%d\n',DATA.exptype{3},DATA.binoc{1}.i3,DATA.mean(3),DATA.nstim(3))];
        s = AddCustomStim(DATA,s,1);
    elseif strcmp(code,'st')
        s = sprintf('st=%s',DATA.stimulusnames{DATA.stimtype(cstim)});
    elseif strcmp(code,'vve')
        s = sprintf('vve=%s',DATA.vergversion);
    elseif strcmp(code,'pf')
        s = 'pf=';
        f = fields(DATA.showflags);
        s = sprintf('pf=%s',sprintf('+%s',f{:}));
    elseif isfield(DATA.binoc{cstim},code)
        id = strmatch(code,{DATA.comcodes.code},'exact');
        if length(id) ==1 && DATA.comcodes(id).type == 'C'
            s = sprintf('%s=%s',code,DATA.binoc{cstim}.(code));
        else
            s = sprintf('%s=%s',code,num2str(DATA.binoc{cstim}.(code)'));
        end  
        if length(id) ==1
            lbl = DATA.comcodes(id).label;
            type = DATA.comcodes(id).group;
        end
    elseif sum(strcmp(code,{DATA.strcodes.code})) == 1
        id = find(strcmp(code,{DATA.strcodes.code}));
        s = sprintf('%s=%s',code,DATA.binocstr.(code));
        lbl = DATA.strcodes(id).label;
    end
        
function StimToggle(a,b, flag)       
    DATA = GetDataFromFig(a);
%    flag = get(a,'Tag');
    DATA.stimflags{1}.(flag) = get(a,'value');
    fprintf(DATA.outid,'%s\n',StimToggleString(DATA,DATA.currentstim));
    ReadFromBinoc(DATA);

function s = StimToggleString(DATA, current)
    s = 'fl=';
    if current > length(DATA.stimflags)
        return;
    end
    f = fields(DATA.stimflags{current});
%always send + and -, so that don't have to track clearing
    for j = 1:length(f)
        if DATA.stimflags{current}.(f{j})
            s = [s '+' f{j}];
        else
            s = [s '-' f{j}];
        end
    end
        
function OtherToggles(a,b,flag)

    DATA = GetDataFromFig(a);
    v= get(a,'value');
    if v
        c = '+';
    else
      c = '-';
    end
    if strcmp(flag,'XYR')
        DATA.showxy(1) = v;
        fprintf(DATA.outid,'ch10%c\n',c);
    elseif strcmp(flag,'XYL')
        DATA.showxy(2) = v;
        fprintf(DATA.outid,'ch11%c\n',c);
    elseif strcmp(flag,'XYB')
        DATA.showxy(3) = v;
        fprintf(DATA.outid,'ch12%c\n',c);
    end        
    set(DATA.toplevel,'UserData',DATA);
    
    
function [DATA, txt] = PrevCommand(DATA, src, step)
    txt = '';
    
    if DATA.newchar ==1  %if typed something, use this to complete commands with
        DATA.completestr = src.Text;
    end
    
    if DATA.commandctr >= length(DATA.commands) && step == 1 && DATA.historyctr > length(DATA.oldcmds)
        DATA.commandctr = length(DATA.commands)+1;
        txt = '';
    elseif (DATA.commandctr > 1 && step == -1) || (DATA.commandctr < length(DATA.commands) && step == 1 && DATA.historyctr == length(DATA.oldcmds)+1)
        if isempty(DATA.completestr)
            DATA.commandctr = DATA.commandctr+step;
        else
            %                fprintf('History with %s\n',DATA.completestr);
            id = find(strncmp(DATA.completestr,DATA.commands,length(DATA.completestr)));
            if step < 0
                id = id(id < DATA.commandctr);
                if ~isempty(id)
                    DATA.commandctr = id(end);
                else 
                    DATA.commandctr = 0;
                end
            else
                id = id(id > DATA.commandctr);
                if ~isempty(id)
                    DATA.commandctr = id(1);
                end
            end
        end
%        fprintf('Step Command %d\n',step);
        DATA.historyctr = length(DATA.oldcmds)+1;
        if DATA.commandctr == 0
            txt = DATA.oldcmds{end};
            DATA.commandctr = 1;
            DATA.historyctr = length(DATA.oldcmds);
        else
            txt = DATA.commands{DATA.commandctr};
            set(DATA.txtrec,'value',DATA.commandctr+1);
        end
    elseif DATA.commandctr == 1 && (step < 0 || DATA.historyctr <= length(DATA.oldcmds))
        if DATA.historyctr == length(DATA.oldcmds) && step == 1
            DATA.historyctr = length(DATA.oldcmds)+1;
            txt = DATA.commands{1};
        elseif DATA.historyctr > 1
            if isempty(DATA.completestr) || DATA.historyctr == length(DATA.oldcmds)+1
                DATA.historyctr = DATA.historyctr+step;
            else
                id = find(strncmp(DATA.completestr,DATA.oldcmds,length(DATA.completestr)));
                if step < 0
                    id = id(id < DATA.historyctr);
                    if ~isempty(id)
                        DATA.historyctr = id(end);
                    end
                else
                    id = id(id > DATA.historyctr);
                    if ~isempty(id)
                        DATA.historyctr = id(1);
                    else
                        DATA.historyctr = 0;
                    end
                end
            end
            set(DATA.txtrec,'value',1);
            if DATA.historyctr == 0
                txt = 'Todays Commands';
                DATA.historyctr = length(DATA.oldcmds)+1;
                DATA.commandctr = 0;
            else
                txt = DATA.oldcmds{DATA.historyctr};
            end
        end
    else
        txt = src.Text;
    end
 %   txt = StripComments(txt);
    
function jTextKey(src, ev)    
    DATA = GetDataFromFig(src);
    ks =get(ev);
    newchar = 0;
    if ks.KeyCode == 38  %up arrow
        if ~isempty(DATA.completions)
            x = get(DATA.txtrec,'value');
            if x > 2
                set(DATA.txtrec,'value',x-1);
                src.Text = [DATA.completions{x-2} '='];
            end
        else
            [DATA, src.Text] = PrevCommand(DATA, src, -1);
        end
        src.setForeground(java.awt.Color(0.6,0,0))
        src.CaretPosition = length(src.Text);
    elseif ks.KeyCode == 10  %return
        if ~isempty(DATA.completions)
            DATA = ResetTextLst(DATA);
            src.setForeground(java.awt.Color(0,0,0));
            if isempty(strfind(src.Text,'='))  %User did not add to completion
                set(DATA.toplevel,'UserData',DATA);
            return;
            end
        else
        DATA = TextEntered(src, ev);
        end
    elseif ks.KeyCode == 39  %right arrow
    elseif ks.KeyCode == 40  %down arrow
        if ~isempty(DATA.completions)
            x = get(DATA.txtrec,'value');
            if x <= length(DATA.completions)
                set(DATA.txtrec,'value',x+1);
                src.Text = [DATA.completions{x} '='];
                src.CaretPosition = length(src.Text);
            end
        else
            [DATA, src.Text] = PrevCommand(DATA, src, 1);
        end
        src.setForeground(java.awt.Color(0.6,0,0))
        src.CaretPosition = length(src.Text);
    elseif ismember(ks.KeyCode,[8 127]) && strcmp(ks.ShiftDown,'on');  %shift delete
        src.Text = '';
    elseif ismember(ks.KeyCode,[8 127]) && strcmp(ks.ControlDown,'on');  %control-delete
        src.Text = regexprep(src.Text,'=.*','=');
        src.CaretPosition = length(src.Text);                        
    elseif isempty(ks.KeyChar)
    elseif ks.KeyChar == 9 %Tab
        a = deblank(src.Text);
        if isempty(strfind(a,'='))  %complete codes
            DATA = ShowCompletions(DATA,a);
        end
    elseif 0 && ks.KeyChar == ' ' %%now tab works, treat space normally
        a = deblank(src.Text);
        if isempty(strfind(a,'='))  %complete codes
            DATA = ShowCompletions(DATA,a);
        end
    else
        newchar = 1;
        if DATA.newchar == 0 %was loooking at history/completions
            txt = StripComments(src.Text);
            if ~strcmp(txt, src.Text)
                src.Text = txt;
                src.CaretPosition = length(src.Text);
                newchar = 0; 
            end
            src.setForeground(java.awt.Color(0,0,0));
        end
        DATA.completestr = '';
    end
    DATA.newchar = newchar; %something typed
    set(DATA.toplevel,'UserData',DATA);
        
function TextKey(src,ev)
    DATA = GetDataFromFig(src);
    ks.Key = get(ev,'KeyChar');
    if strcmp(ks.Key,'downarrow')
        if ~isempty(DATA.completions)
            x = get(DATA.txtrec,'value');
            if x <= length(DATA.completions)
                set(DATA.txtrec,'value',x+1);
                set(src,'string',[DATA.completions{x} '=']);
            end
        elseif DATA.commandctr < length(DATA.commands)
            DATA.commandctr = DATA.commandctr+1;
            set(src,'string',DATA.commands{DATA.commandctr})
            set(DATA.toplevel,'UserData',DATA);
        end
    elseif strcmp(ks.Key,'downarrow')
    elseif strcmp(ks.Key,'uparrow')
        if ~isempty(DATA.completions)
            x = get(DATA.txtrec,'value');
            if x > 3
                set(DATA.txtrec,'value',x-1);
                set(src,'string',[DATA.completions{x-2} '=']);
            end
        elseif DATA.commandctr > 1
            DATA.commandctr = DATA.commandctr-1;
            set(src,'string',DATA.commands{DATA.commandctr})
            set(DATA.toplevel,'UserData',DATA);
        end
    elseif strcmp(ks.Key,'space')
        a = deblank(get(src,'string'))
        if isempty(strfind(a,'='))  %complete codes
            DATA = ShowCompletions(DATA,a);
        end
    elseif strcmp(ks.Key,'tab')
        fprintf('Hit Tab');
    elseif strcmp(ks.Key,'control')
        setappdata(DATA.toplevel,'cntrl_is_down',1);
    else
        str = get(src,'string')
%        if str(end) ~= ' ' && ~isempty(DATA.completions)
%            ResetTextLst(DATA);
%        end
    end
    if strcmp(ks.Modifier,'control')
        setappdata(DATA.toplevel,'cntrl_is_down',1);
    else
        setappdata(DATA.toplevel,'cntrl_is_down',0);
    end
    
function DATA = ShowCompletions(DATA, a)
    DATA.completestr = a;
    xid = find(~strcmp('xx',{DATA.comcodes.code}));
        id = xid(find(strncmp(a,{DATA.comcodes(xid).code},length(a))));
        fprintf('Completing %s\n',a);
        str{1} = sprintf('%d Possible Completions for %s  (Return or Click here to cancel)',length(id),a);
        for j = 1:length(id)
            str{j+1} = [DATA.comcodes(id(j)).code '   (' DATA.comcodes(id(j)).label ')' ];
        end
% if completions not empty, there is already a set of completions up
% so don't change the recorded text
        if isempty(DATA.completions) %
            DATA.oldtxt = get(DATA.txtrec,'string');
        end
        DATA.completions = {DATA.comcodes(id).code};
        set(DATA.txtrec,'string',str,'foregroundcolor',[1 0 0]);
        if ~isempty(id)
            set(DATA.txtrec,'value',2);
        end
        set(DATA.toplevel,'UserData',DATA);

function DATA = ResetTextLst(DATA)       
    DATA.completions = {};
    set(DATA.txtrec,'string',DATA.oldtxt,'foregroundcolor',[0 0 0],'value',1);
    if nargout == 0
        set(DATA.toplevel,'UserData',DATA);
    end
    
function TextList(a,b)
    DATA = GetDataFromFig(a);
    line = get(a,'value');
    s = get(a,'string');
    if length(DATA.completions) >= line-1 && line > 1
        SetTextUI(DATA,[DATA.completions{line-1} '=']);
    elseif line ==1 && isfield(DATA,'oldtxt')
        ResetTextLst(DATA);
    else
        str = StripComments(s(line,:));
        SetTextUI(DATA, str);
    end

    
function s = StripComments(str)
    id = strfind(str,'(');
    if ~isempty(id)
        str = deblank(str(1:id(1)-1));
    end
    id = strfind(str,'?');
    if ~isempty(id)
        str = deblank(str(2:id(2)-1));
    end
    s = regexprep(str,'\s\#.*','');

    
function SetTextUI(DATA, str)
if sum(strncmp(class(DATA.txtui),{'javahandle' 'jcontrol'},8))
    set(DATA.txtui,'Text', str);
else
    set(DATA.txtui,'string',str);        
end

    function yn = isjava(a)
        yn = 0;
        if isfield(a,'uipanel')
            yn = 1;
        end
        

function DATA = TextEntered(a,b)
    
    
    DATA = GetDataFromFig(a);
    if strncmp(class(a),'javahandle',8)
        txt = a.Text;
    else
        txt = get(a,'string');
        if get(gcf, 'currentcharacter') ~= 13 %return
            return;
        end
    end
    cntrl_is_down = getappdata(DATA.toplevel,'cntrl_is_down');
    if cntrl_is_down
        DATA = ShowCompletions(DATA,txt);
        return;
    elseif ~isempty(DATA.completions)
        DATA = ResetTextLst(DATA);
        if isempty(strfind(txt,'='))  %User did not add to completion
            set(DATA.toplevel,'UserData',DATA);
            return;
        end            
%        return;
    end
if isempty(txt)
return;
end

id = strfind(txt,'=');
if isstrprop(txt(1),'digit') || txt(1) == '-'
    txt = [DATA.lastcmd txt];
elseif length(id)
    DATA.lastcmd = txt(1:id(1));
end
if DATA.outid > 0
    if DATA.currentstim > 1
        fprintf(DATA.outid,'mo=%s\n',DATA.stimlabels{DATA.currentstim});
    end
    fprintf(DATA.outid,'%s\n',txt);
end
DATA = LogCommand(DATA, txt);

str = [];
xstr = {};
if id
    code = txt(1:id(1)-1);
    id = strmatch(code,{DATA.comcodes.code},'exact');
    if length(id)
        str = DATA.comcodes(id(1)).label;
    else
    id =  strmatch(code,{DATA.strcodes.code},'exact');
    if length(id)
        str = DATA.strcodes(id(1)).label;
    end
    end
else
    [code,id] = FindCode(DATA,txt);
    if id
    str = DATA.comcodes(id).label;
    end
end

SetTextUI(DATA,'');
if txt(end) ~= '='
    DATA = InterpretLine(DATA,txt);
end
DATA = ReadFromBinoc(DATA,'from TextEntered ');
if txt(end) == '='
    code = txt(1:end-1);
    if sum(strcmp(code,{'uf' 'monkey'}))
       DATA = AddTextToGui(DATA,['cwd=' DATA.cwd]);
    end
    if sum(strcmp(code,{'rw'})) %show total reward
        if isfield(DATA.Trials,'good') && isfield(DATA.Trials,'rw')
            rwsum = sum([DATA.Trials([DATA.Trials.good] ==1).rw]);
            DATA = AddTextToGui(DATA,['totalreward=' sprintf('%.1f',rwsum)]);
        end
    end
    if strcmp(code,'op')
       txt = ['?' CodeText(DATA, 'optionflag')]; 
       str = 'Optionflag';
    elseif isfield(DATA.binoc{DATA.currentstim},code)
       id = strmatch(code,{DATA.comcodes.code},'exact');
       if length(id) == 1 && DATA.comcodes(id).type == 'C'
           txt = ['?' txt '?' DATA.binoc{DATA.currentstim}.(code)];
       elseif isempty(id)
           txt = ['?' txt '?' num2str(DATA.binoc{DATA.currentstim}.(code)') '(Unrecognized code)'];
       elseif ischar(DATA.binoc{DATA.currentstim}.(code)) %sometimes nmes->char  (!! ei=180lin)
           txt = ['?' txt '?''' DATA.binoc{DATA.currentstim}.(code) ''''];
       else
           txt = ['?' txt '?' num2str(DATA.binoc{DATA.currentstim}.(code)')];
       end
       if length(id)
        str = DATA.comcodes(id(1)).label;
       end
    elseif strmatch(code,{'nr' 'nt' 'n2' 'n3' 'et' 'e2' 'e3' })
       txt = ['?' CodeText(DATA, code)];       
       str = 'Nstim';
    elseif isfield(DATA.binocstr,code)
        txt = ['?' txt '?''' DATA.binocstr.(code) ''''];
       id =  strmatch(code,{DATA.strcodes.code},'exact');
       if length(id)
           str = DATA.strcodes(id(1)).label;
       end
    else
        id = find(strncmp(code,{DATA.comcodes.code},length(code))); %find possible matches
        if ~isempty(id)
            str = 'Poossible Completions';
        end
        for j = 1:length(id)
            xstr{j} = sprintf('%s %s\n',DATA.comcodes(id(j)).code,DATA.comcodes(id(j)).label);
        end                
    end
end
a =  get(DATA.txtrec,'string');
n = size(a,1);
if strcmp(code,'px')
    pixdeg = atan(DATA.binoc{1}.px/DATA.binoc{1}.vd) * 180/pi;
    txt = [txt sprintf(' (%.3f deg)',pixdeg)];
end
if length(str)
    txt = [txt '(' str ')  ' datestr(now,'HH:MM')];
end
if iscellstr(a)
    a{n+1} = txt;
else
a(n+1,1:length(txt)) = txt;
end
for j = 1:length(xstr)
    a(n+1+j,1:length(xstr{j})) = xstr{j};
end
set(DATA.txtrec,'string',a);
set(DATA.txtrec,'listboxtop',n+1);
DATA = LogCommand(DATA, txt, 'norec');
set(DATA.toplevel,'UserData',DATA);
SetGui(DATA);


function DATA = AddTextToGui(DATA, txt, varargin)
    if ~isfield(DATA,'txtrec') || ~ishandle(DATA.txtrec)
        return;
    end
a =  get(DATA.txtrec,'string');
n = size(a,1);
DATA = LogCommand(DATA, txt, varargin{:});
txt  = [txt ' ' datestr(now,'HH:MM')];
a(n+1,1:length(txt)) = txt;
set(DATA.txtrec,'string',a);
set(DATA.txtrec,'listboxtop',n+1);

        

function ClearTaggedChecks(it, tags)

    
    c = get(it,'children');
    menutags = get(c,'tag');
    if isempty(tags)
        for j = 1:length(menutags)
            if ~isempty(menutags{j})
                set(c(j),'Checked','off');
            end
        end
    else
        for j = 1:length(tags)
            k = strmatch(tags{j},menutags,'exact');
            set(c(k),'Checked','off');
        end
    end
    
function ChoosePsych(a,b, mode)
    DATA = GetDataFromFig(a);
    onoff = {'off' 'on'};
    
    if strncmp(mode,'Expt',4)
        e = sscanf(mode,'Expt%d');
        if length(DATA.plotexpts) < e
            DATA.plotexpts(e) = 1;
        else
            DATA.plotexpts(e) = ~DATA.plotexpts(e);
        end
        DATA.psych.blockmode = 'Select';
        PlotPsych(DATA);
        if strmatch(DATA.psych.blockmode,'OneOnly')
            c = get(get(a,'parent'),'children');
            set(c,'checked','off');
        else
            ClearTaggedChecks(get(a,'parent'),{});
        end
        set(a,'checked',onoff{DATA.plotexpts(e)+1});
        if strmatch(DATA.psych.blockmode,{'Current' 'OneOnly'})
            it = findobj(get(a,'parent'),'Tag',DATA.psych.blockmode);
            set(it,'Checked','on');
        end
    elseif strmatch(mode,'Current')
        if strcmp(DATA.psych.blockmode,'Current')
            DATA.psych.blockmode = 'Select';
            set(a,'checked','off');
        else
            DATA.psych.blockmode = mode;
            set(a,'checked','on');
        end
        ClearTaggedChecks(get(a,'parent'),{});
        PlotPsych(DATA);
    elseif strmatch(mode,{'OnlyCurrent','All' 'None' 'OneOnly'})
        DATA.psych.blockmode = mode;
        DATA.plotexpts = zeros(size(DATA.plotexpts));
        PlotPsych(DATA);
        c = get(get(a,'parent'),'children');
        set(c,'checked','off');
        set(a,'checked','on');
    elseif strmatch(mode,'Pause')
        DATA.psych.show = ~DATA.psych.show;
        set(a,'Checked',onoff{DATA.psych.show+1});
        PlotPsych(DATA);
    elseif sum(strcmp(mode,{'crosshairs' 'trialresult'}))
        DATA.psych.(mode) = ~DATA.psych.(mode);
        set(a,'Checked',onoff{DATA.psych.(mode)+1});
        PlotPsych(DATA);
    end
    set(DATA.toplevel,'UserData',DATA);



function DATA = SetFigure(tag, DATA)

    [a,isnew] = GetFigure(tag);
    onoff = {'off' 'on'};
    if isnew
        DATA.figs.(tag) = a;
        if strcmp(tag,'VergPsych')
            hm = uimenu(a, 'Label','Expts','Tag','ExptMenu');
            PsychMenu(DATA);
            hm = uimenu(a, 'Label','Options','Tag','PsychOptions');
            sm = uimenu(hm,'Label','Crosshairs','callback', {@ChoosePsych, 'crosshairs'},...
                'checked',onoff{DATA.psych.crosshairs+1});
            sm = uimenu(hm,'Label','Just Show Trial outcomes','callback', {@ChoosePsych, 'trialresult'},...
                'checked',onoff{DATA.psych.trialresult+1});
            set(a,'UserData',DATA.toplevel);
            set(a,'DefaultUIControlFontSize',DATA.font.FontSize);
            set(a,'DefaultUIControlFontName',DATA.font.FontName);

        end
        set(DATA.toplevel,'UserData',DATA);
    end

function PsychMenu(DATA)    
    if ~isfield(DATA,'figs')
        return;
    end
    hm = findobj(DATA.figs.VergPsych,'tag','ExptMenu');
    c = get(hm,'children');
    delete(c);
    for j = 1:length(DATA.Expts)
        if isfield(DATA.Expts{j},'Trials')
        nt = length(DATA.Expts{j}.Trials);
        sm = uimenu(hm,'Label', sprintf('Expt%d %s %d',j,Expt2Name(DATA.Expts{j}),nt),'CallBack', {@ChoosePsych, sprintf('Expt%d',j)});
        if j < length(DATA.plotexpts) && DATA.plotexpts(j)
            set(sm,'Checked','on');
        end
        end
    end
    sm = uimenu(hm,'Label', 'Current','Callback',{@ChoosePsych, 'Current'});
    if strcmp(DATA.psych.blockmode,'Current')
        set(sm,'Checked','On');
    end
    uimenu(hm,'Label', 'Only Current','Callback',{@ChoosePsych, 'OnlyCurrent'},'tag','OnlyCurrent');
    uimenu(hm,'Label', 'All','Callback',{@ChoosePsych, 'All'},'tag','All');
    uimenu(hm,'Label', 'One','Callback',{@ChoosePsych, 'OneOnly'},'tag','OneOnly');
    uimenu(hm,'Label', 'None','Callback',{@ChoosePsych, 'None'},'tag','None');
    
function DATA = CheckExpts(DATA)

    for j = 1:length(DATA.Expts)
        if j < length(DATA.Expts) && ~isfield(DATA.Expts{j},'last')
            DATA.Expts{j}.last = DATA.Expts{j+1}.first -1;
        end
    end
    
function DATA = PlotPsych(DATA)
    
    
    
    if isempty(DATA.Expts) || isempty(DATA.Trials)
        return;
    end
    if strmatch(DATA.psych.blockmode,'None')
        return;
    end
    DATA = CheckExpts(DATA);

    Expt = [];
    e = length(DATA.Expts);
    allid = [];
    if strcmp(DATA.psych.blockmode,'All') || sum(DATA.plotexpts)
        if strmatch(DATA.psych.blockmode,'All')
            expts = 1:e-1;
        else
            expts = find(DATA.plotexpts);
        end
        %can only combine expts if have same et,e2 types.  Check each
        %against last in list
        if sum(strcmp(DATA.psych.blockmode,{'Current' 'All'}))
            Expt = DATA.Expts{e};
        else
            Expt = DATA.Expts{expts(end)};
        end
        
        for j = expts
            if strcmp(DATA.Expts{j}.Stimvals.et,Expt.Stimvals.et) && ...
               strcmp(DATA.Expts{j}.Stimvals.e2,Expt.Stimvals.e2)
                allid= [allid DATA.Expts{j}.first:DATA.Expts{j}.last];
            end
        end
    else
        Expt = DATA.Expts{e};
    end
    %Always update trial list for current expt
    id = DATA.Expts{e}.first:length(DATA.Trials);
        DATA.Expts{e}.Trials = DATA.Trials(id);
    if Expt.first == DATA.Expts{e}.first  %using current
        if strmatch(DATA.psych.blockmode,{'All' 'Current' 'OnlyCurrent'})
         allid = [allid id];
        end
    end
    id = unique(allid);
    if length(id) < 2
        return;
    end
    Expt.Trials = DATA.Trials(id);
    Expt.Header.rc = 0;
    Expt.Header.expname  = 'Online';
    if isfield(Expt.Trials,'RespDir')
        Expt.Header.psych  = 1;
    else
        Expt.Header.psych  = 0;
    end
    
    f = {'m2' 'or' 'm3' 'n2'};
    for j = 1:length(f)
        if isfield(DATA.binoc{1},f{j})
            Expt.Stimvals.(f{j}) = DATA.binoc{1}.(f{j});
        end
    end    
    
    
    if DATA.psych.show
        DATA = SetFigure('VergPsych', DATA);
        hold off;
        if DATA.psych.trialresult
            plot([Expt.Trials.Start],[Expt.Trials.good],'o');
            datetick('x','hh:mm');
            axis('tight');
        else
        np = sum(abs([Expt.Trials.RespDir]) ==1); %psych trials
        Expt = FillTrials(Expt,Expt.Stimvals.et);
        Expt = FillTrials(Expt,Expt.Stimvals.e2);
        eargs = {};
        if np > 1
            if strcmp(Expt.Stimvals.e2,'od') && isfield(Expt.Stimvals,'or')
                for j = 1:length(DATA.expvals{2})
                    do = DATA.expvals{2}(j);
                    lo = Expt.Stimvals.or + do/2;
                    ro = Expt.Stimvals.or - do/2;
                    legendlabels{j} = sprintf('R%.0dL%.0f',ro,lo);
                end
                eargs = {eargs{:} 'legendlabels' legendlabels};
            end
            try
                [a,b] = ExptPsych(Expt,'nmin',1,'mintrials',2,'shown',eargs{:});
            catch ME
                fprintf('Error In ExptPsych %s\n',ME.message);
            end
            id = find(strcmp(Expt.Stimvals.et,{DATA.comcodes.code}));
            if length(id) == 1
                set(get(gca,'xlabel'),'string',DATA.comcodes(id).label);
            end
            if DATA.psych.crosshairs
                plot([0 0], get(gca,'ylim'),'k:')
                plot(get(gca,'xlim'),[0.5 0.5],'k:')
            end
        end
        end
    end
    DATA.Expt = Expt;
    
    
function DATA = CheckTimer(DATA)
    
    global rbusy;
    
    DATA.pipeerror = 0;
    c = get(DATA.toplevel,'color');
    if rbusy > 0
        set(DATA.toplevel,'color','r');
        DATA.pipeerror = 1;
    end
    if strcmp(get(DATA.timerobj,'running'),'off')
        set(DATA.toplevel,'color',[0 0 0.5]);
        DATA.pipeerror = 2;
    end
    if DATA.pipeerror == 0 && sum(c == DATA.windowcolor) < 3
        set(DATA.toplevel,'color',DATA.windowcolor);        
    end
