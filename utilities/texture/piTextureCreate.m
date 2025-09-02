function texture = piTextureCreate(name, varargin)
% Initialize a texture with specific parameters
%
% Synopsis
%   texture = piTextureCreate(name,varargin);
%
% Inputs:
%   name    - name of a texture
%
% Optional key/val pairs
%
%   The key/val options depend on the type of texture.  Use
%   piTextureCreate('help') to see the valid texture types.  Once you have
%   a texture type, you can use this method to see its PBRT parameters.
%
%       piTextureProperties(textureType)
%
%   These are the PBRT properties that you can set for that textureType.
%
% Outputs:
%   texture - new texture with parameters
%
% See also
%   piTextureProperties, piMaterialPresets, t_piIntro_texture,
%      t_targetsOverview 
%

% Examples
%{
  tTypes = piTextureCreate('help');
%}
%{
  texture = piTextureCreate('checkerboard_texture',...
        'type', 'checkerboard',...
        'uscale', 8,...
        'vscale', 8,...
        'tex1', [.01 .01 .01],...
        'tex2', [.99 .99 .99]);
%}

%% List available texture types

varargin = ieParamFormat(varargin);

p = inputParser;
p.KeepUnmatched = true;
p.addRequired('name',@ischar);
p.addParameter('quiet',false,@islogical);
p.parse(name,varargin{:});

validTextures = {'constant','scale','mix','bilerp','imagemap',...
    'checkerboard','dots','fbm','wrinkled','marble','windy'};

if isequal(ieParamFormat(name),'listavailabletypes') || ...
        isequal(ieParamFormat(name),'help')

    texture = validTextures;
    if p.Results.quiet, return; end

    fprintf('\n\n***  Valid textures ***\n\n');
    for jj=1:numel(texture)
        fprintf('\t%s \n',texture{jj});
    end

    return;
end

%% Needed rather than ieParamFormat because of PBRT syntax issues

for ii=1:2:numel(varargin)
    varargin{ii} = strrep(varargin{ii}, ' ', '');
end

%% Parse inputs
p = inputParser;
p.addRequired('name', @ischar);
p.addParameter('type', 'constant', @ischar);
p.addParameter('format', 'spectrum', @ischar);
p.KeepUnmatched = true;
p.parse(name, varargin{:});

tp   = ieParamFormat(p.Results.type);
form = ieParamFormat(p.Results.format);

%% Construct material struct
texture.name = name;
texture.format = form;

