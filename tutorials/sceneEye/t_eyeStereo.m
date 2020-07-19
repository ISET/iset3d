%% t_eyeStereo
%
% Please read t_eyeIntro first.
%
% Create a stereo pair of retinal irradiance images.
%
% See also
%

%%
ieInit

%% Make an oi of the chess set scene using the LeGrand eye model

thisSE = sceneEye('chess set scaled','human eye','legrand');

thisSE.set('lens density',0);   % Just because I can

thisSE.set('rays per pixel',512);  % Pretty quick, but not high quality

oiLeft = thisSE.render;  % Render and show
oiWindow(oiLeft);

%% Shift the eye position

% Change the eye position (from) but stay focused on the same object (to).
% I shifted the eye position by a lot (12 mm) so the image difference is be
% easy to see.  The inter-pupil difference is really only 6-8 mm 

from = thisSE.get('from');   % Current camera location

thisSE.set('from',from + [0.012,0,0]);  % Shift it 12 mm

oiRight = thisSE.render;
oiWindow(oiRight);

%% END

