function camera = piCameraCreate(cameraType,varargin)
% Create a camera structure to be placed in a ISET3d recipe
%
% Synopsis
%   camera = piCameraCreate(cameraType, lensFile, ..)
%
% Input parameters
%
%   cameraType:
%
%    'pinhole'      - Default is pinhole camera, also called 'perspective'
%    'omni'         - Standard lens, including potential microlens array
%    'ray transfer' - Ray transfer function for the optics simulation
%    'human eye'    - For calculating with different physiological
%                     optics models (navarro, arizona, legrand)
%
%
% For example,
%   lensname = 'dgauss.22deg.12.5mm.json';
%   c = piCameraCreate('omni','lens file',lensname);
%
% Optional parameter/values
%
% Output
%   camera - Camera structure for placement in a recipe
%
% Deprecated key/val options
%
%    'light field' - microlens array in front of the sensor for a light
%                    field camera
%    'realisticDiffraction' - Not sure what that sub type is doing in
%                                  light field
%    'realistic'   - This seems to be superseded completely by omni, except
%                    for some old car scene generation cases that have not
%                    been updated.
%
% TL,BW SCIEN STANFORD 2017
%
% See also
%    recipe

% Examples:
%{
c = piCameraCreate('pinhole');
%}
%{
lensname = 'dgauss.22deg.12.5mm.dat';
c = piCameraCreate('omni');
%}
%{
c = piCameraCreate('lightfield');
%}
%{
lensname = 'dgauss.22deg.12.5mm.json';
c = piCameraCreate('omni','lens file',lensname);
%}
%{
lensname = 'navarro.dat';
c = piCameraCreate('human eye','lens file',lensname);
%}
%{
lensname = 'legrand.dat';
c = piCameraCreate('human eye','lens file',lensname);
%}
%{
c = piCameraCreate('ray transfer','lens file','tmp.json')
%}

% PROGRAMMING
%   TODO: Implement things key/val options for the camera type values
%           piCameraCreate('pinhole','fov',val);
%

%% Check input
varargin = ieParamFormat(varargin);

p = inputParser;
% pinhole and perspective are synonyms
% omni is the most general type in current use
% realistic should be replaced by omni in the future.  Not sure what we are
% waiting for, but there is some feature ... (BW)
validCameraTypes = {'pinhole','perspective','realistic','omni', 'humaneye','lightfield','raytransfer'};
p.addRequired('cameraType',@(x)(ismember(ieParamFormat(x),validCameraTypes)));

% This will work for realistic, but not omni.  Perhaps we should make the
% default depend on the camera type.
switch ieParamFormat(cameraType)
    % Omni and realistic have lenses.  We are using this default lens.
    case 'omni'
        lensDefault = 'dgauss.22deg.12.5mm.json';
    case 'realistic'
        lensDefault = 'dgauss.22deg.12.5mm.dat';
    case 'raytransfer'
        % This is the json file for a default RTF when we have one
        lensDefault = 'dgauss-22deg-3.0mm.json';
    otherwise
        lensDefault = '';
end
p.addParameter('eyemodel','navarro',@(x)ismember(x,{'navarro','arizona','legrand'}));
p.addParameter('lensfile',lensDefault, @ischar);

p.parse(cameraType,varargin{:});

% Use pinhole instead of perspective, for clarity.
if isequal(cameraType,'perspective'), cameraType = 'pinhole'; end

lensFile = p.Results.lensfile;
eyeModel = p.Results.eyemodel;

