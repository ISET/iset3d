%% Illustrate the control of certain scene lights
%
%  There are several types of lights that can be placed in a scene.
%
%  Each of the different type of lights has a number of parameters that
%  control its properties.  We control the parameters with the recipe set
%  command, such as
%
%    thisR.set('light ' .....)
% 
% Here we illustrate examples for creating and setting properties of
%
%     * Spot lights (cone angle, cone delta angle, position)
%     * SPD: RGB and Spectrum
%     * Environment lights (skymap)
%
% There is another tutorial specifically designed for area lights
%
% The PBRT book definitions for lights are:
%      https://www.pbrt.org/fileformat-v3.html#lights
%
% See also
%   t_arealight, s_arealight

%% Initialize ISET and Docker and read a file

% Start up ISET/ISETBio and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name','checkerboard');

%% Check the light list that came with the scene

% To summarize the lights use this
lNames = thisR.get('light print');

% We can get a specific light by its name
thisR.get('light', lNames{1})

% Or we can get the light from its index (number) in this list.
idx = piAssetSearch(thisR,'light name',lNames{1});
thisR.get('light', idx)

%% Remove all the lights

thisR.set('light', 'all', 'delete');
thisR.get('light print');

%% Types of lights

% There are a few different types of lights.  The different types we
% control in ISET3d are defined in piLightCreate;  To see the list of
% possible light types use
%
piLightCreate('list available types')

%% Add a spot light
%
% The spot light is defined by
%
%  * the cone angle parameter, which describes how far the spotlight
%  spreads (in degrees of visual angle), and
%  * the cone delta angle parameter describes how rapidly the light falls
%  off at the edges (also in degrees).
%

% NOTE: 
% Unlike most of ISET3d, you do not have the freedom to put spaces into the
% key/val parameters for piLightCreate.  Thus, coneangle cannot be 'cone
% angle'.
%
% Until the v4 textbook is published, only informal sources are available
% for light parameters.
% 
% Many are the same as v3, documented here
%   https://www.pbrt.org/fileformat-v3.html#lights
%
% But there are a lot of changes for v4. Here is a web resource we use:
%   https://github.com/shadeops/pbrt_v3-to-v4_migration
%
% We are also starting to add v4 information to the iset3D wiki:
%
lightName = 'new_spot_light_L';
newLight = piLightCreate(lightName,...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 1, ...
                        'coneangle', 15,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);
thisR.set('light', newLight, 'add');
thisR.get('light print');

%% Set up the render parameters

% This moves the camera closer to the color checker,
% which illustrates the effects of interest here better.
% 
% Shift is in meters.  You have to know something about the
% scale of the scene to use this sensibly.
piCameraTranslate(thisR,'z shift',1); 

piWRS(thisR,'name','Equal energy (spot)');

%%  Narrow the cone angle of the spot light a lot

% We just have one light, and can set its properites with
% piLightSet, indexing into the first light.
coneAngle = 10;

thisR.set('light', lightName, 'coneangle', coneAngle);

piWRS(thisR,'name',sprintf('EE spot %d',coneAngle));

%% Shift the light to the right

% The general syntax for the set is to indicate
%
%   'light' - action - lightName or index - parameter value
%
% We shift the light here by 0.1 meters in the x-direction.
thisR.set('light', 'new_spot_light_L', 'translate',[1, 0, 0]);

piWRS(thisR,'name',sprintf('EE spot %d',coneAngle));

%% Rotate the direction of the spot light

% thisR.set('light', 'rotate', lghtName, [XROT, YROT, ZROT], ORDER)
thisR.set('light', 'new_spot_light_L', 'rotate', [0, -15, 0]); % -15 degree around y axis
piWRS(thisR,'name',sprintf('Rotate EE spot'));

%%  Change the light to a point light source 

thisR.set('light', 'all', 'delete');

% Create a point light at the camera position
% The 'spd spectrum' string is a mat-file saved in
% ISETCam/data/lights
yellowPoint = piLightCreate('yellow_point_L',...
    'type', 'point', ...
    'spd spectrum', 'Tungsten',...
    'specscale float', 1,...
    'cameracoordinate', true);

thisR.set('light', yellowPoint, 'add');

% Move the point closer to the object
thisR.set('light','yellow_point_L','translate',[0 0 -7]);
thisR.get('light print');
piWRS(thisR,'name','Tungsten (point)');

%% Add a second point just to the right
%
% Note:  The blueLEDFlood is too narrow band, we think!
% We should check that (Zly/BW).
%

thisR.set('light', 'all', 'delete');
% Create a point light at the camera position
whitePoint = piLightCreate('white_point_L',...
    'type', 'point', ...
    'spd spectrum', 'D50',...
    'specscale float', 0.5,...
    'cameracoordinate', true);

thisR.set('light', whitePoint, 'add');

% Move the point closer to the object
thisR.set('light','white_point_L','translate',[1 0 -7]);
thisR.get('light print');

% Put the yellow light in again, separated in x
thisR.set('light',yellowPoint,'add');
thisR.set('light','yellow_point_L','translate',[-1 0 -7]);

piWRS(thisR,'name','Yellow and Blue points');

%% When spd is three numbers, we recognize it is rgb values

distLight = piLightCreate('new_dist_L',...
    'type', 'distant', ...
    'spd', [0.3 0.5 1],...
    'specscale float', 1);
distLight.from.value = thisR.get('from');
distLight.to.value   = thisR.get('to');

thisR.set('light', 'all', 'delete');
thisR.set('light',distLight,'add');

thisR.get('lights print');

piWRS(thisR,'name','Blue (distant)');

%% With the skymap, but intensity scaled

fileName = fullfile(piDirGet('skymaps'),'room.exr');

thisR.set('skymap',fileName);
thisR.set('light','room_L','specscale',0.3);
piWRS(thisR,'name','Dark Environment');

%% Add an environment (skymap) light

thisR.set('light', 'all', 'delete');

thisR.set('skymap',fileName);
tmp = thisR.get('lights','names');
skyName = tmp{1};
piWRS(thisR,'name','Environment original');

%%  Now rotate the skymap around the z dimension.  

% The X Y Z dimensions are annoying to interpret.  We
% need better tools.  Here, we rotate
thisR.set('light', skyName, 'rotation', [10 0  0]);
piWRS(thisR,'name','Environment light rotate X');

%% Put it back
thisR.set('light', skyName, 'rotation', [-10 0 0]);
piWRS(thisR,'name','Environment light rotate Z');

%% Rotate around Z
thisR.set('light', skyName, 'rotation', [0 0 10]);
piWRS(thisR,'name','Environment light rotate Z');

%% END