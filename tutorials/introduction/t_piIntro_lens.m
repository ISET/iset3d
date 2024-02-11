%% Render an image using a lens model
%
% We illustrate three different lens models with the Chess Set scene.
% These optics models are standard 3mm choices with a 7.5mm film
% (sensor) diagonal.
%
% Dependencies:
%    ISET3d-v4, ISETCam, isetlens
%
% See also
%   t_piIntro_start, isetlens,
%

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt files

% This is the PBRT scene file inside the output directory
% thisR  = piRecipeDefault();
thisR  = piRecipeDefault('scene name','chessSet');

thisR.set('render type',{'radiance','depth'});
thisR.set('skymap','room.exr');

%% Set render quality

% Set resolution for speed or quality.
thisR.set('film resolution',round([600 600]));   % 2 is high res. 0.25 for speed
thisR.set('rays per pixel',512);                 % 1024 for high quality

%% To determine the range of object depths in the scene

%{
% Run this function
depthRange = thisR.get('depth range');

% Which just calls this:
%
% [depthRange, depthHist] = piSceneDepth(thisR);
% histogram(depthHist(:)); xlabel('Depth (m)'); grid on
%
%}
depthRange = [0.2555    2.7710];  % Chess set distances in meters

%% Add camera with lens

% To see all possible lenses use
%   lensFiles = lensList;
%
theLenses = {'dgauss.22deg.3.0mm.json','wide.56deg.3.0mm.json','fisheye.87deg.3.0mm.json'};
% theLenses = {'dgauss.22deg.50.0mm.json','wide.56deg.50.0mm.json','fisheye.87deg.50.0mm.json'};
for ll=1:numel(theLenses)

    lensfile = theLenses{ll};    
    fprintf('Using lens: %s\n',lensfile);
    thisR.camera = piCameraCreate('omni','lensFile',lensfile);

    % Set the focus into the middle of the depth range of the objects in the
    % scene.
    %{
     d = lensFocus(lensfile,max(depthRange*1000));   % Millimeters
     thisR.set('film distance',d);
    %}
    thisR.set('focal distance',mean(depthRange));

    % The FOV is not used for the 'omni' camera.
    % The FOV is determined by the lens.

    % This is the size of the film/sensor in millimeters (default 22)
    % From the field of view and the focal length we should be able to
    % calculate the proper size of the film.
    thisR.set('film diagonal',7.5);

    % Pick out a bit of the image to look at.  Middle dimension is up.
    % Third dimension is z.  I picked a from/to that put the ruler in the
    % middle.  The in focus is about the pawn or rook.
    thisR.set('from',[0 0.14 -0.7]);     % Get higher and back away than default
    thisR.set('to',  [0.05 -0.07 0.5]);  % Look down default compared to default

    % We can use bdpt if you are using the docker with the "test" tag (see
    % header). Otherwise you must use 'path'
    thisR.integrator.subtype = 'path';
    thisR.sampler.subtype    = 'sobol';

    % Increases the depth of field
    thisR.set('aperture diameter',1);   % thisR.summarize('all');

    % Render and display
    sName = sprintf('%s',lensfile);
    oi = piWRS(thisR,'name',sName,'render flag','hdr');

end

%% Images noisy?  You can clean them using piAIdenoise.
%
%  That function requires downloading the Intel denoiser and having
%  the executable on your path.  Read the documentation at:
%
%    doc piAIdenoise
%  
%{
for ll=1:numel(theLenses)
    oi = ieGetObject('oi',ll);
    oi = piAIdenoise(oi);
    ieReplaceObject(oi,ll);
    oiWindow;
end
%}

%% END
