%% Explore light creation with the area light parameters
%
%
% See also
%   t_arealight.m, t_piIntro_light

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create a proper default for piLightCreate
thisR = piRecipeCreate('arealight');
thisR.show('lights');
piWRS(thisR,'render flag','hdr','name','original arealight');

%%
%{
% These are the original lights
 thisR.set('light','AreaLightRectangle_L','delete');
 thisR.set('light','AreaLightRectangle.001_L','delete');
 thisR.set('light','AreaLightRectangle.002_L','delete');
 thisR.set('light','AreaLightRectangle.003_L','delete');
%}

%%  Put in a white light of our own.

thisR.set('lights','all','delete');
wLight    = piLightCreate('white','type','area');
thisR.set('light',wLight,'add');
thisR.set('asset',wLight.name,'world rotation',[-90 0 0]);
piWRS(thisR,'render flag','hdr','name','single white light');

%% Load the Macbeth scene. 

thisR =  piRecipeCreate('MacBethChecker');
piWRS(thisR,'render flag','rgb','name','original MCC');

%% Clear the initial light and put in a new area light

thisR.set('lights','all','delete');

% Move away so we can see the light shape.
thisR.set('object distance',6);

% The default area light.  Hopefully it is pointing in the proper
% direction!  That depends on the shape
wLight    = piLightCreate('white','type','area');
thisR.set('light',wLight,'add');

% Can we rotate the light to illuminate by different amounts?
thisR.set('light',wLight.name,'world rotation',[-110 0 0]);
thisR.set('light',wLight.name,'translate',[0 1.5 -0.5]);
thisR.get('light',wLight.name,'world position')

% When you reduce the spread, the total amount of light stays the same
% Local regions actually get brighter.  But the fall off at the
% edges is higher.
thisR.set('light',wLight.name,'spread',45);
piWRS(thisR,'render flag','rgb');

%%
thisR.set('light',wLight.name,'twosided',true);
piWRS(thisR,'render flag','rgb');

%%
thisR.set('skymap','room.exr');
piWRS(thisR,'render flag','rgb');

%% Add a top down area light

thisR =  piRecipeDefault('scene name','ChessSet');

thisR.set('lights','all','delete');

wLight    = piLightCreate('light1','type','area');
thisR.set('light',wLight,'add');
thisR.set('light',wLight.name,'world rotation',[-90 0 0]);
thisR.set('light',wLight.name,'translate',[1 2 0]);
thisR.set('light',wLight.name,'spread',30);
thisR.set('light',wLight.name,'spd',[32 32 255]);
% thisR.get('light',wLight.name,'world position')

wLight    = piLightCreate('light2','type','area');
lName = wLight.name;
thisR.set('light',wLight,'add');
thisR.set('light',lName,'world rotation',[-90 0 0]);
thisR.set('light',lName,'translate',[-1 2 0]);
thisR.set('light',lName,'spread',10);
thisR.set('light',lName,'spd',[255 255 0]);

% thisR.show('lights');

scene = piWRS(thisR,'render flag','rgb');
ieReplaceObject(piAIdenoise(scene));
sceneWindow;

%% Contrast with the effect of adding a spot light

thisR =  piRecipeDefault('scene name','ChessSet');
thisR.set('lights','all','delete');

lightName = 'new_spot_light_L';
newLight = piLightCreate(lightName,...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 1, ...
                        'coneangle', 15,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);
thisR.set('light', newLight, 'add');

% piAssetGeometry(thisR);

piWRS(thisR,'gamma',0.7);

%% END

