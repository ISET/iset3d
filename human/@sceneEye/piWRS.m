function obj = piWRS(SE,varargin)
% Calls the main piWRS function, but accounting for sceneEye
% parameters
%
% Synopsis
%   obj = sceneEye.piWRS(varargin);
%
% Brief
%   Writes, Renders, and Shows the sceneEye recipe.  The typical piWRS
%   parameters are passed through. The special case of accounting for
%   the pinhole testing case and scaling the illuminance case are
%   managed here.  But everything else is passed to the piWRS function
%   in ISET3d-v4.
%
%   The Docker implementation does NOT include multiplication by the
%   lens transmission.  The lens density is stored in the slot
%   sceneEye.lensDensity.  Upon return of the optical image, we create
%   the lens transmission for that lens density and apply it to the
%   OI.
%
% Inputs
%   SE - sceneEye object
%
% Key/val pairs
%    render type      - Usual recipe render type cell array 
%    scaleIlluminance - Scale the returned illuminance with respect to
%                       the pupil area. Default true. 
%    write - Call piWrite first. Default: true 
%            For debugging we sometimes suppress piWrite. 
%    docker - Specify an isetdocker object. Pinhole scene previews use the
%       configured/default renderer. Human-eye optics renders force a CPU
%       PBRT image because the human-eye model is not GPU-enabled.
%   'name'  - Set the Scene or OI name
%   'gamma' - Set the display gamma for the window
%   'show'  - Default: true
%
% Outputs
%   obj - Returns the ISETBio/Cam scene or oi struct
%
% See also
%   sceneEye.render, sceneEye.write
%

%% Parse
varargin = ieParamFormat(varargin);

p = inputParser;
p.KeepUnmatched = true;
p.addRequired('SE', @(x)(isa(x, 'sceneEye')));
p.addParameter('scaleilluminance', true, @islogical);
p.addParameter('docker',[],@localIsDockerLike);
p.addParameter('dockerwrapper',[],@localIsDockerLike);
p.addParameter('show',true,@islogical);

p.parse(SE, varargin{:});
scaleIlluminance  = p.Results.scaleilluminance;
show = p.Results.show;

thisDocker = p.Results.docker;
if isempty(thisDocker) && ~isempty(p.Results.dockerwrapper)
    thisDocker = p.Results.dockerwrapper;
end
thisDocker = localSceneEyeDocker(SE,thisDocker);
renderArgs = localRenderArgsWithDocker(varargin,thisDocker);

thisR = SE.recipe;

% For ISETBio debugging, we sometimes switch the camera to pinhole
if SE.usePinhole
    % We will render a scene through a pinhole camera.  We try to match the
    % fov for the scene with the fov that was set for the eyeballc ase.
    fov = thisR.get('fov');
    cameraSave = thisR.get('camera');
    
    thisR.set('camera',piCameraCreate('pinhole'));
    thisR.set('fov',fov);
    restoreCamera = onCleanup(@() thisR.set('camera', cameraSave));
end

% We write and render but do not show at this point.   We need to apply the
% oi settings before showing.

% Write the local/pbrt directory being aware about whether the resources
% are expected to be present remotely.
piWrite(thisR);
obj = piRender(thisR,renderArgs{:});

% Deal with special ISETBio pinhole management
if(~SE.usePinhole)
    % If we are not in pinhole (debug) mode, set the OI parameters.
    % This includes applying the lens transmittance.
    obj = SE.setOI(obj, 'scale illuminance', scaleIlluminance);    
else
    % If in pinhole (debug) mode, copy back the saved camera
    % information that was stored above.
    thisR.set('camera',cameraSave);    
end

% Ready to show.
if show
    switch obj.type
        case 'opticalimage'
            oiWindow(obj);
        case 'scene'
            sceneWindow(obj);
    end
end

end

function tf = localIsDockerLike(value)
%% Accept empty values or current isetdocker objects.

tf = isempty(value) || isa(value,'isetdocker');

end

function thisDocker = localSceneEyeDocker(SE,thisDocker)
%% Use CPU PBRT for human-eye optics, preserving default renderer for pinhole.

if SE.usePinhole
    return;
end

if ~isempty(thisDocker) && strcmpi(thisDocker.device,'cpu')
    thisDocker = localEnsureHumanEyeCPUImage(thisDocker);
    return;
end

thisDocker = localHumanEyeDocker(thisDocker);

end

function thisDocker = localHumanEyeDocker(templateDocker)
%% Create a CPU isetdocker for human-eye PBRT renders.

if isempty(templateDocker)
    thisDocker = isetdocker('verbosity',0);
else
    thisDocker = isetdocker('verbosity',templateDocker.verbosity,'validate',false);
    thisDocker.label = templateDocker.label;
    thisDocker.remoteHost = templateDocker.remoteHost;
    thisDocker.remoteUser = templateDocker.remoteUser;
    thisDocker.workDir = templateDocker.workDir;
    thisDocker.renderContext = templateDocker.renderContext;
end

thisDocker.device = 'cpu';
thisDocker.deviceID = '';
thisDocker = localEnsureHumanEyeCPUImage(thisDocker);

end

function thisDocker = localEnsureHumanEyeCPUImage(thisDocker)
%% Ensure human-eye optics do not accidentally use a GPU PBRT image.

thisDocker.device = 'cpu';
thisDocker.deviceID = '';
if isempty(thisDocker.dockerImage) || contains(lower(thisDocker.dockerImage),'gpu')
    thisDocker.dockerImage = 'digitalprodev/pbrt-v4-cpu';
end
localResetSavedGPUContainer(thisDocker);

end

function localResetSavedGPUContainer(thisDocker)
%% Avoid a device-mismatch warning when human-eye optics switch to CPU PBRT.

if ~ispref('ISETDocker','PBRTContainer') || ~ismethod(thisDocker,'reset')
    return;
end

containerName = char(string(getpref('ISETDocker','PBRTContainer')));
if startsWith(containerName,'pbrt-gpu-')
    thisDocker.reset();
end

end

function renderArgs = localRenderArgsWithDocker(args,thisDocker)
%% Remove legacy docker keys and append the selected isetdocker object.

renderArgs = {};
ii = 1;
while ii <= numel(args)
    if (ischar(args{ii}) || isstring(args{ii})) && ...
            ismember(ieParamFormat(args{ii}),{'docker','dockerwrapper'})
        ii = ii + 2;
    else
        renderArgs = [renderArgs args(ii:min(ii+1,numel(args)))]; %#ok<AGROW>
        ii = ii + 2;
    end
end

if ~isempty(thisDocker)
    renderArgs = [renderArgs {'docker',thisDocker}];
end

end
