function MakeRLs(varargin)



fid = fopen('/local/Images/binoc/lem000.100.rls','w');
ndots = 50;
nframes = 50;
fprintf(fid,'1DNoise %d Frames %d Dots\n',nframes,ndots);
for f = 0:nframes-1
    fprintf(fid,'%dL:',f);
    for d = 1:ndots
        c = floor( 256 * (sin((d+f)/2) +1)/2);
        fprintf(fid,'%02x',c);
    end
    fprintf(fid,'\n%dR:',f);
    for d = 1:ndots
        c = floor( 256 * (sin((d-f)./2) +1)/2);
        fprintf(fid,'%02x',c);
    end
    fprintf(fid,'\n');
end
fclose(fid);