function ieObject = piRenderCloud(thisR,varargin)
%% render using a google VM
%{
%}
%%
p = inputParser;
p.KeepUnmatched = true;

% p.addRequired('pbrtFile',@(x)(exist(x,'file')));
p.addRequired('recipe',@(x)(isequal(class(x),'recipe') || ischar(x)));

varargin = ieParamFormat(varargin);
% p.addParameter('meanluminance',100,@isnumeric);
% p.addParameter('meanilluminancepermm2',[],@isnumeric);
% p.addParameter('scalepupilarea',true,@islogical);
p.addParameter('update',false,@islogical);
p.addParameter('cleandata',false,@islogical);
% p.addParameter('reflectancerender', false, @islogical);
p.addParameter('instancename','zhenyi27@holidayfun-zhenyi',@ischar);
p.addParameter('zone','us-west1-a',@ischar);
p.addParameter('wave', 400:10:700, @isnumeric); % This is the past to piDat2ISET, which is where we do the construction.
p.addParameter('verbose', 2, @isnumeric);

p.parse(thisR,varargin{:});
% scalePupilArea = p.Results.scalepupilarea;
% meanLuminance    = p.Results.meanluminance;
wave             = p.Results.wave;
% verbosity        = p.Results.verbose;
zone             = p.Results.zone; % cloud zone name;
instanceName     = p.Results.instancename; % cloud instance name
update           = p.Results.update; % only update modified pbrt files
cleandata        = p.Results.cleandata; % delete data in VM folder

%%
tic
disp('*** Start rendering using a gcloud instance...');
inputFolder = thisR.get('output dir');
[rootDir,fname]=fileparts(inputFolder);
vmFolder = '~/git_repo/renderVolume';
localFolder = fullfile(inputFolder,'renderings');

baseCmd = sprintf('gcloud compute ssh --zone=%s %s ',...
    zone, instanceName);
if ~update
    % zip folder
    zipName = [fname,'.zip'];
    zipFile = fullfile(rootDir,zipName);
    list = {'scene','bsdf','*.ply','*.pbrt','texture','*.exr','*.png'};
    zip(zipFile, list, inputFolder);
    % upload folder to google instance/ unzip/ render/ and bring back
    disp('Uploading the scene...');
    cmd = sprintf('gcloud compute scp --zone=%s %s %s:%s',...
        zone, zipFile, instanceName,vmFolder);
    [status] = system(cmd);
    if status
        error(result)
    end
    disp('Rendering...');
    renderCmd = strcat(baseCmd, sprintf(' --command ''cd %s && unzip -o %s && cd %s && ~/git_repo/PBRT-GPU/pbrt-zhenyi/build/pbrt --gpu %s --outfile %s''  ',...
        vmFolder, zipName, fname,[fname, '.pbrt'],[fname, '.exr']));
    
    [status] = system(renderCmd);
    if status
        error(result)
    end
else
    % only pbrt files
    filenames = [inputFolder,'/*.pbrt'];
     disp('Uploading the scene...');
    cmd = sprintf('gcloud compute scp --zone=%s %s %s:%s',...
        zone, filenames, instanceName,fullfile(vmFolder,fname));
    [status] = system(cmd);
    if status
        error(result)
    end
    disp('Rendering...');
    renderCmd = strcat(baseCmd, sprintf(' --command ''cd %s && ~/git_repo/PBRT-GPU/pbrt-zhenyi/build/pbrt --gpu %s --outfile %s''  ',...
        fullfile(vmFolder,fname), [fname, '.pbrt'],[fname, '.exr']));    
    [status] = system(renderCmd);
    if status
        error(result)
    end
end

if ~exist(localFolder,'dir'), mkdir(localFolder);end
GetDataCMD = sprintf('gcloud compute scp --zone=%s %s:%s %s',...
    zone, instanceName, fullfile(vmFolder, fname, [fname, '.exr']), localFolder);
[status] = system(GetDataCMD);
if status
    error(result)
else
    outFile  = fullfile(localFolder, [fname, '.exr']);
end

if cleandata
    % clean data
    disp('Data cleaning...');
    delete(zipFile);
    [status]= system(strcat(baseCmd,sprintf(' --command ''rm -r %s && mkdir %s''',vmFolder,vmFolder)));
end
%%
elapsedTime = toc;
fprintf('Rendering time for %s:  %.1f sec ***\n\n',fname,elapsedTime);

%% Convert the returned data to an ieObject
disp('Creating iset object');
if isempty(thisR.metadata)
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',{'radiance'});
else
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',thisR.metadata.rendertype);
end
%%
if isstruct(ieObject)
    switch ieObject.type
        case 'scene'
            curWave = sceneGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = sceneSet(ieObject, 'wave', wave);
            end
            
        case 'opticalimage'
            curWave = oiGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = oiSet(ieObject,'wave',wave);
            end
            
        otherwise
            error('Unknown struct type %s\n',ieObject.type);
    end
end
disp('*** Done');
end