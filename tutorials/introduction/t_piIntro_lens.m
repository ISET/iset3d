%% Render an image using a lens model
%
% This tutorial shows how to attach an omni camera with a JSON lens file to
% a recipe.  It renders one lens model and prints two other compatible lens
% choices for comparison.
%
% Dependencies:
%    ISET3d-v4, ISETCam
%
% See also
%   piCameraCreate, lensList

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt files

thisR  = piRecipeDefault('scene name','chessSet');
thisR.set('render type',{'radiance','depth'});
thisR.set('skymap','room.exr');

%% Set render quality

thisR.set('film resolution',[180 180]);
thisR.set('rays per pixel',64);

%% Attach one lens model

depthRange = [0.2555 2.7710];  % Chess set distances in meters
lensfile = 'dgauss.22deg.3.0mm.json';
fprintf('Using lens: %s\n',lensfile);

thisR.camera = piCameraCreate('omni','lensFile',lensfile);
thisR.set('focal distance',mean(depthRange));
thisR.set('film diagonal',7.5);
thisR.set('from',[0 0.14 -0.7]);
thisR.set('to',  [0.05 -0.07 0.5]);
thisR.set('aperture diameter',1);
thisR.integrator.subtype = 'path';
thisR.sampler.subtype    = 'sobol';

oi = piWRS(thisR,'name',lensfile,'render flag','hdr');
fprintf('Rendered optical image size: %d x %d\n',oiGet(oi,'rows'),oiGet(oi,'cols'));

%% Other standard lens choices

otherLenses = {'wide.56deg.3.0mm.json','fisheye.87deg.3.0mm.json'};
fprintf('Other compatible lens files:\n');
fprintf('  %s\n',otherLenses{:});

%% END
