function scene = piAssetShow(thisR,varargin)
% Quickly render an asset
%
% Input
%  thisR - The asset recipe from s_assetsRecipe
%
% Optional key/val
%  object distance
%
% Output
%  scene
%
% Description
%   Adds a light, maybe sets another parameter, renders a scene with piWRS
%
% See also
%  s_assetsRecipe
%

%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('objectdistance',[],@isnumeric);
p.parse(thisR,varargin{:});

%%
lgt = piLightCreate('point','type','point');
thisR.set('light',lgt,'add');

if ~isempty(p.Results.objectdistance)
    thisR.set('object distance',p.Results.objectdistance);
end

scene = piWRS(thisR);

end
