%% t_piLightType
%
%   Initial Experiments with Projected Lights
%   (with the hope that it can become a tutorial when it works:))
%
%   D. Cardinal, Stanford University, August, 2020
%
% See also
%

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file
thisR = piRecipeDefault('scene name','checkerboard');

% By default camera is [0 0 10], looking at [0 0 0].

% Remove all the lights
thisR.set('light', 'all', 'delete');


%% Add one projection light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
projectionLight = piLightCreate('ProjectedLight', ...
    'type','projection',...
    'scale',[1000 1000 1000],...
    'fov',90,...
    'power', 100000000, ...
    'filename string', 'skymaps/rainbow.exr');

%piLightTranslate(projectionLight, 'zshift', -5);
    thisR.set('light', projectionLight, 'add');


% Does translate happen before or after add?
%piLightTranslate(projectionLight, 'zshift', -5);



%% Render depth and radiance

thisR.set('render type',{'radiance','depth'});
thisR.set('name','ProjectionLight');

pLight = piAssetSearch(thisR,'lightname', 'projectedLight');

for ii = 0:3
    % Not working yet
    thisR.set('asset', pLight, 'rotation val', [0  0 90]);
    
    %piAssetRotate(thisR, pLight, [0 0 90]);
    % Check the light list
    thisR.show('lights');
    piWRS(thisR);
end


