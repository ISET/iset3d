function properties =  piTextureProperties(textureType,varargin)
% List the valid properties for each type of texture
%
% Synopsis
%   properties =  piTextureProperties(textureType,varargin)
%
% Input
%  textureType - A valid texture type.
%
%          piTextureCreate('help')
%
%    returns a cell array of valid types
%
% Optional key/value pairs
%
%
% Returns
%  properties - A cell array of properties
%
% Description
%  Textures can be part of the material definition. This is a helper
%  function that lets the user know which parameters can be adjusted for
%  each texture type.
%
% See also
%  piTextureCreate, t_piIntro_texture, t_materials*s

% Examples:
%{
  tTypes = piTextureCreate('help');
  piTextureProperties(tTypes{5});
%}

%%
varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('quiet',false,@islogical);
p.parse(varargin{:});

%% We make a texture of that type
thisTexture = piTextureCreate('ignoreMe','type',textureType);

% We return its field names
properties = fieldnames(thisTexture);

% Print or not
if p.Results.quiet, return; end

fprintf('\n\n***  %s\n\n',textureType);
for jj=1:numel(properties)
    fprintf('\t%s \n',properties{jj});
end

end
