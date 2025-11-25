function asset = piAssetLoad(fname,varargin)
% Load a mat-file containing an asset recipe
%
% Synopsis
%   asset = piAssetLoad(fname,varargin)
%
% Input
%   fname - filename of the asset mat-file, or 'help' or 'list' to see the
%           assets in piDirGet('assets') (but not character-assets).
%
% Output
%  asset - a struct containing the recipe and the mergeNode
%
%   asset.thisR     - recipe for the asset
%   asset.mergeNode - Node in the asset tree to be used for merging
%
% Description
%   We store certain assets as mat-files that contain a recipe.  These
%   recipes be loaded (piAssetLoad) and then merged into any other
%   scene recipe. 
% 
%   The assets are created and stored in the script s_assetsCreate. The
%   piRecipeMerge function combines the asset into the scene. The asset
%   recipe is stored along with the name of the critical node used for
%   merging. 
%
% See also
%   piRecipeMerge, piDirGet('assets'), dir(piDirGet('assets'))
%

% Examples:
%{
 thisR = piRecipeCreate('flat surface');
 piMaterialsInsert(thisR,'groups','test patterns');
 idx = piAssetSearch(thisR,'object name','Cube');
 thisR.set('asset',idx,'Material name','macbethchart');
 thisR.set('asset',idx,'scale',[.3 0.2 .2]*0.9);
 piWRS(thisR);
%}

%% Parse 

if ismember(ieParamFormat(fname),{'list','help'})
    tmp = dir(fullfile(piDirGet('assets'),'*.mat'));
    fprintf('\n\nAsset files (not character-assets)\n----------\n\n');
    for ii=1:numel(tmp)
        fprintf('%03d\t%s\n',ii,tmp(ii).name');
    end
    return;
end

% Check the extension, make sure it is mat
[filePath,n,e] = fileparts(fname);
if isempty(e), e = '.mat'; end
fname = fullfile(filePath,[n,e]);

varargin = ieParamFormat(varargin);
p = inputParser;
p.addRequired('fname',@ischar);

validTypes = {'scene','character'};
p.addParameter('assettype','scene',@(x)(ismember(x,validTypes)));

p.parse(fname,varargin{:});
assetType = p.Results.assettype;

%% We need a mat-file, preferably from the data/assets directory

if isempty(filePath)
    % If the user specified a name, but not a path, look in the data/assets
    % directory
    switch assetType
        case 'scene'
            fname = fullfile(piDirGet('assets'),[n e]);
            pbrtFile = fullfile(piDirGet('assets'),n,[n '.pbrt']);
        case 'character'
            % The letters are stored as an iset3d-scene deposit
            % The file with the characters (letters) is characters.zip
            downloadDir = piDirGet('assets');
            if ~exist(fullfile(downloadDir,'characters'),'dir')
                ieWebGet('deposit file', 'characters', 'deposit name', 'iset3d-scenes', ...
                    'download dir',downloadDir,'unzip', true);
            end
            fname = fullfile(piDirGet('character-assets'),[n e]);
            pbrtFile = fullfile(piDirGet('character-assets'),n,[n '.pbrt']);
        otherwise
            error('Unknown asset type %s',assetType);
    end
end
if exist(fname,'file')
    asset = load(fname);
elseif exist(pbrtFile,'file')
    asset.thisR = piRead(pbrtFile);
else
    error('File not found:%s.\n',fname);
end

%% Adjust the input slot in the recipe for the local user.

% The asset was written out by a specific user.  But another user on
% another system is loading it. So we need to adjust the location of the
% input file to match this user for the recipe (thisR).

inFile = asset.thisR.get('input file');
switch assetType
    case 'scene'
        % We may need to do more here.  This only works if the directory
        % name and scene file name are the same. Check the bunny. 
        [~,n,e] = fileparts(inFile);
        asset.thisR.set('inputfile',fullfile(piDirGet('scenes'),n,[n,e]));
    case 'character'
        [~,n, e] = fileparts(inFile);
        % assume folder name is the same as pbrt file prefix
        asset.thisR.set('inputfile',fullfile(piDirGet('character-assets'),n,[n e]));
end

% Find the name of the directory containing the original recipe input file
% from the original person
%  [thePath,n,e] = fileparts(asset.thisR.get('input file'));

% Cross-platform issue: 
% Window paths will have \, Linux/Mac /.  We need to be able to get the 
% but we don't know what has been encoded in there.
% if contains(thePath, '/'),     temp = split(thePath,'/');
% else,                          temp = split(thePath,'\');
% end
% theDir = temp{end};

% inFile = fullfile(piDirGet('scenes'),theDir,[n,e]);

% Make sure it exists or try characters
% PS I still don't really understand all this re-mapping
%    and wish we could just get rid of it somehow
% if ~isfile(inFile)
%     inFile = fullfile(piDirGet('character-recipes'),theDir,[n,e]);
%     if ~isfile(inFile)
%         error('Cannot find the PBRT input file %s\n',thisR.inputFile); 
%     end
% end

% Set it
% asset.thisR.set('input file',inFile);

%% Adjust the input slot in the recipe for the local user

% { 
% One theory is we just empty the outputfile (see below).  This is an
% asset that will be inserted into another recipe. Another theory is we set
% it so that we could run piWRS(asset.thisR)
[thePath,n,e] = fileparts(asset.thisR.get('output file'));

% Find the last element of the path
temp = split(thePath,filesep);
theDir = temp{end};

% The file name for this user should be
outFile=fullfile(piRootPath,'local',theDir,[n,e]);

asset.thisR.set('output file',outFile);
%}

% If you comment above, then uncomment this
% asset.thisR.set('output file','');

end
