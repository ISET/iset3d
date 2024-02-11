function instanceMap = piRenderAnnotation_local(thisR, pbrtPath)
%% temp function, will be replaced by a docker based function
% 
%
outfile  = thisR.get('output file');
[outputDir, fname,~] = fileparts(outfile);
currDir    = pwd;
cd(outputDir);
outputFile = fullfile(outputDir, [fname,'-instanceMap.exr']);
renderCmd  = [pbrtPath, ' --spp 4 ',thisR.outputFile,' --outfile ',outputFile];
system(renderCmd)
cd(currDir);

%%
%% read data
instanceMap = piEXR2Mat([fname,'-instanceMap.exr'], 'InstanceId');
end