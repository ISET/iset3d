%% t_arealightArray.m
%
%  * Create an array of area lights
%  * Move the camera so that we are looking back at the array
%    directly.
%
% See also
%  t_arealight*


%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Simple flat surface for the scene

% The recipe has no light
thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);

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
    thisR.set('light',area{ii},'shape scale',0.005);   % 50 mm size
    thisR.set('light',area{ii},'rotate',[0 180 0]);    % Don't ask
    thisR.set('light',area{ii},'spread',5);            % 
    thisR.set('light',area{ii},'specscale',1);       % Brighten it
end

% Add an ambient light so we can see the surface where this light does
% NOT shine.
skyName = 'sky-room';
thisR.set('skymap',skyName);
thisR.set('light',skyName,'rotate',[0 180 0]);    % Don't ask

%%
piWRS(thisR,'name','3 lights-distant surface');

%% Move the cube closer to the camera

% The flat surface object is called Cube.  It is 1m in size.  I shrink it
% so we can also see the environment light, later.
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'delete');   

lookat = thisR.get('lookat');
thisR.set('from',lookat.to);
thisR.set('to',lookat.from);
piWRS(thisR,'name','Look at the camera');

%% Create a ring of light sources

thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);

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
        'spd spectrum','Velscope.mat', ...
        'spread',5, ...
        'specscale',100);
    thisR.set('light',area{ii},'add');
    thisR.set('light',area{ii},'translate',pos(:,ii));
    thisR.set('light',area{ii},'shape scale',0.005);   % 5 mm size
    thisR.set('light',area{ii},'rotate',[0 180 0]);    % Don't ask
end
thisR.show('lights');

piWRS(thisR,'name','ring light','render flag','hdr');

%%  Sweep out some distances by moving the surface


% The flat surface object is called Cube.  It is 1m in size.  I shrink it
% so we can also see the environment light, later.
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'delete');   

lookat = thisR.get('lookat');
thisR.set('from',lookat.to);
thisR.set('to',lookat.from);

thisR.set('spatial samples',[1280 1280]);

piWRS(thisR,'name','Look at the camera','render flag','hdr');

%% END