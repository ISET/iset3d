%% t_filmResize
%
% Illustrate the impact of changing the aspect ratio and sampling
% properties of a scene.  We start with manipulating the pinhole camera
% case.  Then move on to omni and finally to human eye.
%
% See also

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Illustrate with chess set and pinhole camera

% The starting configuration.
thisR = piRecipeCreate('chess set');
ss = thisR.get('spatial samples');

% The camera parameters.  10 mm film diag, 320 x 320 samples
thisR.summarize('camera');

piWRS(thisR);

fprintf('FOV %.1f\n',thisR.get('fov'));

%% Look around with a bigger film diagonal for a momoent

% For a pinhole camera, we store the FOV.  We do not store film
% distance
thisR.get('film distance','mm')

thisR.set('fov',10);

thisR.summarize('camera');

piWRS(thisR);

%% Changing the number of samples

% Samples are (X,Y) in PBRT
thisR.set('spatial samples',round([ss(1),ss(2)/2]));

% We change the (x,y) and now the y dimension determines the FOV.  Since we
% halved the number of samples, we halve the FOV to keep the image width
% the same.  Notice the pawns at the left and right are still there.
thisR.set('fov',15);

thisR.summarize('camera');

piWRS(thisR);

%% Enlarge the FOV

thisR.set('spatial samples',ss);

% This is what the image looks like
thisR.set('fov',45)
thisR.summarize('camera');
piWRS(thisR);

%%  An extreme case of generating a line sample for the pinhole

% This is a problem.  I do not understand why we are seeing the whole
% chess set.  We should only be seeing a strip through the chess set.
nRows = 16;
thisR.set('spatial samples',round([ss(1), nRows]));
thisR.set('fov',30/(ss(2)/nRows));

% The short dimension is very small FOV
thisR.summarize('camera');

% The big dimension is the same 30 deg.
thisR.get('fov other')

piWRS(thisR);

%% Now with a camera lens

% Read from the start and add the lens
thisR = piRecipeCreate('chess set');

% Many lens files are named with their FOV and focal length
lensfile  = 'dgauss.22deg.6.0mm.json';    % 

% We replace the pinhole with the lens
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

ss = thisR.get('spatial samples');

thisR.set('focal distance',1); % Meters
thisR.set('film diagonal',4);

thisR.summarize('camera');
piWRS(thisR);

%% Vary the film size 

% If we reduce it, we also reduce the fov
thisR.get('fov')
thisR.set('film diagonal',2);
thisR.get('fov')

%% Focus

% We can choose the focal distance. 
% This changes the film distance to keep the focus.
thisR.set('focal distance',100);  % Meters
thisR.get('film distance','mm')

% Close distance
thisR.set('focal distance',0.2); % Meters
thisR.get('film distance','mm')

thisR.set('focal distance',1); % Meters
thisR.get('film distance','mm')

%% The camera model uses the diagonal FOV

% Initialize the scene with a lens
thisR = piRecipeCreate('chess set');

% Many lens files are named with their FOV and focal length
lensfile  = 'dgauss.22deg.6.0mm.json';    % 
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
thisR.set('film diagonal',3);

% Render the original and plot a horizontal illuminance line
oi1 = piWRS(thisR);
oi1 = piAIdenoise(oi1);
sz = oiGet(oi1,'size');
uData1 = oiPlot(oi1,'illuminance hline',[1,sz(1)/2]);

% Change the number of samples
% We change the diagonal film size to keep the FOV the same.
ss = thisR.get('spatial samples');
fSize = thisR.get('film size','mm');
x = fSize(1); y = fSize(2);
k = [1, 0.1];
newFD = sqrt((k(1)*x)^2 + (k(2)*y)^2);

% Make the adjustment.  Probably the newFD should always be in
% 'spatial samples' set
thisR.set('spatial samples',k.*ss);
thisR.set('film diagonal',newFD);
oi2 = piWRS(thisR);
oi2 = piAIdenoise(oi2);
sz = oiGet(oi2,'size');
uData2 = oiPlot(oi2,'illuminance hline',[1,sz(1)/2]);

%% Now compare
ieNewGraphWin([],'wide');
subplot(1,2,1)
plot(uData1.pos,uData1.data,'b--',uData2.pos,uData2.data,'r-');
subplot(1,2,2)
plot(uData1.data,uData2.data,'o'); identityLine; grid on;


%% Put it back
thisR.set('spatial samples',ss);
thisR.get('fov')

%% Human eye version
thisSE = sceneEye('chessset','eye model',modelName{mm});
thisSE.set('use pinhole',true);
thisSE.piWRS;

humanD = dockerWrapper.humanEyeDocker;
thisSE.set('use pinhole',false);
thisSE.piWRS('docker wrapper',humanD);

thisSE.get('fov')
thisSE.set('fov',22);
thisSE.piWRS('docker wrapper',humanD);

ss = thisSE.get('spatial samples');
thisSE.set('spatial samples',2*ss);
thisSE.piWRS('docker wrapper',humanD);

oi = ieGetObject('oi'); 
oi = piAIdenoise(oi); ieReplaceObject(oi); 
oiWindow;

thisSE.set('spatial samples',ss);
thisSE.set('render type',{'radiance','depth'});
thisSE.piWRS('docker wrapper',humanD);
oi = ieGetObject('oi'); 
oi = piAIdenoise(oi); ieReplaceObject(oi); 
oiWindow;


%% 

thisSE.set('semidiam')

%% Adjust accommodation

thisSE.set('pupil diameter',3);
thisSE.set('spatial samples',2*ss);
aa =[1/.3, 1/.5, 1, 1/2];
for ii = 1:numel(aa)
    thisSE.set('accommodation',aa(ii));
    name = sprintf('Acc %.1f',aa(ii));
    thisSE.piWRS('docker wrapper',humanD,'name',name);
    oi = ieGetObject('oi');
    oi = piAIdenoise(oi); ieReplaceObject(oi);
    oiWindow;
end

%% END


