%% Illustrate creating a goniometric light
%
% TODO:  Create exr files with localized patches so we understand the
% geometry. 
%
% LightSource "goniometric" "spectrum I" "spds/lights/equalenergy.spd"  "string filename" "pngExample.exr" "float scale" [1.00000]

%% init
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe
%
% The MCC image is the default recipe.  We do not write it out yet because
% we are going to change the parameters
thisR = piRecipeCreate('macbeth checker');

%% Example of a Goniometric light

% There is a default point light.  We delete that.
thisR = thisR.set('lights','all','delete');

% This is always gray scale
spectrumScale = 1000;
% gonioMap = 'clouds-sky.exr';   % Include the extension
gonioMap = 'sky-blue-sun.exr';   % Include the extension
% gonioMap = 'gonio-room.exr'; 

lightSpectrum = 'equalEnergy';
% lightSpectrum = 'D65';

newGoniometric = piLightCreate('gonio',...
                           'type', 'goniometric',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'cameracoordinate', true, ...
                           'filename', gonioMap);
thisR.set('light', newGoniometric, 'add');

% Not working - unclear why.
piWRS(thisR,'render flag','hdr','name','gonio');

%% Add a skymap

thisR.set('skymap','sky-room.exr');

thisR.show('lights');
% thisR.set('lights','room_L','delete');

piWRS(thisR,'render flag','hdr','name','gonoi and skymap');

%% Can we move the gonio light position?

thisR.set('light',newGoniometric.name,'translate',[-1 -1 0]);
thisR.show('lights');
% Create a viewer for the goniometric image
%{
img = exrread(newGoniometric.filename.value);
imtool(img);
%}
piWRS(thisR,'render flag','hdr','name','gonoi shifted');

%% Remove the goniometric light

thisR.set('light',newGoniometric.name,'delete');
thisR.set('light',newGoniometric, 'add');
thisR.set('light',newGoniometric.name,'translate',[0 1 0]);

thisR.show('lights');
piWRS(thisR,'render flag','hdr','name','gonoi shifted');

%% Add a distant light and put back the gonio light

spectrumScale = 1;
lightSpectrum = 'equalEnergy';
newDistant = piLightCreate('distant',...
                           'type', 'distant',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'cameracoordinate', true);
thisR.set('light', newDistant, 'add');
thisR.set('light', newGoniometric, 'add');

piWRS(thisR,'mean luminance',-1,'render flag','hdr','name','distant, skymap, gonio');

%% Trying different goniometric

thisR = piRecipeDefault('scene name','bunny');

thisR.set('skymap','room.exr');
bunnyIDX = piAssetSearch(thisR,'object','Bunny');
thisR.set('asset',bunnyIDX,'scale',4);
thisR.set('nbounces',3);

piMaterialsInsert(thisR,'names','glossy-red');
thisR.set('asset',bunnyIDX,'material name','glossy-red');

thisR = thisR.set('lights','all','delete');

spectrumScale = 1;
% gonioMap = 'gonio-brightsky.exr'; % Include the extension
% gonioMap = 'sky-blue-sun.exr';
% gonioMap = 'gonio-room.exr';
% gonioMap = 'gonio-thicklines.png';
gonioMap = 'gonio-ringsrays-64.exr';

%{
scene = sceneCreate('rings rays',64,512);
rgb = sceneGet(scene,'rgb');
imtool(rgb)
exrwrite(rgb,'gonio-ringsrays-64.exr');
%}

lightSpectrum = 'equalEnergy';
newGoniometric = piLightCreate('gonio',...
                           'type', 'goniometric',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'cameracoordinate', true, ...
                           'filename', gonioMap);
thisR.set('light', newGoniometric, 'add');

piWRS(thisR,'mean luminance',-1,'name','only gonio','render flag','rgb');

%%
piWRS(thisR,'mean luminance',-1,'name','gonio sky','render flag','hdr');

originalTo = thisR.get('to');
originalDist = thisR.get('object distance');
thisR.set('skymap','sky-room.exr');

%%

thisR.set('to',originalTo + [0 -.15 0]);
thisR.set('object distance',originalDist*1.25);

piWRS(thisR,'mean luminance',-1,'name','gonio sky','render flag','hdr');

%% END