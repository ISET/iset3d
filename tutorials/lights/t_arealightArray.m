%% t_arealightArray.m
%
% Exposes the code used in oeLights and cubeLights for how to create
% an array of area lights
%
%  * Create a triangular array of area lights
%  * Move the surface closer to the lights to see them
%  * Create a circular array of lights
%
% See also
%  t_arealight*
%  oraleye:  oeLights, cubeLights


%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Simple flat surface for the scene

% The recipe has no light
thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);

% The flat surface object is called Cube.  It is 1m in size.  I shrink it
% so we can also see the environment light, later.
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'scale',0.25);   

% Add some surface textures.  For now make the surface white.
piMaterialsInsert(thisR,'names',{'mirror','diffuse-white','marble-beige','wood-mahogany'});
thisR.set('asset',cubeID,'material name', 'diffuse-white');

%% The three area lights
area = cell(1,3);

% Triangular positions, a few millimeters off to the side of the
% camera
pos = [0.005 0 0; 
       0.100 0 0; 
       0.05 0.050 0];

% Create and set the light parameters.  The default area light is 1m
% on a side, which is very big.  We make it smaller here.
for ii=1:3
    area{ii} = piLightCreate(sprintf('area-%d',ii),...
        'type','area',...
        'spd spectrum','D65.mat');
    thisR.set('light',area{ii},'add');
    thisR.set('light',area{ii},'translate',pos(ii,:));
    thisR.set('light',area{ii},'shape scale',0.005);   % 5 mm size
    thisR.set('light',area{ii},'rotate',[0 180 0]);    % Don't ask
    thisR.set('light',area{ii},'spread',5);            % 
    thisR.set('light',area{ii},'specscale',100);       % Brighten it
end

% Add an ambient light so we can see the surface where this light does
% NOT shine.
thisR.set('skymap','room.exr');
thisR.set('light','room_L','rotate',[0 180 0]);    % Don't ask

piWRS(thisR,'name','3 lights-distant surface');

%% Move the cube closer to the camera

% This makes it easier to see the three light sources
thisR.set('asset',cubeID,'translate',[0 0 -0.5]);
piWRS(thisR,'name','closer surface');

%% Get rid of the skymap

thisR.set('light','room_L','delete');
piWRS(thisR,'name','closer surface no skymap');

%% Create a ring of light sources

% Delete the triangular array and skymap
thisR.set('lights','all','delete');

% Add back the ambient light so we can see the surface where this
% light does NOT shine.
thisR.set('skymap','room.exr');
thisR.set('light','room_L','rotate',[0 180 0]);    % Don't ask

% Make ring of lights.  They will be in a circle around the camera.
% The camera is pointed in this direction.
direction = thisR.get('fromto');
radius = 0.035; % Meters
nLights = 8;

% Creates a set of positions around the camera in the from-to
% direction.
pos = piRotateFrom(thisR, direction, ...
    'n samples',nLights+1, ...
    'radius',radius,...
    'show',false);

for ii=1:nLights
    area{ii} = piLightCreate(sprintf('area-%d',ii),...
        'type','area',...
        'spd spectrum','D65.mat', ...
        'spread',5, ...
        'specscale',100);
    thisR.set('light',area{ii},'add');
    thisR.set('light',area{ii},'translate',pos(:,ii));
    thisR.set('light',area{ii},'shape scale',0.005);   % 5 mm size
    thisR.set('light',area{ii},'rotate',[0 180 0]);    % Don't ask
end
thisR.show('lights');

piWRS(thisR,'name','ring light');

%%  Sweep out some distances by moving the surface

thisR.set('asset',cubeID,'translate',[0 0 -0.1]);

scene = piWRS(thisR,'name','ring light');

%% END