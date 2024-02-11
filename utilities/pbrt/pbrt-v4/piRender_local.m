function ieObject = piRender_local(thisR, pbrtPath)
%% temp function, will be replaced by a docker based function
% 
%
outfile  = thisR.get('output file');
[outputDir, fname,~] = fileparts(outfile);
currDir    = pwd;
cd(outputDir);
outputFile = fullfile(outputDir, [fname,'.exr']);
renderCmd  = [pbrtPath, ' --gpu ',thisR.outputFile,' --outfile ',outputFile];
system(renderCmd)
cd(currDir);

%%
%% read data
energy   = piReadEXR(outputFile);
wave = 400:10:700;
photons  = Energy2Quanta(wave,energy);
ieObject = piSceneCreate(photons,'wavelength', wave);
% get depth
% depthImage   = piReadEXR_python(outputFile,'data type','zdepth');
% ieObject = sceneSet(ieObject,'depth map',depthImage);
end