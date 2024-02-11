%% t_piLightSpectrum
%
% Render the checkerboard scene with two different light spectra
%
% What are the possible spectral we can use?  Let's illustrate in here.  
% There is a way to get fluorescence, but I don't know how.
%
% Blackbody, rgb, and equal energy are illustrated
%
% See also
%   t_piLightType

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file
thisR = piRecipeDefault('scene name','checkerboard');

% Set up the render parameters
piCameraTranslate(thisR,'z shift',2);

% Add one equal energy light
thisR.set('light', 'all', 'delete');

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
spotLgt1 = piLightCreate('spot1',...
                        'type', 'spot',...
                        'spd', 'equalEnergy',...
                        'specscale float', 1,...
                        'coneangle', 20,...
                        'cameracoordinate', true);
thisR.set('light', spotLgt1, 'add');

thisR.get('light print');

% Render
piWRS(thisR,'name','Equal energy (spot)');

%%  Change the spectrum to tungsten

% What are the possible spd values?
thisR.set('lights', 'spot1_L', 'spd', 'tungsten');

piWRS(thisR,'name','Tungsten (spot)');

%% What are the possible spd strings?

thisR.set('lights', 'spot1_L', 'spd', 'D50');

piWRS(thisR,'name','D50 (spot)');

%% Black body - specify just a single color temperature value

thisR.set('lights', 'spot1_L', 'spd', 3000);

piWRS(thisR,'name','3K (spot)');

%% Now overlay two lights

spotLgt2 = piLightCreate('spot2_L',...
                        'type', 'spot',...
                        'spd', 3000,...
                        'specscale float', 1,...
                        'coneangle', 20,...
                        'cameracoordinate', true);
thisR.set('lights',spotLgt2, 'add');

position = thisR.get('lights','spot1_L','world position');
thisR.set('lights','spot1_L','from',position + [3 0 0]);
thisR.set('lights','spot2_L','from',position - [3 0 0]);

thisR.set('lights','spot1_L','spd',8000);

thisR.show('lights');

piWRS(thisR,'name','Mixture (spot)');

%% Adjust spread of the spots

thisR.set('lights','spot1','coneangle',5);
thisR.set('lights','spot2','coneangle',5);
piWRS(thisR,'name','Mixture narrow (spot)');

%% END