switch tp
    % Any-D
    % Constant, Scale, Mix
    case 'constant'
        texture.type = 'constant';

        texture.value.type = 'float';
        texture.value.value = [];
    case 'scale'
        texture.type = 'scale';
        
        texture.scale.type = 'float';
        texture.scale.value = [];
        
        texture.tex.type = 'texture';
        texture.tex.value = [];

    case 'mix'
        texture.type = 'mix';

        texture.tex1.type = 'float';
        texture.tex1.value = [];

        texture.tex2.type = 'float';
        texture.tex2.value = [];

        texture.amount.type = 'float';
        texture.amount.value = [];

    case 'directionmix'
        texture.type = 'directionmix';

        texture.tex1.type = 'texture';
        texture.tex1.value = [];

        texture.tex2.type = 'texture';
        texture.tex2.value = [];

        texture.dir.type = 'vector3';
        texture.dir.value = [];
    % 2D
    % Bilerp, Image, UV, Checkerboard, Dots
    case 'bilerp'
        texture.type = 'bilerp';

        texture.v00.type = 'float';
        texture.v00.value = [];

        texture.v01.type = 'float';
        texture.v01.value = [];

        texture.v10.type = 'float';
        texture.v10.value = [];

        texture.v11.type = 'float';
        texture.v11.value = [];

        % Common property for 2D texture
        texture.mapping.type = 'string';
        texture.mapping.value = '';

        texture.uscale.type = 'float';
        texture.uscale.value = [];

        texture.vscale.type = 'float';
        texture.vscale.value = [];

        texture.udelta.type = 'float';
        texture.udelta.value = [];

        texture.vdelta.type = 'float';
        texture.vdelta.value = [];

        texture.v1.type = 'vector3';
        texture.v1.value = [];

        texture.v2.type = 'vector3';
        texture.v2.value = [];
    case 'imagemap'
        texture.type = 'imagemap';

        texture.filename.type = 'string';
        texture.filename.value = '';

        texture.basisfilename.type = 'string';
        texture.basisfilename.value = '';

        texture.wrap.type = 'string';
        texture.wrap.value = '';

        texture.maxanisotropy.type = 'float';
        texture.maxanisotropy.value = [];

        texture.trilinear.type = 'bool';
        texture.trilinear.value = [];

        texture.scale.type = 'float';
        texture.scale.value = [];

        texture.gamma.type = 'bool';
        texture.gamma.value = [];

        % this is new in v4 and relates to gamma
        % but not sure if it replaces or extends 
        texture.encoding.type = 'string';
        texture.encoding.value = [];

        % Basis features
        texture.basis.type = 'string';
        texture.basis.value = '';

        texture.basisone.type = 'spectrum';
        texture.basisone.value = [];

        texture.basistwo.type = 'spectrum';
        texture.basistwo.value = [];

        texture.basisthree.type = 'spectrum';
        texture.basisthree.value = [];


        % Common property for 2D texture
        texture.mapping.type = 'string';
        texture.mapping.value = '';

        texture.uscale.type = 'float';
        texture.uscale.value = [];

        texture.vscale.type = 'float';
        texture.vscale.value = [];

        texture.udelta.type = 'float';
        texture.udelta.value = [];

        texture.vdelta.type = 'float';
        texture.vdelta.value = [];

        texture.v1.type = 'vector3';
        texture.v1.value = [];

        texture.v2.type = 'vector3';
        texture.v2.value = [];

        % AJ: don't hardcode invert to false
        texture.invert.type = 'bool';
        texture.invert.value = [];
        % texture.invert.value = 'false';
    case 'checkerboard'
        texture.type = 'checkerboard';

        texture.dimension.type = 'integer';
        texture.dimension.value = [];

        texture.tex1.type = 'float';
        texture.tex1.value = [];

        texture.tex2.type = 'float';
        texture.tex2.value = [];

        % BW - We should ask Zheng about these spectral fields for the
        % checkerboard.  The parameters have been commented out in
        % piTextureCreate, and piWrite routine should allow these
        % parameters but write them out in a way I don't yet
        % understand.  At this time, we simply ignore the parameters
        % and issue a warning.
        %
        % texture.spectrumtex1.type = 'float';
        % texture.spectrumtex1.val = [];
        
        % texture.spectrumtex2.type = 'float';
        % texture.spectrumtex2.val = [];
        
        texture.aamode.type = 'string';
        texture.aamode.value = '';

        % Common property for 2D texture
        texture.mapping.type = 'string';
        texture.mapping.value = '';

        texture.uscale.type = 'float';
        texture.uscale.value = [];

        texture.vscale.type = 'float';
        texture.vscale.value = [];

        texture.udelta.type = 'float';
        texture.udelta.value = [];

        texture.vdelta.type = 'float';
        texture.vdelta.value = [];

        texture.v1.type = 'vector3';
        texture.v1.value = [];

        texture.v2.type = 'vector3';
        texture.v2.value = [];

    case 'dots'
        texture.type = 'dots';

        texture.inside.type = 'float';
        texture.inside.value = [];

        texture.outside.type = 'float';
        texture.outside.value = [];

         % Common property for 2D texture
        texture.mapping.type = 'string';
        texture.mapping.value = '';

        texture.uscale.type = 'float';
        texture.uscale.value = [];

        texture.vscale.type = 'float';
        texture.vscale.value = [];

        texture.udelta.type = 'float';
        texture.udelta.value = [];

        texture.vdelta.type = 'float';
        texture.vdelta.value = [];

        texture.v1.type = 'vector3';
        texture.v1.value = [];

        texture.v2.type = 'vector3';
        texture.v2.value = [];

    % 3D
    % Checkerboard, FBm, Wrinkled, Marble, Windy
    case 'fbm'
        texture.type = 'fbm';

        texture.octaves.type = 'integer';
        texture.octaves.value = [];

        texture.roughness.type = 'float';
        texture.roughness.vlaue = [];

    case 'wrinkled'
        texture.type = 'wrinkled';

        texture.octaves.type = 'integer';
        texture.octaves.value = [];

        texture.roughness.type = 'float';
        texture.roughness.value = [];

    case 'marble'
        texture.type = 'marble';

        texture.octaves.type = 'integer';
        texture.octaves.value = [];

        texture.roughness.type = 'float';
        texture.roughness.value = [];

        texture.scale.type = 'float';
        texture.scale.value = [];

        texture.variation.type = 'float';
        texture.variation.value = [];
    case 'windy'
        % This texture is missing. Something to check
        texture.type = 'windy';
    otherwise
        warning('Texture type: %s does not exist', tp)
        return;
end

%% Put in key/val

for ii=1:2:numel(varargin)
    thisKey = varargin{ii};
    thisVal = varargin{ii + 1};

    if isequal(thisKey, 'type')
        % Skip since we've taken care of material type above.
        continue;
    end

    keyTypeName = strsplit(thisKey, '_');

    % keyName is the property name. if it follows 'TYPE_NAME', we need
    % later, otherwise we need the first one.
    if piMaterialIsParamType(keyTypeName{1})
        keyName = ieParamFormat(keyTypeName{2});
    else
        keyName = ieParamFormat(keyTypeName{1});
    end


    if isfield(texture, keyName)
        texture = piTextureSet(texture, sprintf('%s value', keyName),...
                                thisVal);
    else
        warning('Parameter %s does not exist in texture %s',...
                    keyName, texture.type)
    end
end


%%
%{
%% Parse inputs
varargin = ieParamFormat(varargin);
p = inputParser;
p.KeepUnmatched = true;
p.parse(varargin{:});

%% Get how many textures exist already
val = numel(piTextureGet(thisR, 'print', false));
idx = val + 1;
%% Construct texture structure
texture.name = strcat('Default texture ', num2str(idx));
thisR.textures.list{idx} = texture;

if isempty(varargin)
    % if no parameters, provide a default constant texture
    texture.format = 'float';
    texture.type = 'constant';
    texture.floatvalue = 1;
    thisR.textures.list{idx} = texture;
else
    for ii=1:2:length(varargin)
        texture.(varargin{ii}) = varargin{ii+1};
        piTextureSet(thisR, idx, varargin{ii}, varargin{ii+1});
    end
end
%}
end
