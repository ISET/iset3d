function [ieObject, terminalOutput] = render(obj, varargin)
% Render a sceneEye object 
%
% Syntax:
%   [ieObject, terminalOutput] = render(obj, [varargin])
%
% Description:
%	A sceneEye object wraps an iset3d recipe that contains the information 
%   needed to (a) construct a PBRT file, and (b) render it through one of
%   the human physiological optics models.
%
%   This returns a scene when in debugMode or when the camera model is
%   'pinhole' or equivalently 'perspective.
%
%
% Inputs:
%    obj  - sceneEye object. The sceneEye object has an ISET3d recipe to
%           render. 
%
% Optional key/value pairs:
%    render type       - Usual recipe render type cell array 
%    scale Illuminance - Scale the returned oi illuminance (default: true)
%    docker            - isetdocker object. Default: use isetdocker prefs.
%    write - Call piWrite first. Default: true - but for debugging we
%            sometimes suppress the piWrite. 
%            
%
% Outputs:
%    ieObject         - Object. An oi or a scene, depending on the
%                       usePinhole flag
%    terminalOutput   - String. Terminal output.
%
% Description:
%
%   This method renders an iset3d image using physiological optics model.
%   The actions are
%
%    1. Writes out a new PBRT ([renderName].pbrt) in working directory
%    2. Renders using the PBRT spectral docker container
%    3. Loads the output into an ISETBio optical image (unless in
%    debugMode, in which case it is a scene), filling in the parameters
%    with the ISETBio information from the rendering recipe
%
% It returns an oi when there is a lens specified (omni, realisticEye).  If
% the sceneEye pinhole slot is true, it returns a scene.
%
% Dependencies
%   iset3d, ISEBio
%
% See also
%   recipe, piWrite, piRender


%% Parse
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('obj', @(x)(isa(x, 'sceneEye')));
p.addParameter('scaleilluminance', true, @islogical);
p.addParameter('docker',[],@(x)(isempty(x) || isa(x,'isetdocker')));
p.addParameter('dockerwrapper',[],@localIsLegacyDocker);
p.addParameter('write',true,@islogical);

% Some day, check that the cell array has one of these types.
% rTypes = {'radiance','depth','both','all','coordinates','material','mesh', 'illuminant','illuminantonly'};
p.addParameter('rendertype',{'radiance','depth'},@iscell);

p.parse(obj, varargin{:});
renderType        = p.Results.rendertype;
scaleIlluminance  = p.Results.scaleilluminance;
thisDocker = p.Results.docker;
if isempty(thisDocker) && isa(p.Results.dockerwrapper,'isetdocker')
    thisDocker = p.Results.dockerwrapper;
end

%% Get the render recipe

thisR = obj.recipe;

% For debugging, we sometimes switch the camera to pinhole
if obj.usePinhole
    % We render the scene through a pinhole camera.  We try to match
    % the fov for the scene with the fov that was set for the eyeball case.
    fov = thisR.get('fov');
    cameraSave = thisR.get('camera');
    
    thisR.set('camera',piCameraCreate('pinhole'));
    thisR.set('fov',fov);
end

%% Write out into a pbrt file

if p.Results.write
    % For debugging, we sometimes just render.
    piWrite(thisR);
end

%% Render the pbrt file using isetdocker

if isempty(thisDocker)
    [ieObject, terminalOutput] = piRender(thisR,'render type',renderType);
else
    [ieObject, terminalOutput] = piRender(thisR,'render type',renderType,'docker',thisDocker);
end

%% Fix up the returned object

if(~obj.usePinhole)
    % If we are not in debug mode with a pinhole, set OI parameters.
    ieObject = obj.setOI(ieObject, 'scale illuminance', scaleIlluminance);
    % oiWindow(ieObject);
else
    % If debugMode, put back the saved camera information.
    thisR.set('camera',cameraSave);
    % sceneWindow(ieObject);
end

end

function tf = localIsLegacyDocker(value)
%% Accept empty values or current isetdocker values.

tf = isempty(value) || isa(value,'isetdocker');

end
