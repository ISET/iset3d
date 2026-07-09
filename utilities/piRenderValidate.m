function [assetList, missingAssets,...
          textureList, missingTextures,...
          lightList, missingLights] = piRenderValidate(thisR)
% Validate the existence of files needed for rendering.
%
% Synopsis:
%   [assetList, missingAssets,...
%    textureList, missingTextures,...
%    lightList, missingLights] = piRenderValidate(thisR)
%
% Inputs:
%   thisR:
%
% Outputs:
%   
%
% Examples:
%{
  thisR = piJson2Recipe('SimpleScene.json');

  [assetList, missingAssets,...
   textureList, missingTextures,...
   lightList, missingLights] = piRenderValidate(thisR);
%}
%% Parse input
p = inputParser;
p.addRequired('thisR', @(x)isequal(class(thisR), 'recipe'));
p.parse(thisR);

%% Textures
textureList = {};
missingTextures = [];

tList = thisR.textures.list;
textureValues = localCollectionValues(tList);
for ii = 1:numel(textureValues)
    curTexture = textureValues{ii};
    if isfield(curTexture, 'filename') && ~isempty(curTexture.filename.value)
        fpath = localRenderResourcePath(thisR, curTexture.filename.value, 'textures');
        textureList{end + 1} = fpath;
        if ~localResourceExists(thisR, fpath)
            missingTextures(end + 1) = numel(textureList);
        end
    end
end

%% Lights
lightList = {};
missingLights = [];

lgtList = thisR.lights;
for ii = 1:numel(lgtList)
    curLight = lgtList{ii};
    % Infinite lights needs an image map (changed to filename 8/19/23
    if isfield(curLight, 'filename') && ~isempty(curLight.filename.value)
        fpath = localLightFilePath(thisR, curLight.filename.value);
        lightList{end + 1} = fpath;
        if exist(fpath, 'file')
        else
            missingLights(end + 1) = numel(lightList);
        end
    end

    % Sometimes the light needs .spd spectrum file
    if ischar(curLight.spd.value)
        fpath = localLightSpdPath(thisR, curLight.spd.value);
        if ~isempty(fpath)
            lightList{end + 1} = fpath;
            if exist(fpath, 'file')
            else
                missingLights(end + 1) = numel(lightList);
            end
        end
    end
end

%% Shape filenames of the leaf nodes
assetList = {};
missingAssets = [];

ids = thisR.assets.findleaves;
for ii = 1:numel(ids)
    curNode = thisR.get('assets', ids(ii));
    if isequal(curNode.type, 'object')
        if isfield(curNode.shape, 'filename') && ~isempty(curNode.shape.filename)
            fpath = fullfile(thisR.get('output dir'), curNode.shape.filename);
            assetList{end + 1} = fpath;
            if exist(fpath, 'file')
            else 
                missingAssets(end + 1) = numel(assetList);
            end
        end
    elseif isequal(curNode.type, 'light')
        for jj = 1:numel(curNode.lght)
            curLight = curNode.lght{jj};
            if isfield(curLight, 'filename') && ~isempty(curLight.filename.value)
                fpath = localLightFilePath(thisR, curLight.filename.value);
                lightList{end + 1} = fpath;
                if exist(fpath, 'file')
                else
                    missingLights(end + 1) = numel(lightList);
                end
            end

            if ischar(curLight.spd.value)
                fpath = localLightSpdPath(thisR, curLight.spd.value);
                if ~isempty(fpath)
                    lightList{end + 1} = fpath;
                    if exist(fpath, 'file')
                    else
                        missingLights(end + 1) = numel(lightList);
                    end
                end
            end
        end

    end
end

if sum(missingAssets) + sum(missingTextures) +  sum(missingLights)> 0
    warning('Some files are not found, please check')
end
end

function valuesList = localCollectionValues(collection)
%% Return collection contents as a cell array for maps, structs, and cells.

if isempty(collection)
    valuesList = {};
elseif isa(collection, 'containers.Map')
    valuesList = values(collection);
elseif iscell(collection)
    valuesList = collection;
elseif isstruct(collection)
    valuesList = num2cell(collection);
else
    valuesList = {};
end

end

function fpath = localRenderResourcePath(thisR, resourceName, resourceFolder)
%% Resolve the local staged path expected for a render resource.

if isempty(resourceName)
    fpath = '';
    return;
end

resourceName = char(resourceName);
[resourcePath, resourceBase, resourceExt] = fileparts(resourceName);
resourceFile = [resourceBase, resourceExt];

if localIsAbsolutePath(resourceName)
    if thisR.useDB
        fpath = resourceName;
    else
        fpath = fullfile(thisR.get('output dir'), resourceFolder, resourceFile);
    end
elseif isempty(resourcePath)
    fpath = fullfile(thisR.get('output dir'), resourceFolder, resourceFile);
else
    fpath = fullfile(thisR.get('output dir'), resourceName);
end

end

function tf = localResourceExists(thisR, fpath)
%% Return true when a local staged resource exists or DB mode owns the path.

if isempty(fpath)
    tf = false;
elseif thisR.useDB && localIsAbsolutePath(fpath)
    % DB-backed resources may live only on the mounted remote resource tree.
    tf = true;
else
    tf = exist(fpath, 'file') == 2;
end

end

function fpath = localLightFilePath(thisR, resourceName)
%% Resolve the staged path for a light's image map (skymap/goniometric) file.
%
% Mirrors the prefix logic in piLightGet.m ('filename' case) and the
% staging locations used by piLightWrite.m, which puts image maps in the
% output directory's 'skymaps' subfolder unless the path is already
% absolute, already contains 'skymaps/', or is an 'instanced/' path.

resourceName = char(resourceName);
if localIsAbsolutePath(resourceName)
    % A full path (e.g. into a remote-mounted resource tree) is used as-is.
    fpath = resourceName;
elseif contains(resourceName, 'instanced/') || contains(resourceName, 'skymaps/')
    fpath = fullfile(thisR.get('output dir'), resourceName);
else
    fpath = fullfile(thisR.get('output dir'), 'skymaps', resourceName);
end

end

function fpath = localLightSpdPath(thisR, spdValue)
%% Resolve the staged path for a light's spd value, if it names a file.
%
% Mirrors piLightGet.m ('spd' case) and piLightWrite.m: a value with a
% '.spd' extension is a user-supplied file staged in the output
% directory; any other named spectrum (e.g. a .mat file or spectrum
% name) is written out as 'spds/lights/<ieParamFormat(name)>.spd'.

[~, ~, e] = fileparts(spdValue);
if isequal(e, '.spd')
    fpath = fullfile(thisR.get('output dir'), spdValue);
elseif ~isempty(e)
    fpath = fullfile(thisR.get('output dir'), 'spds', 'lights', ...
        sprintf('%s.spd', ieParamFormat(spdValue)));
else
    fpath = '';
end

end

function tf = localIsAbsolutePath(pathName)
%% True for Unix and Windows absolute paths.

pathName = char(pathName);
tf = startsWith(pathName, filesep) || ...
    ~isempty(regexp(pathName, '^[A-Za-z]:[\\/]', 'once'));

end
