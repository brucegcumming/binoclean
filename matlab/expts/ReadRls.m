function nbars = ReadRls(name)

fid = fopen(name,'r');
if fid < 0
    return;
end
nbars = 0;

a = textscan(fid,'%s','delimiter','\n');
txt = a{1};

for j = 1:length(txt)
    if strfind(txt{j},':')
        bid = strfind(txt{j},'a');
        wid = strfind(txt{j},'0');
        nbars(j,1) = length(wid);
        nbars(j,2) = length(bid);
    end
end