%% Initialize the default camera type
switch ieParamFormat(cameraType)
    case {'pinhole'}
        % A pinhole camera is also called 'perspective'.  I am trying to
        % get rid of that terminology in the code (BW).
        camera.type      = 'Camera';
        camera.subtype   = 'perspective';
        camera.fov.type  = 'float';
        camera.fov.value = 45;         % angle in deg
        camera.lensradius.type = 'float';
        camera.lensradius.value = 0;   % Radius in mm???

    case {'realistic'}
        % Check for lens .dat file
        warning('realistic will be deprecated for omni');
        [~,~,e] = fileparts(lensFile);
        if(~strcmp(e,'.dat'))
            % Sometimes we are sent in the json file
            warning('Realistic camera needs *.dat lens file. Checking.');
            [p,n,~] = fileparts(lensFile);
            lensFile = fullfile(p,[n '.dat']);
            if ~exist(fullfile(p,[n '.dat']),'file')
                error('No corresponding dat file found');
            else
                fprintf('Found %s\n',lensFile);
            end
        end

        camera.type          = 'Camera';
        camera.subtype       = 'omni';
        camera.lensfile.type = 'string';
        camera.lensfile.value = which(lensFile);
        camera.aperturediameter.type  = 'float';
        camera.aperturediameter.value = 5;    % mm
        camera.focusdistance.type     = 'float';
        camera.focusdistance.value    = 10; % mm

    case {'omni'}
        [~,name,e] = fileparts(lensFile);
        if(~strcmp(e,'.json'))
            error('Omni camera needs *.json lens file.');
        end

        camera.type = 'Camera';
        camera.subtype = 'omni';
        camera.lensfile.type = 'string';
        
        % If a full path of the lensFile is not specified, the
        % lensFile should be in the isetcam/data/lens directory. This
        % is new July 30, 2022.  This change may not account for every
        % case, and I am particularly concerned about the human lens
        % case and now the microlens case.  In the microlens case, we
        % build the combined lens file in the output directory. (BW)
        % 
        if isfile(lensFile)
            % Full path was specified.  Use it.
            camera.lensfile.value = lensFile;
        else
            % Partial path ways specified.  So, use the filename and
            % assume it is in the default location (isecam/data/lens).
            lensFile = fullfile(isetRootPath,'data','lens',[name, '.json']);
            if isfile(lensFile)
                camera.lensfile.value = fullfile(isetRootPath,'data','lens',[name, '.json']);
            else
                error('Lens file is not found: %s.\n',lensFile);
            end
        end
        
        % Why are we setting these values here?  We should fix.
        % TODO:  Change this.
        camera.aperturediameter.type = 'float';
        camera.aperturediameter.value = 5;    % mm
        camera.focusdistance.type = 'float';
        camera.focusdistance.value = 10; % mm
    case {'raytransfer'}
        % Ray Transfer polynomials are in the json file specified by
        % rtfModel.  We need to add some specifications of the lens
        % properties into the JSON file for convenience.  When we get the
        % parameters using recipeGet, we will read the JSON file.
        camera.type           = 'Camera';
        camera.subtype        = 'raytransfer';
        camera.filmdistance.type ='float';
        camera.filmdistance.value=0.002167;
        camera.lensfile.type  = 'string';
        [~,name,~] = fileparts(lensFile);
        % check if lensFile exist.  This may fail.  To check with RTF
        % calculations (BW, Augu 2 2022).
        if isempty(which(lensFile))
            % The lensFile is not included in iset3d lens folder.
            % So we move the file into the lens folder.
            copyfile(lensFile, fullfile(piRootPath,'data/lens'));
            camera.lensfile.value = [name, '.json'];
        else
            % lensFile in matlab path
            camera.lensfile.value = which(lensFile);
        end

        %camera.lensfile.value = lensDefault;  % JSON Polynomial ray transfer model
    case {'lightfield'}
        % This may no longer be used.  The 'omni' type incorporates the
        % light field microlens method and is more modern.
        error('Use ''omni'' and add a microlens array');
    case {'humaneye'}
        % Human eye model used with sceneEye calculations in ISETBio. The
        % subtype 'realisticEye' is historical.  We allow it for PBRT,
        % though human eye is now preferred.
        %
        % piCameraCreate('humaneye',

        if piCamBio
            % Merge of isetbio/isetcam makes this unnecessary
            % warning('human eye camera type is for use with ISETBio')
        end
        camera.type           = 'Camera';
        camera.subtype        = 'humaneye';
        
        % The lens file should be created by calling the appropriate lens
        % model.  The default might be navarroLensCreate(0).
        camera.lensfile.type  = 'string';
        switch eyeModel
            case 'navarro'
                camera.lensfile.value = lensFile;
            case 'arizona'
                camera.lensfile.value = lensFile;
            case 'legrand'
                camera.lensfile.value = lensFile;
            otherwise
                error('Unknown eye model %s\n',eyemodel);
        end

        
        % There is a PowerPoint in the wiki (iset3d) images that explains
        % the parameters: EyeballGeometry.pptx.
        
        % The retina distance and retina radius are the same for all the
        % human eye models. The models differ in the parameters about the
        % lens and cornea, which are written out in the lens file.

        % The distance from the back of the lens to the retina is the
        % retinaDistance.  We initialize at a distance estimated using
        % the script t_eyeRetinaDistance. We place an edge at 10 m
        % from the eye and adjust the distance so that the slanted
        % edge chromatic fringe is as expected.  Hence, the default
        % accommodation = 0 (distance is Inf).
        camera.retinaDistance.type = 'float';
        switch eyeModel
            case 'navarro'
                camera.retinaDistance.value = 16.37;
            case 'arizona'
                camera.retinaDistance.value = 16.55;
            case 'legrand'
                camera.retinaDistance.value = 16.35;
        end

        % The radius of the whole eyeball is retinaRadius.
        camera.retinaRadius.type    = 'float';
        camera.retinaRadius.value   = 12;  %mm

        % This the semi diameter and pupil diameter are changed, reasonably
        % enough, to control the field of view and match the pupil.
        %
        % The chord length used to define the effect 'width','height' and
        % field of view of the eyeball model.  See the PowerPoint (above).
        camera.retinaSemiDiam.type  = 'float';
        camera.retinaSemiDiam.value = 6;  %mm

        camera.pupilDiameter.type   = 'float';
        camera.pupilDiameter.value  = 4;  % mm

        % Not used in V4.  Like chromatic aberration.  Checking.
        % Default distance to the focal plane in object space.  This
        % differs from the 'object distance' which is the difference
        % between the 'from' and 'to' coordinates.
        % camera.focusdistance.value = 0.2;   % Meters.  Accommodation is 5 diopters
        % camera.focusdistance.type  = 'float';

        % Added May, 2023.  Relates to accommodation (1/focaldistance)
        camera.focaldistance.type    = 'float';
        camera.focaldistance.value   = 1e4;  %mm

        % Default is units of meters.  If you have something in
        % millimeters, you should use this flag
        camera.mmUnits.value = 'false';
        camera.mmUnits.type  = 'bool';


        % Not used in V4.  The chromatic aberration must be handled
        % through the spectralpath integrator, which is separate from the
        % humaneye model.
        % camera.chromaticAberrationEnabled.value = false;
        % camera.chromaticAberrationEnabled.type  = 'bool';

        % These are index of refraction files for the navarro model
        camera.ior1.type = 'spectrum';
        camera.ior2.type = 'spectrum';
        camera.ior4.type = 'spectrum';
        camera.ior3.type = 'spectrum';
        switch eyeModel
            case {'navarro','legrand'}
                camera.ior1.value = 'ior1.spd';
                camera.ior2.value = 'ior2.spd';
                camera.ior3.value = 'ior3.spd';
                camera.ior4.value = 'ior4.spd';
            case 'arizona'
                % Arizona does not have any entries here.  How can that be?
                % Asking TL.  Maybe that model does not include chromatic
                % abberration?
                camera.ior1.value = '';
                camera.ior2.value = '';
                camera.ior3.value = '';
                camera.ior4.value = '';
            otherwise
                error('Unknown eye model %s\n',eyeModel);
        end

    otherwise
        error('Unrecognized camera subtype, %s\n.', cameraType);
end

end
