function [thisR, out] = recipeSet(thisR, param, val, varargin)
% Set a recipe class value
%
% Syntax
%   [thisR, out] = recipeSet(thisR, param, val, varargin)
%
% Brief description
%  Modify the recipe, thisR, as specified by a complex set of possible
%  parameters, values, and varargin.  See below for examples.
%
% Input
%    thisR - recipe
%    param - main parameter
%    val   - value to set the parameter
%
% Output
%   thisR - Not needed, really, because we are a by-reference (handle) class.
%   out   - An optional error code or other return value.
%
% Description:
%  The recipe class manages the PBRT rendering parameters.  The class
%  has many fields specifying camera and rendering parameters. This
%  method is capable of setting only one parameter at a time.
%
% This is mainly an example of the parameters.  There are many more
% examples in the code.  Usually commented.
%
%   Metadata:
%    'name'
%
%   Data management
%    'input file'
%    'output file
%    'rendered file'
%
%  %Scene
%    'mm units'   - Logical (true/false)
%    'exporter'   - Information about where the PBRT file came from
%    'lookat'     - includes the 'from','to', and 'up' vectors
%    'from'       - Position of the camera
%    'to'         - Position the camera is pointed to
%    'up'         - The up direction, not always the y-direction
%
%  % Lights
%    'skymap'     - Name of environmental light exr file
%    'skymap', 'rotation val', <over-ride default rotation> [x y z] degrees
%    'skymap, <name>, <optional attribute>, <attribute value>
%
%  % Camera
%    'camera'     - Struct with camera information
%    'camera subtype' - The valid camera subtypes are
%                       {'pinhole','realistic','humaneye','omni'}
%    'camera exposure'
%    'camera body'      - Do not use
%
%    'object distance' - Distance between from and to
%    'accommodation'   - Inverse of the focus distance
%    'exposure time'   - forces shutteropen to 0
%    'shutteropen'     - time for shutter opening
%    'shutterclose'    - time at which shutter closes
%    'focus distance'  - Distance to where the camera is in best focus
%    'focal distance'  - Used with pinhole to define image plane distance
%                        from the pinhole
%    'n microlens'     - Number of microlenses in front of the sensor
%    'n subpixels'     - Number of pixels behind each microlens
%    'microlens sensor offset' - Distance in mm between the microlens
%                                and film (sensor).  NYI in PBRT.
%
%   % Lens
%     'lens file'    - JSON file for omni.  Older models (realistic) use dat-file
%     'lens radius'  - Only for perspective camera.  Use aperture diameter
%                      for omni
%     'aperture diameter' - mm
%     'fov'
%     'diffraction'
%     'chromatic aberration'
%     TODO:  Microlens information should be stored in some way.
%
%   % Film
%     'film diagonal'
%     'film distance'
%     'spatial samples'
%
%   % humaneye (human optics)
%     'retina distance' - mm
%     'eye radius'      - mm
%     'retina semdiam'  - mm
%     'pupil diameter'  - mm
%     'ior1','ior2','ior3','ior4' - Index of refraction data for Navarro eye
%                          model
%
%  Film/sensor
%    'film diagonal'
%    'film distance'
%    'film resolution'
%    'rays per pixel'
%
%  Rendering
%    'integrator num ca bands'
%    'integrator subtype'
%    'sampler'
%    'filter'
%    'rays per pixel'
%    'crop window'
%    'nbounces'
%    'autofocus'
%
%  Assets
%    Big set of options.
%
%  Lights
%
%  Materials
%    'materials'
%    'materials output file'
%    'fluorophore concentration'
%    'fluorophore eem'
%    'concentration'
%
%  Programming related
%    'verbose'
%
%  ISETAuto special:
%    'traffic flow density'%
%    'traffic time stamp'
%
% BW ISETBIO Team, 2017
%
% PBRT information that explains many of the options
%    https://www.pbrt.org/fileformat-v3.html#overview
%
% Specifically
%    https://www.pbrt.org/fileformat-v3.html#cameras
%
% See also
%    @recipe, recipeGet

% Examples:
%{
%}

%% Set up

if isequal(param,'help')
    doc('recipe.recipeSet');
    return;
end

out = [];

%% Parse
p = inputParser;
p.KeepUnmatched = true;

vFunc = @(x)(isequal(class(x),'recipe'));
p.addRequired('thisR',vFunc);
p.addRequired('param',@ischar);
p.addRequired('val');

p.addParameter('lensfile','dgauss.22deg.12.5mm.dat',@(x)(exist(x,'file')));
p.addParameter('verbose', thisR.verbose, @isnumeric);

p.parse(thisR, param, val);
param = ieParamFormat(p.Results.param);
% verbosity = p.Results.verbose;

%% Act

