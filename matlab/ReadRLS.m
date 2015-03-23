function ReadRLS(name, varargin)

txt = scanlines(name);

idid = find(strncmp('id',txt,2));
rlsid = find(~strncmp('id',txt,2));
for j = 1:length(rlsid)
    s = txt{rlsid(j)}
    id = strfind(':',s);
end