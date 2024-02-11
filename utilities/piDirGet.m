function resourceDir = piDirGet(resourceType)
% Returns default directory of a resource type.
%
% Synopsis
%   resourceDir = piDirGet(resourceType)
%
% Input
%   resourceType - One of
%     {'data','assets', 'lights', 'imageTextures', 
%     'lens', 'scenes','local', 'resources',
%     'server local', 'character-assets', 'character-recipes'}
%
% Output
%   resourceDir
%
% Description:
%   Most of these resources are in directories within iset3d-v4.  The
%   lens resources are in isetcam.
%
%
% D.Cardinal -- Stanford University -- May, 2022
% See also
%

% Example:
%{
  piDirGet('help')
  piDirGet('lens')
  piDirGet('assets')
%}

%% Parse
valid = {'data','assets', 'asset','lights', 'imageTextures', ...
    'textures','texture','materials','material','lens', 'lenses', ...
    'scenes','scene','local','server local', 'character-assets', ...
    'character-recipes','skymaps','resources'};

if isequal(resourceType,'help')
    disp(valid);
    return;
end

if isempty(resourceType) || ~ischar(resourceType) || ~ismember(resourceType,valid)
    fprintf('Valid resources are\n\n');
    disp(valid);
    error("%s is not a valid resource type",resourceType);
end

%% Set these resource directories once, here, in case we ever need to change them

ourRoot = piRootPath();
ourData = fullfile(ourRoot,'data');

% Now we can locate specific types of resources
switch (resourceType)
    case 'data'
        resourceDir = ourData;
    case {'assets','asset'}
        resourceDir = fullfile(ourData,'assets');
    case {'lights','light'}
        resourceDir = fullfile(ourData,'lights');
    case {'materials','material'}
        resourceDir = fullfile(ourData,'materials');
    case {'imageTextures','textures','texture'}
        % imageTextures is legacy and will be deprecated
        % Moved textures inside of materials Aug 1, 2022. (BW).
        resourceDir = fullfile(ourData,'materials','textures');
    case {'lens', 'lenses'}
        resourceDir = fullfile(isetRootPath,'data','lens');

    case {'scenes','scene'}
        resourceDir = fullfile(ourData,'scenes');
    case {'skymaps'}
        resourceDir = fullfile(ourData,'skymaps');
    case 'local'
        resourceDir = fullfile(ourRoot,'local');
    case 'character-assets'
        % put characters in a sub-folder of assets for now
        resourceDir = fullfile(piDirGet('assets'),'characters');
    case 'character-recipes'
        % put characters in a sub-folder of assets for now
        resourceDir = fullfile(ourData,'characters');
    case 'server local'
        % should really be someplace else!
        resourceDir = '/iset/iset3d-v4/local'; % default
    case 'resources'
        % default for Vistalab, other sites need to change
        resourceDir =  getpref('docker','resourceLocation','/acorn/data/iset/Resources');
end


end