switch param

    % Object metadata
    case {'name'}
        thisR.name = val;

        % Rendering and Docker related
    case {'outputfile'}
        % thisR.set('outputfile',fullfilepath);
        % This file may not yet exist.  It is where PBRT will write the
        % output file.
        thisR.outputFile = val;

    case {'inputfile'}
        % thisR.set('input file',filename);
        % This file should typically exist.  There are cases, however,
        % where we may set it before the file exists.  I think.
        %if ~isfile(val), warning('Specified input file not found.'); end
        thisR.inputFile = val;
    case {'verbose'}
        thisR.verbose = val;
    case {'exporter'}
        % thisR.set('exporter',val);
        % a string that identifies how the PBRT file was build
        % We have 'C4D','Copy','Unknown'
        thisR.exporter = val;
    case 'renderedfile'
        % thisR.set('rendered file',fname);
        % Set the full path
        thisR.renderedfile = val;

        % Scene parameters
    case {'fromtodistance','objectdistance'}
        % thisR.set('object distance',val);
        %
        % The 'from' spot, is the camera location.  The 'to' spot is
        % the point the camera is looking at.  Both are specified in
        % meters.
        %
        % This routine adjusts the the 'from' position, moving the
        % camera position. It does so by keeping the 'to' position the
        % same, so the camera is still looking at the same location.
        % Thus, this set moves the camera closer or further from the 'to'
        % position.
        %
        % What is the relationship to the focal distance?  If we move
        % the camera, the focal distance is always with respect to the
        % camera, right?  Or is it always at the 'to' distance???  You can
        % force it to be the 'to' by using
        %
        % thisR.set('focal distance',thisR.get('object distance'))
        %
        % See recipeSet 'todistance'

        assert(val > 0);  % We do not change which side of 'to' this way.

        % Unit length vector  objDir = ('to' - 'from')
        % So, 'from' + objDir moves towards 'to'
        %     'from' - objDir moves away from 'to'
        objDirection = thisR.get('object direction');

        % Change in distance (in meters).  If val is bigger, delta is
        % negative and adding moves away from 'to'.  If val is smaller,
        % delta is positive and we move towards 'to'.
        delta = thisR.get('object distance') - val;

        % Test: If we set val to 0, the new from should be at 'to',
        thisR.lookAt.from = thisR.lookAt.from + objDirection*delta;

    case {'todistance'}
        % thisR.set('to distance',val) % Meters
        %
        % Adjusts the 'to' position along the 'from to' line.  Leaves the
        % camera position (from) unchanged
        %
        %  to = from + fromto
        from = thisR.get('from');
        fromto = thisR.get('fromto');
        thisR.set('to',from + fromto*val);

    case {'accommodation'}
        % We allow specifying accommodation rather than focal distance.
        % For typical lenses, accommodation is 1/focaldistance.
        %
        % For the human eye models, we need to change the whole lens model
        % using setNavarroAccommodation or setArizonaAccommodation.
        %
        % There is no way to adjust the LeGrand eye.
        %
        subType = thisR.get('camera subtype');
        switch subType
            case {'humaneye'}
                % For the human eye models accommodation is baked into
                % the lens itself, and stored in the lens file.
                eyeModel = thisR.get('human eye model');
                % lensDir = thisR.get('lens dir output');

                % Perhaps we should write out silently?  The lens file
                % is always written to the lens output dir.  We used
                % to use the functions setNavarroAccommodation and
                % setArizonaAccommodation.  But they are now
                % deprecated.
                switch eyeModel
                    case 'navarro'
                        % The accommodation sent in by the user is
                        % converted to a different value because TL
                        % tested and felt that was proper.  See
                        % comments.
                        navarroWrite(thisR,val);
                    case 'arizona'
                        arizonaWrite(thisR,val);
                    case 'legrand'
                        warning('The LeGrand eye does not allow accommodation adjustment.')
                    otherwise
                        error('Unknown human eye model %s',modelName);
                end
            otherwise
                % Nothing
        end

        % Accommodation is the inverse of focal distance. Even for human.
        % For cameras, we do not usually set accommodation. Rather, we
        % adjust the distance from the lens to the film (sensor).  We
        % store the focal distance in the recipe (inside the camera
        % slot) here.
        thisR.set('focal distance',1/val);

    case {'focusdistance','focaldistance'}
        % lens.set('focus distance',m)
        %
        % This is the distance (m) to the object in the scene that
        % will be in focus.  The film distance is derived by PBRT from
        % this parameter.  It is possible that there is no film
        % distance for certain (say very near) focus distances.
        %
        % This variable is related to the lookat settings.  That
        % parameter says where the camera is pointing.  But the
        % distance to the object (objectdistance) may not be the same
        % as this focus distance. That is because it is possible to
        % look at an object but have it not be the object that is in
        % focus.

        % Depending on the camera subtype, the parameter name is either
        % focusdistance or focaldistance. Historical annoyance in PBRT.

        subType = thisR.get('camera subtype');
        switch subType
            case {'pinhole'}
                thisR.camera.focaldistance.value = val;
                thisR.camera.focaldistance.type = 'float';

                % pbrt v4 does not allow this field
                if isfield(thisR.camera,'focusdistance')
                    thisR.camera = rmfield(thisR.camera,'focusdistance');
                end
            case {'humaneye'}
                % For the human eye models, the lens accommodation is
                % stored in the lens file, which is written out by either
                % the Navarro or Arizona eye functions, such as
                %
                %    [na,txt] = navarroLensCreate(accommodation)) or by
                %    thisR = setNavarroAccommodation(thisR, accommodation, workingFolder)
                %    [az, columnDescription]  = arizonaLensCreate(1);
                %
                % We store the focaldistance in the camera slot.
                % But until 05.2023 we (mistakenly) stored it in the
                % retinalDistance slot.
                %   thisR.camera.retinalDistance.value = val;
                %   thisR.camera.retinalDistance.type = 'float';
                %
                % But setting this value does not change the
                % accommodation file that we write out.  In the
                % humaneye case, it should cause a write of the eye
                % model file during piWrite.  Check whether this is
                % happening.
                thisR.camera.focaldistance.value = val;
                thisR.camera.focaldistance.type = 'float';

                % pbrt v4 does not allow this field, but I am confused by
                % this (BW).  It is used just belows in the omni case?
                % Maybe we can't have both?
                if isfield(thisR.camera,'focusdistance')
                    thisR.camera = rmfield(thisR.camera,'focusdistance');
                end

            case {'omni','realistic'}
                % When there is a lens.  Omni.  Realistic.
                thisR.camera.focusdistance.value = val;
                thisR.camera.focusdistance.type = 'float';
            otherwise
                warning('Unknown camera subtype %s', subType);
        end

        % Camera
    case 'camera'
        % val = piCameraCreate('pinhole'); thisR = recipe;
        % thisR.set('camera',val);
        %
        % The whole camera struct
        thisR.camera = val;
        %{

        % This deprecated code is very bizarre for recipeSet. So I replaced
        % it.  But probably this change will break stuff.  We will have to
        % fix.
        thisR.camera = piCameraCreate(val,'lensFile',p.Results.lensfile);

        % For the default camera, the film size is 35 mm
        thisR.set('film diagonal',35);

        %}
    case 'scale'
        % Scale something?? Was missing until December 11, 2021.
        % Will experiment with what it does.  There is a slot for it in
        % piWrite().
        if numel(val) == 3,     thisR.scale = val(:)';
        elseif numel(val) == 1, thisR.scale = ones(3,1)*val;
        else, warning('Bad scale value.  Must be scalar or 3-vector');
        end

    case 'mmunits'
        % thisR.set('mm units',true/false)
        %
        % Indicate whether we are in millimeter units or not
        thisR.camera.mmUnits.type = 'bool';
        if val
            % val is true, so we are in millimeter units
            thisR.camera.mmUnits.value = 'true';
        else
            % We are probably in units of meters, not millimeters
            thisR.camera.mmUnits.value = 'false';
        end
    case {'transformtimesstart'}
        thisR.transformTimes.start = val;
        if ~isfield(thisR.transformTimes, 'end')
            warning('Adding transform end time: %.4f', val + 1);
            thisR.transformTimes.end = val + 1;
        end
    case {'transformtimesend'}
        if ~isfield(thisR.transformTimes, 'start')
            warning('Adding transform start time: %.4f', 0);
            thisR.transformTimes.start = 0;
        end
        thisR.transformTimes.end = val;
    case 'cameratype'
        % This should always be 'Camera'
        if ~isequal(val,'Camera')
            error('Check your code');
        end
    case {'camerasubtype'}
        % I don't think the sub is needed.  But there it is.
        thisR.camera.subtype = val;

        % Camera motion
    case {'cameramotiontranslatestart'}
        % thisR.set('camera motion translate start',vector)
        thisR.camera.motion.activeTransformStart.pos = val;

    case {'cameramotiontranslateend'}
        % thisR.set('camera motion translate end',vector)
        thisR.camera.motion.activeTransformEnd.pos = val;

    case {'cameramotionrotatestart'}
        % thisR.set('camera motion rotate start',rotMatrix)
        thisR.camera.motion.activeTransformStart.rotate = val;

    case {'cameramotionrotateend'}
        % thisR.set('camera motion rotate end',rotMatrix)
        thisR.camera.motion.activeTransformEnd.rotate = val;

        % Camera exposure
    case {'cameraexposure','exposuretime'}
        % Shutter duration in sec
        % Shutter open is always at time zero
        thisR.camera.shutteropen.type  = 'float';
        thisR.camera.shutteropen.value = 0;

        thisR.camera.shutterclose.type = 'float';
        thisR.camera.shutterclose.value = val;
    case {'shutteropen'}
        % thisR.set('shutter open',time)
        if isfield(thisR.camera,'shutterclose')
            if val > thisR.camera.shutterclose.value
                warning('Open time later than open time');
            end
        end
        thisR.camera.shutteropen.type  = 'float';
        thisR.camera.shutteropen.value = val;
    case {'shutterclose'}
        % thisR.set('shutter close',time)
        if isfield(thisR.camera,'shutteropen')
            if val < thisR.camera.shutteropen.value
                warning('Close time earlier than open time');
            end
        end
        thisR.camera.shutterclose.type = 'float';
        thisR.camera.shutterclose.value = val; %single(val);

        % Lens related
    case 'lensfile'
        % lens.set('lens file',val)   (string)
        % Typically a JSON file defining the camera.  But for humaneye
        % we are still using dat files (e.g., navarro.dat).
        if ~exist(val,'file')
            % Sometimes we set this without the file being copied yet.
            % Let's see if this warning does us any good.
            % warning('Lens file in out dir not yet found (%s)\n',val);
        end
        thisR.camera.lensfile.value = val;
        thisR.camera.lensfile.type = 'string';

    case {'pinholeradius','lensradius'}
        % thisR.set('pinhole radius',val (mm))
        %
        % Should only be set for perspective cameras.  Controls the
        % size of the pinhole.  Introduces some blur if > 0.
        %
        if isequal(thisR.camera.subtype,'perspective')
            thisR.camera.lensradius.value = val;
            thisR.camera.lensradius.type = 'float';
        else
            warning('Lens radius is set for perspective camera.  Use aperture diameter for omni');
        end

        % Human eye model related
    case {'retinadistance'}
        % Specified in mm
        thisR.camera.retinaDistance.value = val;
        thisR.camera.retinaDistance.type = 'float';
    case {'eyeradius','retinaradius'}
        % Specified in mm
        thisR.camera.retinaRadius.value = val;
        thisR.camera.retinaRadius.type = 'float';
    case {'retinasemidiam'}
        % Specified in mm
        thisR.camera.retinaSemiDiam.value = val;
        thisR.camera.retinaSemiDiam.type = 'float';
    case {'pupildiameter'}
        % Specified in mm
        thisR.camera.pupilDiameter.value = val;
        thisR.camera.pupilDiameter.type = 'float';

    case {'ior1','ior2','ior3','ior4'}
        % thisR.set('ior1',fullfilename);
        %
        % For the humaneye camera subtype, we store spd files that specify
        % the indices of refraction. for each of the different human optics
        % components.
        if ~isequal(thisR.get('camera subtype'),'humaneye')
            warning('No ior slot except for humaneye camera subtype.');
        else
            switch param(end)
                case '1'
                    % cornea
                    thisR.camera.ior1.value = val;
                    thisR.camera.ior1.type = 'spectrum';
                case '2'
                    % acqueous
                    thisR.camera.ior2.value = val;
                    thisR.camera.ior2.type = 'spectrum';
                case '3'
                    % lens
                    thisR.camera.ior3.value = val;
                    thisR.camera.ior3.type = 'spectrum';
                case '4'
                    % vitreous
                    thisR.camera.ior4.value = val;
                    thisR.camera.ior4.type = 'spectrum';
            end
        end

        % More general camera parameters
    case {'aperture','aperturediameter'}
        % lens.set('aperture diameter',val (mm))
        %
        % Set 'aperture diameter' should look at the aperture in the
        % lens file, which represents the largest possible aperture.
        % It should not allow a value bigger than that.  (ZL/BW).

        % Throw a warning for perspective camera
        if isequal(thisR.camera.subtype,'pinhole') ||...
                isequal(thisR.camera.subtype,'perspective')
            warning('Perspective/pinhole camera - setting "lens radius".')
            thisR.set('lens radius',val/2);
            return;
        end

        thisR.camera.aperturediameter.value = val;
        thisR.camera.aperturediameter.type = 'float';
    case {'fov'}
        % thisR.set('fov',deg)
        % This always refers to the shorter of the two dimensions (the
        % limiting field of view).  Not the diagonal.
        % https://pbrt.org/fileformat-v4
        %
        thisR.camera.fov.value = val;
        thisR.camera.fov.type = 'float';

    case 'diffraction'
        % thisR.set('diffraction');
        %
        % Turn on diffraction rendering.  Works with realistic eye and
        % omni.  Probably humaneye, but we should ask TL.
        if val
            thisR.camera.diffractionEnabled.value = 'true';
        else
            thisR.camera.diffractionEnabled.value = 'false';
        end
        thisR.camera.diffractionEnabled.type = 'bool';

    case 'chromaticaberration'
        % There is no chromaticAberration flag in the recipe any more.
        % This set adjust the integrator and the number of CA bands.
        %
        % If true, set the integrator to spectralpath and the number of
        % bands to 8.
        % If an integer between 1 and 30, set the integrator
        % to spectralpath and the number of bands to that integer.
        % If false, set the integrator to 'path' and the number of CA bands
        % to 1.
        %
        % Examples:
        %   thisR.set('chromatic aberration',true);
        %   thisR.set('chromatic aberration',false);
        %   thisR.set('chromatic aberration',16);

        % User turned off chromatic abberations
        if isequal(val,false)
            % Use path, not spectralpath, integrator.
            % Set nunCABand to 1.
            thisR.set('integrator subtype','path');
            thisR.set('integrator num ca bands',1);

            % Set the enabled flag.
            % This was deleted at some point.  Not sure why.
            thisR.camera.chromaticAberrationEnabled.value = false;
            return;
        else
            % User sent in true or an integer number of bands which implies
            % true.

            % This is the integrator that manages chromatic aberration.
            thisR.set('integrator subtype','spectralpath');

            % Set the number of bands.
            if islogical(val), val = 8; end  % Default number of bands

            % The bands are divided evenly the 31 wavelength samples,
            % between 400 and 700 nm. If the user sent in more than 30, we
            % have a problem.  So ...
            val = min(val,30);
            thisR.set('integrator num cabands',val);

            % Set the enabled flag to true.
            thisR.camera.chromaticAberrationEnabled.type  = 'bool';
            thisR.camera.chromaticAberrationEnabled.value = true;
        end

    case {'integratorsubtype','integrator'}
        % thisR.set('integrator subtype',val)
        %
        % Different integrators are needed depending on the materials in
        % the scene, and also for chromatic aberration calculations.  For
        % example spectralpath is needed for CA.  bdpt is needed when there
        % are scattering media.
        thisR.integrator.type = 'Integrator';
        thisR.integrator.subtype = val;

    case 'integratornumcabands'
        thisR.integrator.type = 'Integrator';
        thisR.integrator.numCABands.value = val;
        thisR.integrator.numCABands.type = 'integer';

    case{'maxdepth','bounces','nbounces'}
        % thisR.set('n bounces',val);
        % Number of surfaces a ray can bounce from
        %
        % This can be set for some, but not all integrators. Also,
        % sometimes the integrator slot is empty.  I am not sure what
        % happens then (BW).
        %
        % I allowed spectralpath for multiple bounces.  Not sure that is
        % OK, but will ask Zhenyi soon (BW).
        if(~strcmp(thisR.integrator.subtype,'path')) &&...
                ~(strcmp(thisR.integrator.subtype,'bdpt') || ...
                strcmp(thisR.integrator.subtype,'spectralpath'))

            disp('Changing integrator sub type to "bdpt"');

            % When multiple bounces are needed, use this integrator
            thisR.integrator.subtype = 'bdpt';
        end

        thisR.integrator.maxdepth.value = val;
        thisR.integrator.maxdepth.type = 'integer';

    case 'autofocus'
        % Should deprecate this.  Let's run it for a while and see how
        % often it turns up.
        %
        % thisR.set('autofocus',true);
        % Sets the film distance so the lookAt to point is in good focus
        warning('Bad autofocus set in recipe.  Fix!');
        if val
            fdist = thisR.get('focal distance');
            if isnan(fdist)
                error('Camera is probably too close (%f) to focus.',thisR.get('object distance'));
            end
            thisR.set('film distance',fdist);
        end

        % Camera position related.  The units are in ????
    case 'lookat'
        % Includes the from, to and up in a struct
        if isstruct(val) &&  isfield(val,'from') && isfield(val,'to')
            thisR.lookAt = val;
        end
    case {'from','cameraposition'}
        thisR.lookAt.from = val(:)';  % Force row vector
    case 'to'
        thisR.lookAt.to = val(:)';
    case 'up'
        thisR.lookAt.up = val(:)';


        % Microlens
    case 'microlens'
        % Not sure about what this means.  It is on or off
        thisR.camera.microlens_enabled.value = val;
        thisR.camera.microlens_enabled.type = 'float';
    case 'nmicrolens'
        % Number of microlens/pinhole samples for a light field camera
        %
        if length(val) == 1, val(2) = val(1); end
        thisR.camera.num_pinholes_h.value = val(1);
        thisR.camera.num_pinholes_h.type = 'float';
        thisR.camera.num_pinholes_w.value = val(2);
        thisR.camera.num_pinholes_w.type = 'float';
    case 'microlenssensoroffset'
        % thisR.set('microlens sensor offset',val) - Units meters.
        %
        % Printed out in 'camera' subfield of PBRT file for use by
        % omni camera.
        thisR.camera.microlenssensoroffset.type = 'float';
        thisR.camera.microlenssensoroffset.value = val;
    case 'nsubpixels'
        % How many pixels behind each microlens/pinhole
        % The type is not included because this is not passed to pbrt.  It
        % is specified in the lens file made by the Docker container.  See
        % instructions about modeling light field cameras.
        thisR.camera.subpixels_h = val(1);
        thisR.camera.subpixels_w = val(2);

        % Film parameters
    case 'filmdiagonal'
        % thisR.set('film diagonal',val)
        % Default units are millimeters.
        opticsType = thisR.get('camera subtype');
        switch opticsType
            case {'pinhole','humaneye'}
                disp('Film diagonal not used for pinhole and human eye');
            otherwise
                thisR.film.diagonal.type = 'float';
                thisR.film.diagonal.value = val;
        end
    case 'filmsize'
        % thisR.set('film size',[width,height] in mm);
        %
        % The person wants to specify width,height but the code is
        % with respect to the diagonal. So we compute the relevant
        % parameters here, maintaining the sample spacing.
        spacing = thisR.get('sample spacing','mm');

        filmdiagonal = sqrt(val(1).^2 + val(2).^2);  % New diagonal
        thisR.set('film diagonal',filmdiagonal);

        nRowCol = round([val(1),val(2)]/spacing);
        thisR.set('film resolution',nRowCol);

    case {'filmdistance'}
        % Set in meters. Sigh again.
        thisR.camera.filmdistance.type = 'float';
        thisR.camera.filmdistance.value = val;
    case {'filmshapefile'}
        % thisR.set('film shape file') = JSONFile;
        %
        % Used for making arbitrary film shapes, as in the examples in
        % the ISETBio directory retinaShape.
        %
        % We considered naming this filmshape.  To do that requires
        % recompiling PBRT to look for 'filmshape' and rebuilding the
        % Docker containers (TG/BW)
        thisR.camera.lookuptable.type = 'string';
        thisR.camera.lookuptable.value  = val;

    case {'spatialsamples','filmresolution','spatialresolution'}
        % thisR.set('spatial samples',256);
        %
        % Number of spatial samples on the film (or retinal) surface. The
        % number of samples may be spread over larger or smaller field of
        % view.
        if length(val) == 1, val(2) = val(1); end
        thisR.film.xresolution.value = val(1);
        thisR.film.yresolution.value = val(2);
        thisR.film.xresolution.type = 'integer';
        thisR.film.yresolution.type = 'integer';

        % Sampler
    case 'samplersubtype'
        % thisR.set('sampler subtype','halton')
        %
        thisR.sampler.type = 'Sampler';
        thisR.sampler.subtype = val;
    case {'raysperpixel','pixelsamples','samplesperpixel'}
        % thisR.set('rays per pixel')
        % How many rays from each pixel
        if isempty(thisR.sampler)
            thisR.sampler.type = 'Sampler';
            thisR.sampler.subtype = 'pmj02bn';
        end
        thisR.sampler.pixelsamples.value = val;
        thisR.sampler.pixelsamples.type = 'integer';

    case{'cropwindow'}
        thisR.film.cropwindow.value = [val(1) val(2) val(3) val(4)];
        thisR.film.cropwindow.type = 'float';

        % SUMO parameters stored in recipe metadata
    case {'trafficflowdensity'}
        thisR.metadata.sumo.trafficflowdensity = val;
    case {'traffictimestamp'}
        thisR.metadata.sumo.timestamp = val;

    case 'filter'
        % Spatial filter for interpolating rays onto the film sampling grid
        % Options for the filter are
        %
        %    'box', 'triangle','gaussian','mitchell', 'sinc'
        %
        thisR.filter = val;

        % Getting ready for camera level recipe information.
        % Not really used yet and may never get used.
    case {'camerabody'}
        % Notice that val is rather special in this case. Which we are not
        % yet using.
        thisR.set('camera',val.camera);
        thisR.set('film',val.film);
        thisR.filter = thisR.set('filter',val.filter);

    case {'medium','media'}
        % thisR.set(param,val,varargin{1},varargin{2})
        %
        % Calling convention
        %
        %  param = media or medium, which is why you are here
        %  val     medium name or medium struct, or one of several key
        %  words
        %  varargin{1} action ('add','replace','delete'), or
        %              a parameter ('scatter')
        %              a medium
        %  varargin{2} parameter
        %
        % thisR.set('media', 'add', newMedium);
        % thisR.set('media', 'delete', mediumName);
        % thisR.set('media', 'replace', mediumName, newMedium);
        %
        % thisR.set('media', mediumName, 'scatter',val)
        % Others to come

        % It is either a special command (add, delete, replace) or
        % the material name
        switch val
            case {'add'}
                % There must be a new medium to add
                newMed = varargin{1};

                if isstruct(newMed) && isfield(newMed,'medium')
                    thisName = newMed.media.name;
                    thisR.media.list(thisName) = newMed.material;
                    thisR.media.order{end + 1} = thisName;
                else
                    % Not part of newMat.material, just a material
                    thisR.media.list(newMed.name) = newMed;
                    thisR.media.order{end + 1} = newMed.name;
                end
                return;
            case {'delete', 'remove'}
                % With the container/key method, we use the 'remove'
                % function to delete the material from the list and
                % from the order.  This requires using the name of the
                % material, not just its numeric value.  So, we get the
                % name.
                if isnumeric(varargin{1})
                    names = keys(thisR.media.list);
                    thisName = names(varargin{1});
                else
                    thisName = varargin{1};
                end
                remove(thisR.media.list, thisName);
                [~,idx] = ismember(thisName,thisR.media.order);
                thisR.media.order(idx) = [];
                return;
            case {'replace'}
                % thisR.set('materials',matName,'replace',newMaterial)
                thisR.media.list(varargin{1}) = varargin{2};
                [~,idx] = ismember(varargin{1},thisR.media.order);
                thisR.media.order{idx} = varargin{2}.name;
                return;
            otherwise
                % Should be the medium name.
                thisMedium = thisR.media.list(val);

                % We adjust the parameter of the medium.  All this
                % could go into
                %   mediumSet(thisMedium,param,val);
                %   mediumSet(thisMedium,varargin{1},varargin{2});
                switch ieParamFormat(varargin{1})
                    case 'scatter'
                        % Set scatter to varargin{2}
                        tmp = [varargin{2}.wave;varargin{2}.scatter];
                        thisMedium.sigma_s.value = tmp(:)';
                        thisR.set('media','replace',val,thisMedium);
                    case 'absorption'
                        % Set absorption to varargin{2}
                        tmp = [varargin{2}.wave;varargin{2}.absorption];
                        thisMedium.sigma_a.value = tmp(:)';
                        thisR.set('media','replace',val,thisMedium);
                    case 'scale'
                    case 'Le'
                    case 'preset'
                    otherwise
                        disp('Unknown.')
                end
        end


        % Materials should be built up here.
    case {'materials', 'material'}
        % Act on the list of materials
        %
        % thisR.set('material', materialList);
        % thisR.set('material', matName, newMaterial);
        % thisR.set('material', 'add', newMaterial);
        % thisR.set('material', 'delete', matName);
        % thisR.set('material', matName, 'PARAM TYPE', VAL);
        % thisR.set('material', matName,'replace',val);


        % In this case, we completely replace the material list.
        if isempty(varargin)
            if isa(thisR.materials.list, 'containers.Map')
                thisR.materials.list = val;
            else
                warning('Please provide a list of materials in a containers.Map')
            end
            return;
        end
        % Get index and material struct from the material list
        % Search by name or index
        if isstruct(val)
            % They sent in a struct
            if isfield(val,'name'), matName = val.name;
                % It has a name slot.
                thisMat = thisR.materials.list(matName);
            else
                error('Bad struct.');
            end
        elseif ischar(val)
            % It is either a special command (add, delete, replace) or
            % the material name
            switch val
                case {'add'}
                    newMat = varargin{1};
                    if isstruct(newMat) && isfield(newMat,'texture')
                        % This is probably from piMaterialPresets, and
                        % it may include a material and a cell array
                        % of textures
                        if iscell(newMat.texture)
                            % Cell
                            for tt=1:numel(newMat.texture)
                                thisR.set('texture','add',newMat.texture{tt});
                            end
                        else
                            % Plain
                            thisR.set('texture', 'add', newMat.texture);
                        end

                        thisR.set('material', 'add', newMat.material);
                    elseif isstruct(newMat) && isfield(newMat,'material')
                        thisName = newMat.material.name;
                        thisR.materials.list(thisName) = newMat.material;
                        thisR.materials.order{end + 1} = thisName;
                    else
                        % Not part of newMat.material, just a material
                        thisR.materials.list(newMat.name) = newMat;
                        thisR.materials.order{end + 1} = newMat.name;
                    end
                    return;
                case {'delete', 'remove'}
                    % With the container/key method, we use the 'remove'
                    % function to delete the material from the list and
                    % from the order.  This requires using the name of the
                    % material, not just its numeric value.  So, we get the
                    % name.
                    if isnumeric(varargin{1})
                        names = keys(thisR.materials.list);
                        thisName = names(varargin{1});
                    else
                        thisName = varargin{1};
                    end
                    remove(thisR.materials.list, thisName);
                    [~,idx] = ismember(thisName,thisR.materials.order);
                    thisR.materials.order(idx) = [];
                    return;
                case {'replace'}
                    % thisR.set('materials',matName,'replace',newMaterial)
                    thisR.materials.list(varargin{1}) = varargin{2};
                    [~,idx] = ismember(varargin{1},thisR.materials.order);
                    thisR.materials.order{idx} = varargin{2}.name;
                    return;
                otherwise
                    % Probably the material name.
                    matName = val;
                    thisMat = thisR.materials.list(val);
            end
        end

        % At this point we have the material.
        if numel(varargin{1}) == 1
            % A material struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it.
            thisR.materials.list(matName) = varargin{1};
        else
            % A material name and property was sent in.  We set the
            % property and then update the material in the list.
            thisMat = piMaterialSet(thisMat, varargin{1}, varargin{2});
            thisR.set('materials', matName, thisMat);
        end

    case {'materialsoutputfile'}
        % Deprecated?
        thisR.materials.outputfile = val;

    case {'mediaoutputfile'}
        % Deprecated?
        thisR.media.outputfile = val;

    case {'textures', 'texture'}
        % thisR.set('texture',textureName,parameter,value);
        % thisR.set('texture',textures
        if isempty(varargin)
            % At this point thisR.textures has a slot for list
            % (contains.Map) and a slot for order, a cell array of texture
            % names.  The code here is not the right way to adjust
            % thisR.textures.
            if iscell(val)
                thisR.textures.list = val;
            else
                warning('Please provide a list of textures in cell array')
            end
            return;
        end
        % Get index and texture struct from the texture list
        % Search by name or index
        if isstruct(val)
            % They sent in a struct
            if isfield(val,'name'), textureName = val.name;
                % It has a name slot.
                thisTexture = thisR.textures.list(textureName);
            else
                error('Bad struct.');
            end
        elseif ischar(val)
            % It is either a special command or the texture name
            newTexture = varargin{1};
            switch val
                case {'add'}
                    % thisR.set('textures', 'add', texture struct);
                    if ~isKey(thisR.textures.list, newTexture.name)
                        thisR.textures.list(newTexture.name) = varargin{1};
                        thisR.textures.order{end + 1} = newTexture.name;
                    else
                        warning('%s tecture already exists, overriding',...
                            newTexture.name);
                        thisR.textures.list(newTexture.name) = varargin{1};
                    end
                    return;
                case {'delete', 'remove'}
                    % thisR.set('texture', 'delete', idxORname);
                    remove(thisR.textures.list, varargin{1}.name)
                    [~,idx] = ismember(varargin{1},thisR.textures.order);
                    thisR.textures.order(idx) = [];
                    return;
                case {'replace'}
                    % thisR.set('texture','replace', idxORname-1, newtexture-2)
                    thisR.textures.list(varargin{1}) = varargin{2};
                    [~,idx] = ismember(varargin{1},thisR.textures.order);
                    thisR.textures.order{idx} = varargin{2}.name;
                    return;
                case {'basis'}
                    % thisR.set('texture', 'basis', tName, wave, basisfunctions)
                    % basisfunctions need to have size of 3 x numel(wave)
                    if isequal(thisR.textures.list(varargin{1}).type, 'imagemap')
                        wave = varargin{2};
                        piTextureSetBasis(thisR, varargin{1}, wave, 'basis functions', varargin{3});
                    else
                        warning('Basis function only applies to image map.')
                    end
                    return;
                otherwise
                    % Probably the material name.
                    textureName = val;
                    [textureName, thisTexture] = piTextureFind(thisR.textures.list, 'name', textureName);
            end
        end

        % At this point we have the texture.  This code has not been used a
        % lot and needs checking.  Maybe with Zheng's help. (BW).
        if numel(varargin{1}) == 1
            % A texture struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it.
            thisTexture = varargin{1};
            thisR.textures.list(thisTexture.name) = varargin{1};
        else
            % A texture name and property was sent in.  We set the
            % property and then update the material in the list.
            thisTexture = piTextureSet(thisTexture, varargin{1}, varargin{2});
            thisR.set('textures', textureName, thisTexture);
        end

    case {'skymap'}
        % thisR.set('skypmap',filename)
        % add a skymap by filename
        % See piDockerImgtool for creating skymaps
        if isstruct(val) && strcmp(val.type,'skymap')
            % use a database skymap
            skymapFileName = val.filepath;
        else

            % If no extension passed, we assume an 'exr' extension
            [~,n,e] = fileparts(val);
            if isempty(e), e = '.exr'; end
            skymapFileName = [n,e];

            % if the map isn't already in the output dir, we have to copy it
            if ~isfolder(fullfile(thisR.get('output dir')))
                mkdir(fullfile(thisR.get('output dir')));
            end

            if ~isfile(fullfile(thisR.get('output dir'),skymapFileName))
                % We keep all skymap files in this folder now.
                skymapdir = fullfile(thisR.get('output dir'),'skymaps');
                % If it is not in the local directory, check the data/skymaps
                if isfile(fullfile(piDirGet('skymaps'), skymapFileName))
                    if ~isfolder(skymapdir), mkdir(skymapdir); end
                    copyfile(fullfile(piDirGet('skymaps'), skymapFileName),...
                        skymapdir);
                else
                    % Not found yet, look for it anywhere on the path
                    exrFile = which(skymapFileName);
                    if ~isempty(exrFile)
                        fprintf('Using skymap file: %s\n',exrFile);
                        if ~isfolder(skymapdir), mkdir(skymapdir); end
                        copyfile(exrFile, skymapdir);
                    else
                        % BW is confused by this. But moving on.
                        % If skymapFileName exists at different location, we
                        % move it to the output folder.
                        if exist(skymapFileName,"file")
                            [~, filename, ext] = fileparts(skymapFileName);
                            fprintf('Using skymap:  %s\n',[filename,ext]);
                            copyfile(skymapFileName,thisR.get('output dir'));
                            skymapFileName = [filename,ext];
                        elseif exist(val, "file")
                            [~, filename, ext] = fileparts(skymapFileName);
                            fprintf('Using skymap:  %s\n',[filename,ext]);
                            copyfile(val, thisR.get('output dir'));
                            skymapFileName = [filename, ext];
                        else
                            warning("Unable to find skymap: %s\n", skymapFileName);
                            return % can't create the light
                        end

                    end
                end
            end
        end
        % Create a sky light with default params.
        [~, f, ~] = fileparts(skymapFileName);

        lName = f; % in case we want to get fancy later
        envLight = piLightCreate(lName, ...
            'type', 'infinite',...
            'filename', skymapFileName);
        thisR.set('lights', envLight, 'add');

        if ~isempty(varargin) && isequal(varargin{1},'rotation val')
            thisR.set('light', lName, 'rotate', varargin{2});
        else
            % For V4 we do not usually need the -90 rotation as we did
            % for V3. For V4 the 'up' direction seems to mainly be
            % z-up. But scenes where it is y-up, we need the rotation.
            % (Check with Zhenyi).
            up = thisR.get('up');
            if up(2) > up(3)
                % This is a y-up recipe, so by default we rotate the skypmap
                thisR.set('light', lName, 'rotate', [-90 0 0]);
            end
        end

        out = envLight;

    case {'light', 'lights'}
        % Calling convention
        %
        %   param is 'light', which is why you are here
        %   val is lightName
        %   varargin{1} is the parameter(or action)
        %   varargin{2...} are additional values, if needed.
        %
        % Examples - After making light consistent with assets:
        %
        % thisR.set('light', newLight, 'add');
        % thisR.set('light', newLightCellArray, 'add');
        % thisR.set('light', lightName, 'delete');
        % thisR.set('light', 'all', 'delete');
        % thisR.set('light', lightName, 'rotate', [XROT, YROT, ZROT], ORDER)
        % thisR.set('light', lightName, 'translate', [XSFT, YSFT, ZSFT], FROMTO);
        % thisR.set('light', lightname, 'specscale', val);
        % thisR.set('light', lightName, 'spread val',20);
        % thisR.set('light', lightName, 'spd',[0.5 0.3 1]);

        % TODO:  We need additional cases for the area light

        if isnumeric(val)
            thisLight = thisR.get('light', val);
            lghtName = thisLight.name;
            lghtName = piLightNameFormat(lghtName);
        elseif ischar(val)
            lghtName = val;
            lghtName = piLightNameFormat(lghtName);
        elseif isstruct(val) || iscell(val) % A light struct or a cell array
            newLight = val;
            lghtName = newLight.name;
        else
            error('Unknown light parameter!');
        end

        param = varargin{1};

        if numel(varargin) == 2, val = varargin{2}; end

        switch ieParamFormat(param)
            case 'add'
                % thisR.set('light', newLight, 'add')
                if isstruct(newLight)
                    % Make sure light name has '_L' in the end
                    newLight.name = piLightNameFormat(newLight.name);

                    % Make sure the light name is unique.
                    currentLightNames = thisR.get('lights','names');
                    if contains(currentLightNames,newLight.name)
                        disp('Adjusting duplicate light name');
                        tmp = newLight.name(1:end-2);
                        newLight.name = sprintf('%s-%03d_L',tmp,randi(100));
                    end

                    % Create an asset of type light
                    newLightAsset = piAssetCreate('type', 'light');
                    newLightAsset.name = newLight.name;
                    newLightAsset.lght{1} = newLight;

                    % Insert a branch for the light geometry under the
                    % root.
                    defaultBranch = piAssetCreate('type', 'branch');
                    defaultBranch.name = [newLight.name(1:end-1), 'B'];
                    thisR.set('asset', 1, 'add', defaultBranch);

                    % Put the light under the geometry branch.
                    thisR.set('asset', defaultBranch.name, 'add', newLightAsset);
                elseif iscell(newLight)
                    for ii=1:numel(newLight)
                        thisR.set('light', newLight{ii}, 'add');
                    end
                end
                return;
            case {'delete', 'remove'}
                % thisR.set('light', lightName, 'delete');
                if isequal(lghtName, 'all')
                    lgtNames = thisR.get('light', 'names');
                    for ii=1:numel(lgtNames)
                        thisR.set('asset', lgtNames{ii}, 'delete');
                    end
                else
                    thisR.set('asset', lghtName, 'delete');
                end
                return;
            case 'replace'
                % thisR.set('light', lightName, 'replace', newLight);
                %
                % The light asset has a type, name and struct called
                % lght{1}.
                oldLight = thisR.get('light', lghtName);

                % Sometimes newLight is the light asset with the
                % subfield lght.  Sometimes it is just the subfield
                % lght.
                if ~isfield(val,'lght')
                    newLight = oldLight;
                    % newLight is just the subfield
                    newLight.lght{1} = val;
                    % Make sure the name has the _L
                    newLight.lght{1}.name = piLightNameFormat(val.name);
                else
                    newLight = val;
                end

                % Assign but make sure the ID (names) are OK.
                thisR.set('asset', lghtName, newLight);
                thisR.assets.uniqueNames;
                return;

            case {'worldrotation', 'worldrotate'}
                thisR.set('asset', lghtName, 'world rotation', val);
                return;
            case {'worldtranslation', 'worldtranslate'}
                % Shouldn't be applied to infinite light but could be for
                % area light.
                thisR.set('asset', lghtName, 'world translation', val);
                return;
            case {'worldposition'}
                thisR.set('asset', lghtName, 'world position', val);
                return;
            case {'worldorientation'}
                thisR.set('asset', lghtName, 'world orientation', val);
                return;
            case {'shapescale'}
                % thisR.set('light',name,'shape scale',1 or 3 vector)
                %
                % Find the node and add a scale to the branch node
                % above the light.
                %
                id = thisR.get('node',lghtName,'id');
                thisR.set('node',id,'scale',val);
                return;

            case {'rotate', 'rotation'}
                % Rotate the direction, angle in degrees
                % We should use the same approach as for shapescale.
                % thisR.set('light', lghtName, 'rotate', [XROT, YROT, ZROT], ORDER)
                % See piLightRotate
                lghtAsset = thisR.get('light', lghtName);
                lght = lghtAsset.lght{1};

                % If the light (asset) has no from field, then the
                % transformation will be applied to the branch node.  This
                % applies to  the skymap (infinite, environment) and area
                % light.
                if ~isfield(lght, 'from')
                    thisR.set('asset', lghtName, 'rotate', val);
                    return;
                end

                % It has a 'from' field so we apply a real rotation.  The
                % parameters specify the amount of the rotation and the
                % order of w.r.t X,Y,Z
                if numel(varargin) == 2
                    % The 2nd varargin is the rotation in deg of X,Y,Z
                    xRot = varargin{2}(1);
                    yRot = varargin{2}(2);
                    zRot = varargin{2}(3);
                end
                if numel(varargin) == 3
                    % The 3rd varargin specifies the order of the rotations
                    % of X, Y, and Z. Default is below.
                    order = varargin{3};
                else
                    order = ['x', 'y', 'z'];
                end

                lght = piLightRotate(lght, 'xrot', xRot,...
                    'yrot', yRot,...
                    'zrot', zRot,...
                    'order', order);
                thisR.set('asset', lghtName, 'lght', lght);
                return;
            case {'translate', 'translation'}
                % thisR.set('light', lghtName, 'translate', [xShift, yShift, zShift], FROMTO)
                % See piLightTranslate
                %
                lghtAsset = thisR.get('light', lghtName);
                lght = lghtAsset.lght{1};

                % If it has no from field, then the transformation will
                % be applied to the branch node (for infinite and area
                % light). An area light has no from field, for
                % example.
                if ~isfield(lght, 'from')
                    % No 'from' field.  So translate with the branch.
                    thisR.set('asset', lghtName, 'translate', varargin{2});
                    return;
                end

                % This light has a 'from' field.  Here is the shift.
                if numel(varargin) == 2
                    xSft = varargin{2}(1);
                    ySft = varargin{2}(2);
                    zSft = varargin{2}(3);
                end

                if numel(varargin) == 3, fromto = varargin{3};
                else,                    fromto = 'both';
                end
                up = thisR.get('up');

                % If the light is at the same position of camera
                if lght.cameracoordinate
                    if isfield(lght, 'from')
                        lght = piLightSet(lght, 'from val', thisR.get('from'));
                    end
                    if isfield(lght, 'to')
                        lght = piLightSet(lght, 'to val', thisR.get('to'));
                    end
                end
                lght = piLightTranslate(lght, ...
                    'xshift', xSft,...
                    'yshift', ySft,...
                    'zshift', zSft,...
                    'fromto', fromto,...
                    'up', up);
                thisR.set('asset', lghtName, 'lght', lght);
                return;
            otherwise
                % Probably the light name. Just get the light.
                thisLightAsset = thisR.get('light', lghtName);
                thisLight = thisLightAsset.lght{1};
        end

        % At this point we have the light.
        if numel(varargin{1}) == 1
            % thisR.set('light', lghtName, lightStruct);
            %
            % A light struct was sent in as the only argument.  We
            % should check it, make sure its name is unique, and then set
            % it. We are not checking enough.
            thisR.set('light', lghtName, 'replace', varargin{1});
        else
            % thisR.set('light', lightName, param, val)
            % A light name and property was sent in.  We set the
            % property and then update the material in the list.
            thisLight = piLightSet(thisLight, param, val);
            thisR.set('light', lghtName, 'replace', thisLight);
            if isequal(param,'name')
                % There are two places where light names are stored.
                % We keep them the same, which is goofy.  But there is
                % it is for now.
                thisR.set('asset',lghtName,'name',val);
            end
        end

    case {'asset', 'assets','node','nodes'}
        % Typical:    thisR.set(param,val)
        % This case:  thisR.set('asset',assetNameOrID, param, val);
        %          or thisR.set('asset', assetName/assetStruct, action);
        %          or thisR.set('asset', assetName, action, val);
        %
        % These operations need the whole tree, so we send in the
        % recipe that contains the asset tree, thisR.assets.

        % We are slowly starting to call nodes nodes, rather than
        % assets.  We think of an asset now as, say, a car with all of
        % its parts.  A node is the node in a tree that contains
        % multiple assets. (BW, Sept 2021).

        % Given the calling convention, val is assetName and
        % varargin{1} is the param, and varargin{2} is the param
        % value, if needed.
        if isnumeric(val)
            % Person sent in an id, so we get the name here
            [id,thisAsset] = piAssetFind(thisR,'id',val);
            if val == 1, assetName = 'root';
            else, assetName = thisAsset{1}.name;
            end
        else
            % Person send in a name, so we get the id here
            assetName = val;
            id = thisR.get('asset', assetName, 'id');
        end
        param = varargin{1};
        % If only one element in varargin, it should be a node struct.
        if numel(varargin) == 1 && ~ischar(varargin{1})
            thisR.assets = thisR.assets.set(id, varargin{1});
            out = varargin{1};
            thisR.assets = thisR.assets.uniqueNames;
            return;
        end
        % Else we are setting a parameter value
        if numel(varargin) == 2, val   = varargin{2}; end

        % Some of these functions should be edited to return the new
        % branch.  Some have been.
        switch ieParamFormat(param)
            case 'add'
                % thisR.set('asset',parentName,newAsset);
                out = piAssetAdd(thisR, assetName, val);
            case {'cancellasttransformation', 'removelasttransformation',...
                    'cancellasttrans', 'removelasttrans',...
                    'cancellastaction', 'removelastaction'}
                % Note: this is for transformation only, not
                % motion/animation
                piAssetRemoveLastTrans(thisR, assetName);
            case {'clearmotion', 'removemotion', 'cancelmotion'}
                piAssetSet(thisR, assetName, 'motion', []);
            case {'delete', 'remove'}
                % thisR.set('asset',assetName,'delete');
                % Do we need an 'all' option?
                piAssetDelete(thisR, assetName);
            case {'insert'}
                % thisR.set('asset',assetName,'insert');
                out = piAssetInsert(thisR, assetName, val);
            case {'parent'}
                % thisR.set('asset',assetName,'parent',id)
                piAssetSetParent(thisR, assetName, val);
            case {'translate', 'translation'}
                % thisR.set('asset',assetName,'translate',val);
                out = piAssetTranslate(thisR, assetName, val);
            case {'worldtranslate', 'worldtranslation'}
                % Translate in world axis orientation.
                rotM = thisR.get('asset', assetName, 'world rotation matrix'); % Get new axis orientation
                % newTrans = inv(rotM) * [reshape(val, numel(val), 1); 0];
                newTrans = rotM \ [reshape(val, numel(val), 1); 0];

                % Get the scale
                worldScale = thisR.get('asset', assetName, 'world scale');
                out = piAssetTranslate(thisR, assetName, newTrans(1:3)./worldScale(:));
            case {'rotate', 'rotation'}
                % Figures out the rotation from the angles in val and sets
                % the rotation matrix
                % val
                out = piAssetRotate(thisR, assetName, val);
            case {'rotationmatrix'}
                % Just set the rotation matrix
                % id = piAssetFind(thisR.assets,'name',assetName);
                % Check that val is a rotation matrix
                if size(val) == [4,4]
                    piAssetSet(thisR, assetName, 'rotation',val);
                else
                    error('val must be 4x4 matrix');
                end
            case {'size'}
                % thisR.set('asset',assetID-Name,'size',[x y z meters]);
                % Change the size of the asset (x,y,z) in meters

                % Get the current size, and then use scale to make a new
                % size.
                curSize = thisR.get('asset',assetName,'size');
                thisR.set('asset',assetName,'scale',val./curSize);

            case {'worldrotate', 'worldrotation'}
                % thisR.set('asset','assetID,'world rotate',vecDeg)
                %
                % Change the rotation in the world space

                % Get current rotation matrix
                curRotM = thisR.get('asset', assetName, 'world rotation matrix');

                % Compute new axis rotation (orientation)
                [~, rotDeg] = piTransformRotationInAbsSpace(val, curRotM);

                % Set the rotation parameter PBRT will use
                out = thisR.set('asset', assetName, 'rotate', rotDeg);

            case {'worldorientation'}
                % curRot = thisR.get('asset', assetName, 'worldrotationangle');
                curM = thisR.get('asset', assetName, 'worldrotationmatrix');
                invDeg = piTransformRotM2Degs(inv(curM));
                thisR.set('asset', assetName, 'world rotation', invDeg);
                thisR.set('asset', assetName, 'world rotation', val(:)');
            case {'worldposition'}
                % thisR.set('asset', assetName, 'world position', [1 2 3]);

                % Find the translation value, which is the difference
                % between the current position and the desired
                % position.
                pos = thisR.get('asset', assetName, 'world position');
                translation = -pos + varargin{2}(:)';
                [~, out] = thisR.set('asset', assetName, 'translation', translation);
            case {'scale'}
                out = piAssetScale(thisR,assetName,val);
            case {'move', 'motion'}
                % varargin{2:end} contains translation and rotation info
                out = piAssetMotionAdd(thisR, assetName, varargin{2:end});
            case {'obj2light'}
                piAssetObject2Light(thisR, assetName, val);
            case {'graft', 'subtreeadd'}
                % thisR.set('asset',nodeForGraft,'graft',subtree);
                id = thisR.get('node', assetName, 'id');
                rootSTID = thisR.assets.nnodes + 1;
                thisR.assets = thisR.assets.graft(id, val);
                thisR.assets = thisR.assets.uniqueNames;
                % Get the root node of the subtree.
                out = thisR.get('asset', rootSTID);
            case {'graftwithmaterial', 'graftwithmaterials'}
                % thisR.set('asset',assetName,'graft with materials',assetFileName)
                [assetTree, matList] = piAssetTreeLoad(val);
                [~,out] = thisR.set('asset', assetName, 'graft', assetTree);
                keyList = keys(matList);
                for ii=1:numel(keyList)
                    thisR.set('material', 'add', matList(keyList{ii}));
                end
            case {'mergebranches'}
                % thisR.set('asset',assetName,'merge branches');
                %
                % Merge the branches above an object to the root_B branch.
                % This is applied to older recipes that come have the older
                % style multiple branches.  In the newer format, we have an
                % object and only one geometry branch above it.
                %

                % Find the world positions.  We will set the branch
                % node of this object or light so these values.
                wpos    = thisR.get('asset',assetName,'world position');
                wscale  = thisR.get('asset',assetName,'world scale');
                wrotate = thisR.get('asset',assetName,'world rotation angle');

                % Find the indices to root from this object or light.
                id = thisR.get('asset',assetName,'path to root');
                for ii=2:numel(id)
                    thisR.set('asset',id(ii),'delete');
                end

                % There should be only one id.
                id = thisR.get('asset',assetName,'path to root');
                if (numel(id)-1 == 0)
                    % Adding a geometry node above the object but
                    % below the root node
                    geometryNode = piAssetCreate('type','branch');

                    % Branch name is object or light name with _B replaced
                    % This could be switch on asset type.
                    geometryNode.name = strrep(assetName,'_O','_B');
                    geometryNode.name = strrep(assetName,'_L','_B');

                    % Branch is underneath root_B
                    thisR.set('asset','root_B','add',geometryNode);
                    thisR.set('asset',assetName,'parent',geometryNode.name);
                end

                % Set the position and other parameters.
                piAssetSet(thisR, geometryNode.name, 'translate',wpos);
                piAssetSet(thisR, geometryNode.name, 'scale',wscale);

                % rotMatrix = [wrotate; fliplr(eye(3))];
                % piAssetSet(thisR, geometryNode.name, 'rotation', rotMatrix);

                thisR.set('asset',geometryNode.name,'world rotation',wrotate);

            case {'subtreedelete','chop', 'cut'}
                % thisR.set('asset',id,'subtree delete');
                %
                % Delete all the node and its subtree
                id = thisR.get('asset', assetName, 'id');
                thisR.assets = thisR.assets.chop(id);
                thisR.assets = thisR.assets.uniqueNames;
            otherwise
                % Set a parameter of an asset to val
                % rotation is a parameter, but it is stopped above via the
                % call to rotation matrix.
                piAssetSet(thisR, assetName, varargin{1},val);
        end
        % reassign unique names for delete/chop;
        thisR.assets = thisR.assets.uniqueNames;

        % ZLY added fluorescent sets
    case {'fluorophoreconcentration'}
        % thisR.set('fluorophore concentration',val,idx)
        if isempty(varargin), error('Material name or index required'); end

        % material name
        materialName = varargin{1};

        matName = val; % for older version
        switch thisR.recipeVer
            case 2
                % A modern recipe. So we set using modern methods.  The
                % function reads the fluorophore (fluorophoreRead) and
                % returns the EEM and sets it.  It uses the wavelength
                % sampling in the recipe to determine the EEM wavelength
                % sampling.
                thisR = piMaterialSet(thisR,materialName,'fluorophore concentration',val);

            otherwise
                % This is the original framing, before re-writing the
                % materials.list organization by Zheng.
                disp('Please update to version 2 of the recipe');
                disp('This will be deprecated');
                if ~isfield(thisR.materials.list, matName)
                    error('Unknown material name %s\n', matName);
                end
                thisR.materials.list.(matName).floatconcentration = val;
        end
    case {'fluorophoreeem'}
        % thisR.set('fluorophore eem',val,idx)
        %
        % val - the name of the fluorophore.
        % idx - a numerical index to the material or it can be a string
        % which is the name of the mater
        if isempty(varargin), error('Material name or index required'); end

        % material name
        materialName = varargin{1};

        matName = val;
        switch thisR.recipeVer
            case 2
                % A modern recipe. So we set using modern methods.  The
                % function reads the fluorophore (fluorophoreRead) and
                % returns the EEM and sets it.  It uses the wavelength
                % sampling in the recipe to determine the EEM wavelength
                % sampling.
                thisR = piMaterialSet(thisR,materialName,'fluorophore eem',val);

            otherwise
                % This is the original framing, before re-writing the
                % materials.list organization by Zheng.
                disp('Please update to version 2 of the recipe');
                disp('This will be deprecated');
                if ~isfield(thisR.materials.list, matName)
                    error('Unknown material name %s\n', matName);
                end
                if length(val) == 1
                    error('Donaldson matrix is empty\n');
                end
                if length(varargin) > 2
                    error('Accept only one Donaldson matrix\n');
                end

                fluorophoresName = val{2};
                if isempty(fluorophoresName)
                    thisR.materials.list.(matName).photolumifluorescence = '';
                    thisR.materials.list.(matName).floatconcentration = [];
                else
                    wave = 365:5:705; % By default it is the wavelength range used in pbrt
                    fluorophores = fluorophoreRead(fluorophoresName,'wave',wave);
                    % Here is the excitation emission matrix
                    eem = fluorophoreGet(fluorophores,'eem');
                    %{
                       fluorophorePlot(Porphyrins,'donaldson mesh');
                    %}
                    %{
                       dWave = fluorophoreGet(FAD,'delta wave');
                       wave = fluorophoreGet(FAD,'wave');
                       ex = fluorophoreGet(FAD,'excitation');
                       ieNewGraphWin;
                       plot(wave,sum(eem)/dWave,'k--',wave,ex/max(ex(:)),'r:')
                    %}

                    % The data are converted to a vector like this
                    flatEEM = eem';
                    vec = [wave(1) wave(2)-wave(1) wave(end) flatEEM(:)'];
                    thisR.materials.list.(matName).photolumifluorescence = vec;
                end
        end
    case {'concentration'}
        matName = val{1};
        if ~isfield(thisR.materials.list, matName)
            error('Unknown material name %s\n', matName);
        end
        if length(val) == 1
            error('Concentration is empty\n');
        end
        if length(val) > 2
            error('Accept single number as concentration\n');
        end
        thisR.materials.list.(matName).floatconcentration = val{2};
    case {'rendertype','filmrendertype'}
        % piRender(thisR,'render type',{list of types});
        % piRender(thisR,'render type',{'radiance','depth','instance'});
        thisR.metadata.rendertype = val;
        for ii = 1:numel(val)
            switch val{ii}
                case 'radiance'
                    thisR.film.saveRadiance.type  = 'bool';
                    thisR.film.saveRadiance.value = true;
                    thisR.film.saveRadianceAsBasis.type  = 'bool';
                    thisR.film.saveRadianceAsBasis.value =false;
                case 'radiancebasis'
                    thisR.film.saveRadianceAsBasis.type  = 'bool';
                    thisR.film.saveRadianceAsBasis.value = true;
                    thisR.film.saveRadiance.type  = 'bool';
                    thisR.film.saveRadiance.value = false;
                case 'depth'
                    % depth
                    thisR.film.saveDepth.type  = 'bool';
                    thisR.film.saveDepth.value = true;
                    % Added for gbuffer in pbrt-v4
                case 'normal'
                    thisR.film.saveNormal.type  = 'bool';
                    thisR.film.saveNormal.value = true;
                case 'albedo'
                    thisR.film.saveAlbedo.type  = 'bool';
                    thisR.film.saveAlbedo.value = true;
                case 'material'
                    thisR.film.saveMaterial.type  = 'bool';
                    thisR.film.saveMaterial.value = true;
                case 'instance'
                    thisR.film.saveInstance.type  = 'bool';
                    thisR.film.saveInstance.value = true;
                case 'illuminance'
                    illumR = piRecipeCopy(thisR);
                    illumR.film.saveRadiance.type  = 'bool';
                    illumR.film.saveRadiance.value = true;
                    illumR.film.saveRadianceAsBasis.type  = 'bool';
                    illumR.film.saveRadianceAsBasis.value =false;
                    % using radiance render type, but modify material
                    matList = keys(illumR.materials.list);
                    for jj = 1: numel(matList)
                        thisMat = illumR.materials.list(matList{jj});
                        thisMat.reflectance.type = 'spectrum';
                        thisMat.reflectance.value = [300 1 800 1];
                        illumR.materials.list(matList{jj}) = thisMat;
                    end

                    [dir, fname, ext]=fileparts(thisR.outputFile);
                    illumR.outputFile = fullfile(dir, [fname,'_illuminance',ext]);
                    thisR.metadata.illuminanceRecipe = illumR;
            end
        end
    otherwise
        error('Unknown parameter %s\n',param);
end

end
