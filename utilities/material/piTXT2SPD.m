% Convert measured txt to spd file
function outfile = piTXT2SPD(infile)
[path,name,~] = fileparts(infile);
tmpFilename   = fullfile(path,[name '_tmp.txt']);
outfile       = fullfile(path,[name '.spd']);

spd           = textread(infile);
wavelength    = spd(:,1);
data          = spd(:,2);

fileID        = fopen(tmpFilename,'w');

for ii = 1:length(data)
    
    if(mod(wavelength(ii),0))
        %  Neater
        fprintf(fileID,'%d %.7f\n',wavelength(ii),data(ii));
    else
        fprintf(fileID,'%f %.7f\n',wavelength(ii),data(ii));
    end
    
end
movefile(tmpFilename,outfile);
fclose(fileID);
end