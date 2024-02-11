%% t_arealightLookat.m
%
% Look at the light directly.
% Also, rotate the light and translate it and scale its size.
%
% See also
%  t_arealight*

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Simple flat surface for the scene

thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);

% Make an area light that covers the whole surface

% The light position is (0,0,0), which happens to be the camera position
area1 = piLightCreate('area1',...
    'type','area',...
    'spd spectrum','D50', ...
    'spread',30);
thisR.set('lights',area1,'add');
thisR.set('light','area1','rotate',[0 180 0]);

thisR.set('skymap','room.exr');
% thisR.show('lights');

% Rotate the light so it is pointing at the surface

% The light is very big and it spreads. 
piWRS(thisR);

%% Turn around and look at the light

% Delete the object to get it out of the way
cubeID = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset',cubeID,'delete');

% Reverse lookat and to
lookat = thisR.get('lookat');
thisR.set('from',lookat.to);
thisR.set( 'to',lookat.from);

% See the light, but we also see the environment light through the big
% light.  Hmm.
piWRS(thisR);

%% Shrink the size of the light
thisR.set('light','area1','shape scale',0.1);   
piWRS(thisR);

%%  Rotate the light - it is not two sided
for ii=1:4
    thisR.set('light','area1','rotate',[0 45 0]);
    piWRS(thisR);
end

%% Make the light two sided
thisR.set('light','area1','twosided',true);
piWRS(thisR);

%%  Translate the light
thisR.set('light','area1','translate',[0.1 0.1 0]);
piWRS(thisR);

%% END