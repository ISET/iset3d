function val = recipeGet(thisR, param, varargin)
% Derive parameters from the recipe class
%
% Syntax:
%     val = recipeGet(thisR, param, ...)
%
% Inputs:
%     thisR - a recipe object
%     param - a parameter (string)
%
% Returns
%     val - Stored or derived parameter from the recipe
%
% Parameters
%
%    % Data management
%    % The input files are the original PBRT files
%     'input file'        - full path to original scene pbrt file
%     'input basename'    - just base name of input file
%     'input dir'         - Directory of the input file
%
%    % The output files are the modified PBRT files after modifications to the
%    % parameters in ISET3d
%     'output file'       - full path to scene pbrt file in working directory
%     'output basename'   - base name of the output file
%     'output dir'        - Directory of the output file
%
%    % The rendered files are the output of PBRT, which starts with the
%    % output files
%     'rendered file'     - dat-file where piRender creates the radiance
%     'rendered dir'      - directory with rendered data
%     'rendered basename' - basename of rendered dat-file
%
%    % Scene properties
%     'exporter'  - Where the scene came from
%     'mm units'  - Some scenes were given to us in mm, rathern m, units
%     'depth range'      - Depth range of the scene elements given the
%                          camera position (m)
%
%   % Camera, scene and film
%    % There are several types of cameras: pinhole, realistic,
%    % realisticDiffraction, realisticEye, and omni.  The camera parameters
%    % are stored in the 'camera' and 'film' slots.  There are also some
%    % parameters that define the camera location, what it is pointed at in
%    % the World and motion
%     'camera'           - The whole camera struct
%     'camera type'      - Always 'camera'
%     'camera subtype'   - Valid camera subtypes are {'omni','pinhole', ...}
%     'camera body'
%     'optics type'      - Translates camera sub type into one of
%                          'pinhole', 'envronment', or 'lens'
%     'lens file'        - Name of lens file in data/lens
%     'focal distance'   - See autofocus calculation (mm)
%     'pupil diameter'   - In millimeters
%     'fov'              - (Field of view) Used if 'optics type' is
%                          'pinhole' or 'realisticEye' or ..???
%    % PBRT allows us to specify camera translations.  Here are the
%    % parameters
%     'camera motion start' - Start position in the World
%     'camera motion end'   - End position in the World
%     'camera exposure'     - Time (sec)
%     'camera motion translate' - Difference in position (Start - End)
%
%    % The relationship between the camera and objects in the World are
%    % specified by these parameters
%     'object distance'  - The magnitude ||(from - to)|| of the difference
%                          between from and to.  Units are from the scene,
%                          typically in meters.
%     'lookat direction' - Unit length vector of from and to
%     'look at'          - Struct with four components
%        'from'           - Camera location
%        'to'             - Camera points at
%        'up'             - Direction that is 'up'
%        'from to'        - vector difference (from - to)
%        'to from'        - vector difference (to - from)
%
%    % Lens
%      'lens file'
%      'lens dir input'
%      'lens dir output'
%      'lens basename'      - No extension
%      'lens full basename' - With extension
%      'focus distance'     - Distance to in-focus plane  (m)
%      'focal distance'     - Used with pinhole, which has infinite depth
%                             of field, to specify the distance from the
%                             pinhole and film
%      'accommodation'      - Inverse of focus distance (diopters)
%      'fov'                - Field of view (deg)
%      'aperture diameter'   - For most cameras, but not human eye
%      'pupil diameter'      - For realisticEye.  Zero for pinhole
%      'diffraction'         - Enabled or not
%      'chromatic aberraton' - Enabled or not
%      'num ca bands'        - Number of chromatic aberration spectral bands
%
%    % Film and retina
%      'film subtype'
%      'film distance'      - PBRT adjusts the film distance so that an
%                             object at the focus distance is in focus.
%                             This is that distance. If a pinhole, it might
%                             just exist as a parameter.  If it doesn't
%                             exist, then we use the film size to and FOV
%                             to figure out what it must be.
%      'spatial samples'    - Number of row and col samples
%      'film x resolution'  - Number of x dimension samples
%      'film y resolution'  - Number of y-dimension samples
%      'sample spacing'     - Spacing between row and col samples
%      'film diagonal'      - Size in mm
%
%
%      % Special retinal properties for human eye models
%      'retina distance'
%      'eye radius'
%      'retina semidiam'
%      'center 2 chord'
%      'lens 2 chord'
%      'ior1','ior2','ior3','ior4' - Index of refraction slots for Navarro
%                                    eye model
%
%    % Light field camera parameters
%     'n microlens'      - 2-vector, row,col (alias 'n pinholes')
%     'n subpixels'      - 2 vector, row,col
%
%    % Properties of how PBRT does the rendering
%      'render type'   -  Cell array indicating 'radiance','depth', ...
%      'integrator'
%      'rays per pixel'
%      'n bounces'
%      'crop window'
%      'integrator subtype'
%      'nwavebands'
%
%    % Asset information
%       'assets'      - This struct includes the objects and their
%                       properties in the World
%       'asset names'
%       'asset id'
%       'asset root'
%       'asset names'
%       'asset parent id'
%       'asset parent'
%       'asset list'  - a list of branches.
%
%    % Material information
%      'materials'
%      'materials output file'
%
%    % Textures
%      'texture'
%
%    % Lighting information
%      'light'
%
%
% BW, ISETBIO Team, 2017

% Examples
%{
  thisR = piRecipeDefault('scene name','SimpleScene');
  thisR.get('working directory')
  thisR.get('object distance')
  thisR.get('focal distance')
  thisR.get('camera type')
  thisR.get('lens file')

  thisR.get('asset names')       % The call should be the same!
  thisR.get('materials','names');
  thisR.get('textures','names')
  thisR.get('light','names')

%}

% Programming todo
%   * Lots of gets needed for the assets, materials, lighting, ...
%

%% Parameters

if isequal(param,'help')
    doc('recipe.recipeGet');
    return;
end

p = inputParser;
vFunc = @(x)(isequal(class(x),'recipe'));
p.addRequired('thisR',vFunc);
p.addRequired('param',@ischar);

p.parse(thisR,param);

val = [];

%%

switch ieParamFormat(param)  % lower case, no spaces

    % File management
    case 'inputfile'
        % The place where the PBRT scene files start before being modified
        val = thisR.inputFile;
    case 'inputdir'
        val = fileparts(thisR.get('input file'));
    case {'inputbasename'}
        name = thisR.inputFile;
        [~,val] = fileparts(name);
    case 'outputfile'
        % This file location defines the working directory that docker
        % mounts to run.
        val = thisR.outputFile;
    case {'outputdir','workingdirectory','dockerdirectory'}
        val = fileparts(thisR.get('output file'));
    case {'outputbasename'}
        name = thisR.outputFile;
        [~,val] = fileparts(name);
    case 'renderedfile'
        % We store the renderings in a 'renderings' directory within the
        % output directory.
        rdir = thisR.get('rendered dir');
        outputFile = thisR.get('output basename');
        val = fullfile(rdir,[outputFile,'.dat']);
    case {'rendereddir'}
        outDir = thisR.get('output dir');
        val = fullfile(outDir,'renderings');
    case {'renderedbasename'}
        val = thisR.get('output basename');
    case {'inputmaterialsfile','materialsfile'}
        % Stored in the root of the input directory
        n = thisR.get('input basename');
        p = thisR.get('input dir');
        fname_materials = sprintf('%s_materials.pbrt',n);
        val = fullfile(p,fname_materials);
    case {'geometrydir','outputgeometrydir'}
        % Standard location for the scene geometry output information
        outputDir = thisR.get('output dir');
        val = fullfile(outputDir,'geometry');

        % Graphics related
    case {'exporter'}
        % 'C4D' or 'Unknown' or 'Copy' at present.
        val = thisR.exporter;
    case 'mmunits'
        % thisR.get('mm units',true/false)
        %
        % Indicates whether the PBRT scene representation is in millimeter
        % units.  Typically, it is not - it is in 'meters'.  The value is
        % stored as a string because PBRT reads it that way.  We might
        % choose to return true/false some day.
        val = 'false';
        if isfield(thisR.camera,'mmUnits')
            % val is true, so we are in millimeter units
            val = thisR.camera.mmUnits.value;
        end
        % Scene and camera direction
    case {'transformtimes'}
        val = thisR.transformTimes;
    case {'transformtimesstart'}
        if isfield(thisR.transformTimes, 'strat')
            val = thisR.transformTimes.start;
        else
            val = [];
        end
    case {'transformtimesend'}
        if isfield(thisR.transformTimes, 'end')
            val = thisR.transformTimes.end;
        else
            val = [];
        end
    case {'fromtodistance','objectdistance'}
        % thisR.get('fromto distance',units)
        diff = thisR.lookAt.from - thisR.lookAt.to;
        val = sqrt(sum(diff.^2));
        % Spatial scale
        if ~isempty(varargin)
            val = val*ieUnitScaleFactor(varargin{1});
        end

    case {'lookatdirection','objectdirection'}
        % A unit vector in the lookAt direction
        %   This vector is v = 'to' - 'from',
        %   so  v + 'from' = 'to'
        val = thisR.lookAt.to - thisR.lookAt.from;
        val = val/norm(val);
    case {'rendertype','filmrendertype'}
        % A cell array of the radiance and other metadata types
        val = thisR.metadata.rendertype;

        % Camera fields
    case {'camera'}
        % The whole struct
        val = thisR.camera;
    case {'cameratype'}
        % This is always 'Camera'
        val = thisR.camera.type;
    case {'cameramodel','camerasubtype'}
        % thisR.get('camera subtype') This is type of camera.  The type
        % slot stores camera and the subtype stores the camera type. It may
        % be perspective, pinhole, realisticEye, humaneye, omni, realistic,
        % environment.
        if isfield(thisR.camera,'subtype'), val = lower(thisR.camera.subtype);
        else, error('No camera subtype specified.')
        end

        % Enforcing perspective rather than pinhole and 
        % humaneye rather than realisticeye
        if isequal(val,'perspective'), val = 'pinhole';
        elseif isequal(val,'realisticeye'), val = 'humaneye';
        end

    case 'lookat'
        val = thisR.lookAt;
    case {'from','cameraposition'}
        val = thisR.lookAt.from;
    case 'to'
        val = thisR.lookAt.to;
    case 'up'
        val = thisR.lookAt.up;
    case 'tofrom'
        % Changed this July 29.  Hopefully this is not a big breaking
        % change.  See BW/ZLY
        % Vector that starts at 'to' pointing towards 'from'  
        val = thisR.lookAt.from - thisR.lookAt.to;
    case 'fromto'
        % Vector that starts at 'from' pointing towards 'to'
        val = thisR.lookAt.to - thisR.lookAt.from;
    case {'scale'}
        % Change the size (scale) of something.  Almost always 1 1 1
        val = thisR.scale;

        % Motion is not always included.  When it is, there is a start and
        % end position, and a start and end rotation.
    case {'cameramotiontranslate'}
        % This is the difference between start and end
        if isfield(thisR.camera,'motion')
            val = thisR.camera.motion.activeTransformStart.pos - thisR.camera.motion.activeTransformEnd.pos;
        end
    case {'cameramotiontranslatestart'}
        % Start position
        if isfield(thisR.camera,'motion')
            val = thisR.camera.motion.activeTransformStart.pos ;
        end
    case {'cameramotiontranslateend'}
        % End position
        if isfield(thisR.camera,'motion')
            val =  thisR.camera.motion.activeTransformEnd.pos;
        end
    case {'cameramotionrotationstart'}
        % Start rotation
        if isfield(thisR.camera,'motion')
            val = thisR.camera.motion.activeTransformStart.rotate;
        end
    case {'cameramotionrotationend'}
        % End rotation
        if isfield(thisR.camera,'motion')
            val = thisR.camera.motion.activeTransformEnd.rotate;
        end
    case {'exposuretime','cameraexposure'}
        try
            val = thisR.camera.shutterclose.value - thisR.camera.shutteropen.value;
        catch
            val = 1;  % 1 sec is the default.  Too long.
        end
    case {'shutteropen'}
        % thisR.get('shutter open');   % Time in sec
        try
            val = thisR.camera.shutteropen.value;
        catch
            val = 0;
        end

    case {'shutterclose'}
        % thisR.get('shutter close');  % Time in sec
        % When not set, the exposure duration is 1 sec and open,close are
        % [0,1]
        try
            val = thisR.camera.shutterclose.value;
        catch
            val = 1;
        end

        % Lens and optics
    case 'opticstype'
        % val = thisR.get('optics type');
        %
        % This collapses the camera models, which tells us more, into lens
        % and pinhole.  I have no idea what 'environment' is, but
        % apparently that is something that can get returned here.
        %
        % perspective means pinhole.  I am trying to get rid of perspective
        % as a subtype (BW).
        %
        % See 'camera model' for more information about the subtypes of
        % cameras. 
        val = thisR.get('camera subtype');

        % These get counted as 'lens' type optics.  pinhole and environment
        % are the other options.
        if ismember(val,{'realisticdiffraction','humaneye','realistic','omni','raytransfer'})
            val = 'lens';
        end

    case {'humaneyemodel','realisticeyemodel'}
        % Which humanEye (realisticEye) model.  Over time we will figure
        % out how to identify them in a better way. For example, we might
        % insert a slot in the recipe with the label when we create the
        % model.  For now, it is the lensfile name.
        subType = thisR.get('camera subtype');
        if isequal(subType,'humaneye')
            if contains(thisR.get('lensfile'),'navarro')
                val = 'navarro';
            elseif contains(thisR.get('lensfile'),'legrand')
                val = 'legrand';
            elseif contains(thisR.get('lensfile'),'arizona')
                val = 'arizona';
            end
        else
            val = [];
        end

    case {'lensfile','lensfileinput'}
        % The lens file should be in the isetcam/data/lens directory.

        % There are a few different camera types.  Not all have lens files.
        subType = thisR.get('camera subtype');
        switch(lower(subType))
            case 'pinhole'
                val = 'pinhole';
                % There are no lenses for pinhole/perspective
            case 'perspective'
                % There are no lenses for pinhole/perspective
                val = 'pinhole (perspective)';
            case 'humaneye'
                % This will be navarro.dat or one of the other models,
                % usually.
                val = thisR.camera.lensfile.value;
            otherwise
                % I think this is used by omni, particularly for microlens
                % cases.  We might do something about putting the microlens
                % examples in the data/lens directory and avoiding this
                % problem.

                % Make sure the lensfile is in the isetcam/data/lens directory.
                
                if isfield(thisR.camera,'lensfile') 
                    % We expect the lens file will be in
                    % isetcam/data/lens. But there are some cases,
                    % such as microlens calculations, when it may not
                    % be there, but rather in local.  If the first
                    % character is a / we suppose the person knows
                    % what they are doing and we accept the full path.
                    lensfile = thisR.camera.lensfile.value;
                    if strncmp(lensfile,'/',1)
                        % Full path case.  Worried that I didn't
                        % handle the Windows case correctly (BW).
                        if isfile(lensfile)
                            val = lensfile;
                        end
                    else
                        % Not a full path, so look in the default
                        % directory.
                        [~,name,ext] = fileparts(lensfile);
                        baseName = [name,ext];

                        % Check it is there.
                        val = fullfile(piDirGet('lens'),baseName);
                        if ~exist(val,'file')
                            error('Cannot find the lens file %s in isetcam/data/lens.\n',baseName);
                        end
                    end
                end
        end
    case {'lensdir','lensdirinput'}
        % This is the directory where the lens files are kept, not the
        % directory unique to this recipe. We copy the lens files from this
        % directory, usually.  There are some complications for navarro and
        % the realisticEye human models.
        val = piDirGet('lens');
    case 'lensdiroutput'
        % Directory where we are stsring the lens file for rendering
        val = fullfile(thisR.get('outputdir'),'lens');
    case 'lensbasename'
        % Just the name, like fisheye
        val = thisR.get('lens file');
        [~,val,~] = fileparts(val);
    case 'lensfullbasename'
        % the base name plus the extension fisheye.dat
        val = thisR.get('lens file');
        [~,val,ext] = fileparts(val);
        val = [val,ext];
    case 'lensfileoutput'
        % The full path to the file in the output area where the lens
        % file is kept
        outputDir = thisR.get('outputdir');
        lensfullbasename = thisR.get('lens full basename');
        val = fullfile(outputDir,'lens',lensfullbasename);
    case 'lensaccommodation'
        % Some eye models have an accommodation value for the
        % lens/cornea.  The retina distance is held fixed, and
        % accommodation is achieved by rebuilding the eye model.
        %
        % For typical lenses (not eye models) the accommodation refers
        % to the 1/focal distance.  So people say that a simple lens
        % is accommodated to a focal distance and its accommodation is
        % the inverse of that distance.
        %
        % We used to insert the accommodation in the name of the lens
        % file. Nov 2022 I took this approach (BW).

        if isequal(thisR.get('camera subtype'),'humaneye')
            % If it is a human eye model do this

            % Read the lens file
            txtLines = piReadText(thisR.get('lensfile'));

            % Find the text that has '(Diopters)' in it.  Normally this is
            % line 10 in the lens file.
            tmp = strfind(txtLines,'s)');

            for ii=1:numel(tmp)
                if ~isempty(tmp{ii})
                    thisLine = txtLines{ii};  % Should be line 10
                    % Find the string beyond Diopters and return it
                    val = str2double(thisLine((tmp{ii}+2):end)); % ,'%f')
                    return;
                end
            end
        else
            % For typical lenses people call the accommodation the
            % inverse of the focal distance.
            val = 1 / thisR.get('focal distance');
        end


    case {'focusdistance','focaldistance'}
        % Distance in object space that is in focus on the film. If the
        % camera model has a lens, we check whether the lens can bring this
        % distance into focus on the film plane.
        %
        %   recipe.get('focal distance')  (m)
        %
        % N.B.  The phrasing can be confusing.  This is the distance to the
        %       plane in OBJECT space that is in focus. This can be easily
        %       confused the the lens' focal length - which is a different
        %       thing!
        %
        %       In PBRT parlance this is stored differently depending on
        %       the camera model.
        %
        %       For pinhole this is stored as focal distance.
        %       For lens, this stored as focus distance.
        %
        opticsType = thisR.get('optics type');
        switch opticsType
            case {'pinhole', 'perspective'}
                % Everything is in focus for a pinhole camera.  For
                % pinholes this is focaldistance.  But not for omni.
                disp('No true focal distance for pinhole. This value is arbitrary');
                if isfield(thisR.camera,'focaldistance')
                    val = thisR.camera.focaldistance.value;
                end
            case {'environment'}
                % Everything is in focus for the panorama
                disp('Panorama rendering. No focal distance');
                val = NaN;
            case 'lens'

                % Distance to the in-focus object. 
                switch thisR.get('camera subtype')
                    case {'humaneye'}
                        % For the human eye, this is built into the
                        % definition (accommodation) of the lens model
                        val = 1/thisR.get('accommodation');                        
                    otherwise
                        % For other types of lenses this can be set, and
                        % PBRT adjusts the film distance to achieve this.
                        val = thisR.camera.focusdistance.value; % Meters
                end

                % If the isetlens repository is on the path, we convert the
                % distance to the focal plane into millimeters and warn if
                % there is no film distance that will bring the object into
                % focus.
                if exist('lensFocus','file')
                    % If isetlens is on the path, we run lensFocus to check
                    % that the specified focus distance is a legitimate
                    % value.
                    lensFile     = thisR.get('lens file');
                    filmdistance = lensFocus(lensFile,val*1e+3); %mm
                    if filmdistance < 0
                        warning('%s lens cannot focus an object at this distance.', lensFile);
                    end
                end
            otherwise
                error('Unknown camera type %s\n',opticsType);
        end

        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = val*ieUnitScaleFactor(varargin{1});
        end

    case {'accommodation'}
        % We allow specifying accommodation rather than focal distance.
        % For typical lenses, accommodation is 1/focaldistance.
        % 
        % For the human eye models, accommodation is built into the model
        % itself.  When we set the value, we use setNavarroAccommodation or
        % setArizonaAccommodation. There is no way to adjust the LeGrand eye.
        %        
        switch thisR.get('camera subtype')
            case {'humaneye'}
                val = thisR.get('lens accommodation');
            case 'pinhole'
                warning('Pinhole has infinite depth of field, no focal distance.');
                val = Inf;
                return;
            otherwise
                % Typically this is what is meant
                val = 1 / thisR.get('focal distance','m');
        end

        % thisR.get('accommodation');   % Diopters

    case 'film'
        % The whole film struct.
        val = thisR.film;

    case {'filmdistance'}
        % thisR.get('film distance',unit); % Returned in meters
        %
        % If the camera is a pinhole, it might have a filmdistance.  If it
        % does not, then we calculate where the film should be positioned
        % so that the film diagonal and the field of view all make sense
        % together.
        %
        % When there is a lens, PBRT sets the filmdistance so that an
        % object at the focaldistance is in focus. This code calculates
        % roughly where that will be.  It requires having isetlens on the
        % path, though.
        %
        % For humanEye or realisticEye, call retina distance in mm.
        %
        opticsType = thisR.get('optics type');
        switch opticsType
            case {'pinhole'}
                % Calculate this from the fov, if it is not already stored.
                if isfield(thisR.camera,'filmdistance')
                    % Worried about the units.  mm or m?  Assuming meters.
                    val = thisR.camera.filmdistance.value;
                else
                    % Compute the distance to achieve the diagonal fov.  We
                    % might have to make this match the smaller size (x or
                    % y) because of PBRT conventions.  Some day.  For now
                    % we use the diagonal.
                    fov = thisR.get('fov');  % Degrees
                    filmDiag = thisR.get('film diagonal','m');  % m

                    %   tand(fov) = opp/adj; adjacent is distance
                    val = (filmDiag/2)/tand(fov);               % m

                end

            case 'lens'
                % We separate out the omni and humaneye models
                if strcmp(thisR.get('camera subtype'),'humaneye')
                    % For the human eye model we store the distance to the
                    % retina in millimeters.  So we explicitly return it in
                    % meters here.
                    val = thisR.get('retina distance','m');
                else
                    % We calculate the focal length from the lens file
                    lensFile = thisR.get('lens file');
                    if exist('lensFocus','file')
                        % If isetlens is on the path, we convert the
                        % distance to the in-focus object plane into
                        % millimeters and see whether there is a film
                        % distance so that that object plane is in focus.
                        % This is
                        %
                        % But we return the value in meters
                        val = lensFocus(lensFile,1e+3*thisR.get('focal distance'))*1e-3;
                    else
                        % No lensFocus, so tell the user about isetlens
                        warning('Add isetlens to your path if you want the film distance estimate')
                    end
                    if ~isempty(val) && val < 0
                        warning('%s lens cannot focus an object at this distance.', lensFile);
                    end
                end
            case 'environment'
                % No idea
            otherwise
                error('Unknown opticsType %s\n',opticsType);
        end

        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = val*ieUnitScaleFactor(varargin{1});
        end


        % humaneye (realisticEye) parameters
    case {'retinadistance'}
        % Default storage in mm.  Hence the scale factor on units
        subType = thisR.get('camera subtype');
        if isequal(subType,'humaneye')
            val = thisR.camera.retinaDistance.value;
        else, error('%s only exists for humaneye or realisticeye model',param);
        end

        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = (val*1e-3)*ieUnitScaleFactor(varargin{1});
        end

    case {'eyeradius','retinaradius'}
        % thisR.get('eye radius','m');
        % Default storage in mm.
        %
        % Originally called retina radius, but it really is the
        % radius of the eye ball, not the retina.
        subType = thisR.get('camera subtype');
        if isequal(subType,'humaneye')
            val = thisR.camera.retinaRadius.value;
        else, error('%s only exists for humaneye or realisticeye model',param);
        end
        
        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = (val*1e-3)*ieUnitScaleFactor(varargin{1});
        end

    case {'retinasemidiam'}
        % Curved retina parameter.
        % Default storage in mm.  Hence the scale factor on units
        subType = thisR.get('camera subtype');
        if isequal(subType,'humaneye')
            val = thisR.camera.retinaSemiDiam.value;
        else, error('%s only exists for realisticEye model',param);
        end
        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = (val*1e-3)*ieUnitScaleFactor(varargin{1});
        end

    case 'center2chord'
        % Distance from the center of the eyeball to the chord that defines
        % the field of view.  We know the radius of the eyeball and the
        % size of the chord.
        %
        %  val^2 + semiDiam^2 = radius^2
        %
        % See the PPT about the eyeball geometry, defining the retina
        % radius, distance, and semidiam

        eyeRadius = thisR.get('retina radius','mm');
        semiDiam  = thisR.get('retina semidiam','mm');
        if(eyeRadius < semiDiam)
            % The distance to the retina from the back of the lens should
            % always be bigger than the eye ball radius.  Otherwise the
            % lens is on the wrong side of the center of the eye.
            error('semiDiam is larger than eye ball radius. Not good.')
        end
        val = sqrt(eyeRadius^2 - semiDiam^2);

    case {'lens2chord','distance2chord'}
        %  Distance from the back of the lens to the chord that defines
        %  the field of view.
        %
        % See the PPT about the eyeball geometry, defining the retina
        % radius, distance, and semidiam

        eyeRadius     = thisR.get('retina radius','mm');
        focalDistance = thisR.get('retina distance','mm');
        d = focalDistance - eyeRadius;

        a = thisR.get('center 2 chord');
        val = a+d;

    case {'ior1'}
        % Index of refraction 1
        if isequal(thisR.get('camera subtype'),'humaneye')
            val = thisR.camera.ior1.value;
        else, error('%s only exists for realisticEye model',param);
        end
    case {'ior2'}
        % Index of refraction 1
        if isequal(thisR.get('camera subtype'),'humaneye')
            val = thisR.camera.ior2.value;
        else, error('%s only exists for realisticEye model',param);
        end
    case {'ior3'}
        if isequal(thisR.get('camera subtype'),'humaneye')
            val = thisR.camera.ior3.value;
        else, error('%s only exists for realisticEye model',param);
        end
    case {'ior4'}
        if isequal(thisR.get('camera subtype'),'humaneye')
            val = thisR.camera.ior4.value;
        else, error('%s only exists for realisticEye model',param);
        end

        % Back to the general case
    case {'fov','fieldofview'}
        % recipe.get('fov') - degrees
        %
        if isfield(thisR.camera,'fov')
            val = thisR.camera.fov.value;
            return;
        end

        % Try to figure out.  But we have to deal with fov separately for
        % different types of camera models.
        filmDiag = thisR.get('film diagonal');
        if isempty(filmDiag)
            thisR.set('film diagonal',10);
            warning('Set film diagonal to 10 mm, arbitrarily');
        end
        switch lower(thisR.get('camera subtype'))
            case {'pinhole','perspective'}
                % For the pinhole the film distance and the field of view always
                % match.  The fov is normally stored which implies a film distance
                % and film size.
                if isfield(thisR.camera,'fov')
                    % The fov was set.
                    val = thisR.get('fov');  % There is an FOV
                    if isfield(thisR.camera,'filmdistance')
                        % A consistency check.  The field of view should make
                        % sense for the film distance.
                        tst = atand(filmDiag/2/thisR.camera.filmdistance.value);
                        assert(abs((val/tst) - 1) < 0.01);
                    end
                else
                    % There is no FOV. We hneed a film distance and size to
                    % know the FOV.  With no film distance, we are in
                    % trouble.  So, we set an arbitrary distance and tell
                    % the user to fix it.
                    filmDistance = 3*filmDiag;  % Just made that up.
                    thisR.set('film distance',filmDistance);
                    warning('Set film distance  to %f (arbitrarily)',filmDistance);
                    % filmDistance = thisR.set('film distance');
                    val = atand(filmDiag/2/filmDistance);
                end
            case 'humaneye'
                % thisR.get('fov') - realisticEye case
                %
                % The retinal geometry parameters are retinaDistance,
                % retinaSemidiam and retinaRadius.
                %
                % The field of view depends on the size of a chord placed
                % at the 'back' of the sphere where the image is formed.
                % The length of half of this chord is called the semidiam.
                % The distance from the lens to this chord can be
                % calculated from the
                rd = thisR.get('lens 2 chord','mm');
                rs = thisR.get('retina semidiam','mm');
                val = atand(rs/rd)*2;
            otherwise
                % Another lens model (not human)
                %
                % Coarse estimate of the diagonal FOV (degrees) for the
                % lens case. Film diagonal size and distance from the film
                % to the back of the lens.
                if ~exist('lensFocus','file')
                    warning('To calculate FOV with a lens, you need isetlens on your path');
                    return;
                end
                focusDistance = thisR.get('focus distance');    % meters
                lensFile      = thisR.get('lens file');
                filmDistance  = lensFocus(lensFile,1e+3*focusDistance); % mm
                val           = atand(filmDiag/2/filmDistance);
        end

    case 'depthrange'
        % dRange = thisR.get('depth range');
        % Values in meters
        val = piSceneDepth(thisR);
        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = val*ieUnitScaleFactor(varargin{1});
        end

    case 'pupildiameter'
        % Default units are millimeters
        switch ieParamFormat(thisR.get('camera subtype'))
            case 'pinhole'
                val = 0;
            case 'humaneye'
                val = thisR.camera.pupilDiameter.value;
            otherwise
                disp('Need to figure out pupil diameter!!!')
        end
        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = (val*1e-3)*ieUnitScaleFactor(varargin{1});
        end

    case 'diffraction'
        % thisR.get('diffraction');
        %
        % Status of diffraction during rendering.  Works with realistic eye
        % and omni.  Probably realisticEye, but we should ask TL.  It isn't
        % quite running in the new version, July 11.
        val = 'false';
        if isfield(thisR.camera,'diffractionEnabled')
            val = thisR.camera.diffractionEnabled.value;
        end
        if isequal(val,'true'), val = true; else, val = false; end

    case 'chromaticaberration'
        % thisR.get('chromatic aberration')
        % True or false (on or off)
        val = 'false';
        if isfield(thisR.camera,'chromaticAberrationEnabled')
            val = thisR.camera.chromaticAberrationEnabled.value;
        end
        if isequal(val,'true'), val = true; else, val = false; end

    case 'numcabands'
        % thisR.get('num ca bands')
        try
            val = thisR.integrator.numCABands.value;
        catch
            val = 0;
        end

        % Light field camera parameters
    case {'nmicrolens','npinholes'}
        % How many microlens (pinholes)
        val(2) = thisR.camera.num_pinholes_w.value;
        val(1) = thisR.camera.num_pinholes_h.value;
    case 'nsubpixels'
        % How many film pixels behind each microlens/pinhole
        val(2) = thisR.camera.subpixels_w;
        val(1) = thisR.camera.subpixels_h;

        % Film (because of PBRT.  ISETCam it would be sensor).
    case {'spatialsamples','filmresolution','spatialresolution'}
        % thisR.get('spatial samples');
        %
        % When using ISETBio, we usually call it spatial samples or spatial
        % resolution.  For ISET3d, it is usually film resolution because of
        % the PBRT notation.
        %
        % We also have some matters to consider for light field cameras.
        try
            val = [thisR.film.xresolution.value,thisR.film.yresolution.value];
        catch
            warning('Film resolution not specified');
            val = [];
        end
        %{
        % For a lightfield camera, if film resolution is not defined, we
          could do this. This would be an omni camera that has microlenses.

          nMicrolens = thisR.get('n microlens');
          nSubpixels = thisR.get('n subpixels');
          thisR.set('film resolution', nMicrolens .* nSubpixels);
        %}

    case {'samplespacing'}
        % Distance in meters between the row and col samples

        % This formula assumes film diagonal pixels
        val =thisR.get('filmdiagonal')/norm(thisR.get('spatial samples'));

    case 'filmxresolution'
        % An integer specifying number of samples
        val = thisR.film.xresolution.value;
    case 'filmyresolution'
        % An integer specifying number of samples
        val = [thisR.film.yresolution.value];

    case {'filmwidth'}
        % x-dimension, columns
        ss   = thisR.get('spatial samples'); % Number of samples
        val = ss(1)*thisR.get('sample spacing');
    case {'filmheight'}
        % y-dimension, rows
        ss   = thisR.get('spatial samples'); % Number of samples
        val = ss(2)*thisR.get('sample spacing');
    case 'aperturediameter'
        % Needs to be checked.  Default units are meters or millimeters?
        if isfield(thisR.camera, 'aperturediameter') ||...
                isfield(thisR.camera, 'aperture_diameter')
            val = thisR.camera.aperturediameter.value;
        else
            val = NaN;
        end

        % Need to check on the units!
        if isempty(varargin), return;
        else, val = val*ieUnitScaleFactor(varargin{1});
        end

    case {'filmdiagonal','filmdiag'}
        % recipe.get('film diagonal');  in mm
        if isfield(thisR.film,'diagonal')
            val = thisR.film.diagonal.value;
        else
            % warning('Setting film diagonal to 10 mm. Previously unspecified');
            thisR.set('film diagonal',10);
            val = 10;
        end

        % By default the film is stored in mm, unfortunately.  So we scale
        % to meters and then apply unit scale factor
        if isempty(varargin), return;
        else, val = val*1e-3*ieUnitScaleFactor(varargin{1});
        end

    case 'filmsubtype'
        % What are the legitimate options?
        if isfield(thisR.film,'subtype')
            val = thisR.film.subtype;
        end

    case {'raysperpixel'}
        if isfield(thisR.sampler,'pixelsamples')
            val = thisR.sampler.pixelsamples.value;
        end

    case {'cropwindow'}
        if(isfield(thisR.film,'cropwindow'))
            val = thisR.film.cropwindow.value;
        else
            val = [0 1 0 1];
        end

        % Rendering related
    case{'maxdepth','bounces','nbounces'}
        % Number of bounces.  If not specified, 1.  Otherwise ...
        val = 1;
        if isfield(thisR.integrator,'maxdepth')
            val = thisR.integrator.maxdepth.value;
        end

    case{'integrator','integratorsubtype'}
        if isfield(thisR.integrator,'subtype')
            val = thisR.integrator.subtype;
        end
    case {'nwavebands'}
        % Not sure about this.  Initialized this way because expected this
        % way in sceneEye.  Could be updated once we understand.
        val = 0;
        if(isfield(thisR.renderer, 'nWaveBands'))
            val = thisR.renderer.nWaveBands.value;
        end

    case{'camerabody'}
        % thisR.get('camera body');
        val.camera = thisR.camera;
        val.film   = thisR.film;
        val.filter = thisR.filter;

        % Materials.  Still needs work, but exists (BW).
    case {'materials', 'material'}
        % thisR.Get('material',matName,property)
        %
        % thisR = piRecipeDefault('scene name','SimpleScene');
        % materials = thisR.get('materials');
        % thisMat   = thisR.get('material', 'BODY');
        % nameCheck = thisR.get('material', 'uber', 'name');
        % kd     = thisR.get('material', 'uber', 'kd');
        % kdType = thisR.get('material', 'uber', 'kd type');
        % kdVal  = thisR.get('material', 'uber', 'kd value');
        %
        % Get a  property from a material or a material property named in
        % this recipe.

        if isempty(varargin)
            % Return the whole material list
            if isfield(thisR.materials, 'list')
                val = thisR.materials.list;
            else
                % Should this be just empty, or an empty cell?
                warning('No material in this recipe')
                val = {};
            end
            return;
        end

        % Here we list the material names or find a material by its name.
        % If there is a material name (varargin{1}) and then a material
        % property (varargin{2}) we call piMaterialGet.  See piMaterialGet
        % for the list of material properties you can get.
        switch varargin{1}
            % Special cases
            case 'names'
                % thisR.get('material','names');
                val = keys(thisR.materials.list);
            otherwise
                % The first argument indicates the material name and there
                % must be a second argument for the property
                if isstruct(varargin{1})
                    % The user sent in the material.  We hope.
                    % We should have a slot in material that identifies itself as a
                    % material.  Maybe a test like "material.type ismember valid
                    % materials."
                    thisMat = varargin{1};
                elseif ischar(varargin{1})
                    % Search by name, find the index
                    thisMat = thisR.materials.list(varargin{1});
                    val = thisMat;
                end

                if isempty(thisMat)
                    warning('Could not find material. Return.')
                    return;
                end
                if numel(varargin) >= 2
                    % Return the material property
                    % thisR.get('material', material/idx/name, property)
                    % Return the material property
                    val = piMaterialGet(thisMat, varargin{2});
                end
        end

    case {'nmaterial', 'nmaterials', 'materialnumber', 'materialsnumber'}
        % thisR.get('n materials')
        % Number of materials in this scene.
        val = thisR.materials.list.Count;
    case {'materialsprint','printmaterials', 'materialprint', 'printmaterial'}
        % thisR.get('materials print');
        %
        % These are the materials that are named in the tree hierarchy.
        piMaterialPrint(thisR);
    case {'materialsoutputfile'}
        % Unclear why this is still here.  Probably deprecated.
        val = thisR.materials.outputfile;

        % Getting ready for textures
    case{'texture', 'textures'}
        % thisR.get('texture', textureName, property)

        % thisR = piRecipeDefault('scene name', 'flatSurfaceRandomTexture');
        % textures = thisR.get('texture');
        % thisTexture = thisR.get('texture', 'reflectanceChart_color');
        % thisName = thisR.get('texture', 'reflectanceChart_color', 'name');
        % filename = thisR.get('texture', 'reflectanceChart_color', 'filename');
        % filenameVal = thisR.get('texture', 'reflectanceChart_color', 'filename val');

        if isempty(varargin)
            % Return the whole texture list
            if isfield(thisR.textures, 'list')
                val = thisR.textures.list;
            else
                % Should this be just empty, or an empty cell?
                warning('No material in this recipe')
                val = {};
            end
            return;
        end

        switch varargin{1}
            % Special cases
            case 'names'
                % thisR.get('texture', 'names');
                val = keys(thisR.textures.list);
            otherwise
                % The first argument indicates the texture name and there
                % must be a second argument for the property
                if isstruct(varargin{1})
                    thisTexture = varargin{1};
                elseif ischar(varargin{1})
                    % Search by name, find the index
                    [~, thisTexture] = piTextureFind(thisR.textures.list, 'name', varargin{1});
                    val = thisTexture;
                end

                if isempty(thisTexture)
                    warning('Could not find material. Return.')
                    return;
                end
                if numel(varargin) >= 2
                    % Return the texture property
                    % thisR.get('texture', texture/idx/name, property)
                    % Return the texture property
                    val = piTextureGet(thisTexture, varargin{2});
                end
        end

    case {'ntexture', 'ntextures', 'texturenumber', 'texturesnumber'}
        % thisR.get('n textures')
        % Number of textures in this scene
        if isfield(thisR.textures, 'list')
            val = thisR.textures.list.Count;
        else
            val = 0;
        end
    case {'texturesprint', 'printmtextures', 'textureprint', 'printtexture'}
        % thisR.get('textures print')
        %
        piTexturePrint(thisR);

        % Branches
    case {'branches'}
        val = [];
        if isempty(thisR.assets), return; end
        nnodes = thisR.assets.nnodes;
        for ii=1:nnodes
            thisNode = thisR.assets.Node{ii};
            if isfield(thisNode,'type') && isequal(thisNode.type,'branch')
                val = [val,ii]; %#ok<AGROW>
            end
        end
    case {'branchnames'}
        % Full names with id of every branch node
        if isempty(thisR.assets), return; end
        ids = thisR.get('branches');
        names = thisR.assets.names;   % Names of everything.
        val = cell(1,numel(ids));
        for ii = 1:numel(ids)
            % Includes ids and everything
            val{ii} = names{ids(ii)};
        end

    case {'branchnamesnoid'}
        % Name with id stripped of every branch node
        if isempty(thisR.assets), return; end
        ids = thisR.get('branches');
        names = thisR.assets.names;   % Names of everything.
        val = cell(1,numel(ids));
        for ii = 1:numel(ids)
            % Includes ids and everything
            thisName = names{ids(ii)};
            val{ii} = thisName(10:end);
        end

        % Objects - this section should be converted to
        % thisR.get('object',param)
        % But for now, it is all 'objectparam'
    case {'objects','object'}
        % Indices to the objects.
        val = [];
        if isempty(thisR.assets), return; end
        nnodes = thisR.assets.nnodes;
        for ii=1:nnodes
            thisNode = thisR.assets.Node{ii};
            if isfield(thisNode,'type') && isequal(thisNode.type,'object')
                val = [val,ii]; %#ok<AGROW>
            end
        end
    case {'objectmaterial','materialobject'}
        % val = thisR.get('object material');
        %
        % Cell arrays of object names and corresponding material
        % names.
        %
        % We do not use findleaves because sometimes tree class
        % thinks what we call is a branch is a leaf because,
        % well, we don't put an object below a branch node.  We
        % should trim the tree of useless branches (any branch
        % that has no object beneath it). Maybe.  (BW).
        ids = thisR.get('objects');
        leafMaterial = cell(1,numel(ids));
        leafNames = cell(1,numel(ids));
        cnt = 1;
        for ii=ids
            thisAsset = thisR.get('asset',ii);
            if iscell(thisAsset), thisAsset = thisAsset{1}; end
            leafNames{cnt} = thisAsset.name;
            leafMaterial{cnt} = piAssetGet(thisAsset,'material name');
            cnt = cnt + 1;
        end
        val.leafNames = leafNames;
        val.leafMaterial = leafMaterial;
    case {'objectmaterials'}
        % A list of materials for each of the objects
        % This and the one above should be merged.
        tmp = thisR.get('object material');
        val = (tmp.leafMaterial)';
    case {'objectnames'}
        % Full names of the objects, including ID and instance.
        val = [];
        if isempty(thisR.assets), return; end
        ids = thisR.get('objects');
        names = thisR.assets.names;
        val = cell(1,numel(ids));
        for ii = 1:numel(ids)
            % Includes ids and everything
            val{ii} = names{ids(ii)};
        end
    case {'objectnamesnoid'}
        % Names of the objects with the ID stripped.
        % Edited by BW Dec 10, 2022.  It used to strip the first 10
        % characters.  Now it splits at ID_ and returns the part after
        % that.
        %
        % We should build a routine that does more, like this one:
        %
        %    [id, instance, objectname] = assetNameParse(name)
        %
        % And then we should call that routine for this set of gets.
        ids = thisR.get('objects');
        names = thisR.assets.names;
        val = cell(1,numel(ids));
        for ii = 1:numel(ids)
            % Includes ids and everything
            thisName = names{ids(ii)};
            tmp = split(thisName,'ID_');
            val{ii} = tmp{end};
        end

    case 'objectsimplenames'
        % Names of the objects
        % We think there is ID_Instance_ObjectName_O.
        % So we try to delete the first two and the O atthe end.
        % If there are fewer parts, we delete less.
        ids = thisR.get('objects');
        names = thisR.assets.names;
        val = cell(1,numel(ids));
        for ii = 1:numel(ids)
            nameParts = split(names{ids(ii)},'_');
            if numel(nameParts) > 2
                tmp = join(nameParts(3:(end-1)),'-');
                val{ii} = tmp{1};
            elseif numel(nameParts) > 1
                val{ii} = nameParts{2};
            else
                val{ii} = nameParts{1};
            end
        end
    case {'objectcoords','objectcoordinates'}
        % Returns the coordinates of the objects (leafs of the asset tree)
        % Units should be meters
        % coords = thisR.get('object coordinates');
        %
        Objects  = thisR.get('objects');
        nObjects = numel(Objects);

        % Get their world positions
        val = zeros(nObjects,3);
        for ii=1:nObjects
            thisNode = thisR.get('assets',Objects(ii));
            if iscell(thisNode), thisNode = thisNode{1}; end
            val(ii,:) = thisR.get('assets',thisNode.name,'world position');
        end
    case {'objectsizes'}
        % All the objects
        % thisR.get('object sizes')
        Objects  = thisR.get('objects');
        nObjects = numel(Objects);
        val = zeros(nObjects,3);
        for ii=1:nObjects
            thisNode = thisR.get('assets',Objects(ii));
            if iscell(thisNode), thisNode = thisNode{1}; end
            thisScale = thisR.get('assets',Objects(ii),'world scale');

            % All the object points
            if isfield(thisNode.shape,'point3p')
                pts = thisNode.shape.point3p;
                if ~isempty(pts)
                    % Range of points times any scale factors on the path
                    val(ii,1) = range(pts(1:3:end))*thisScale(1);
                    val(ii,2) = range(pts(2:3:end))*thisScale(2);
                    val(ii,3) = range(pts(3:3:end))*thisScale(3);
                else
                    val(ii,:) = NaN;
                end
            else
                % There is no shape point information.  So we return NaNs.
                val(ii,:) = NaN;
            end

        end


        % ---------  Lights
    case {'lightsimplenames'}
        % thisR.get('light simple names')
        % Simple names of all the lights
        lightIDX = thisR.get('lights');
        val = cell(numel(lightIDX),1);
        for ii=1:numel(lightIDX)
            val{ii} = thisR.get('light',lightIDX(ii),'name simple');
        end
    case {'lightcoordinates','lightpositions'}
        % thisR.get('light positions')
        % Coordinates of all the lights that have positions
        lightIDX = thisR.get('lights');
        cnt = 0;
        for ii=1:numel(lightIDX)
            thisPos = thisR.get('light',lightIDX(ii),'world position');
            if isnumeric(thisPos) && (sum(isinf(thisPos)) == 0)
                cnt = cnt + 1;
                val.positions(cnt,:) = thisPos; %#ok<AGROW> 
                val.names{cnt} = thisR.get('light',lightIDX(ii),'name simple');
            end
        end
    case{'light', 'lights'}
        % Many different light paramters
        % thisR.get('lights',name or id,property)
        % thisR.get('lights',idx,property)
        % thisR.get('light',idx,'shape')
        % [idx,names] = thisR.get('lights');
        %
        if isempty(varargin)
            % thisR.get('lights')
            %
            % This was returning the names (no id) of the lights.
            % BW changed it to return a vector of node indices to the
            % lights.
            %
            % To discuss with Zhenyi and Zheng.
            names = thisR.assets.mapLgtFullName2Idx.keys;
            if isempty(names), disp('No lights.'); return;
            else
                % We have some names.  Find the numerical value of the asset.
                val = zeros(1,numel(names));
                for ii=1:numel(names)
                    val(ii) = piAssetFind(thisR,'name',names{ii});
                end
                return;
            end
        end

        % Parameters from a single light.  varargin{1} may be an index
        % to the light asset.
        switch ieParamFormat(varargin{1})
            case {'names','namesnoid'}
                % thisR.get('lights','names')
                % All the light names (full)
                val = thisR.assets.mapLgtShortName2Idx.keys;
            case {'namesid','namesidx'}
                % thisR.get('lights','names id');
                % All the light names, without the ID
                val = thisR.assets.mapLgtFullName2Idx.keys;
            otherwise
                % If we are here, varargin{1} is a light name or id.
                % There may be a varargin{2} for the light property to
                % return
                if isnumeric(varargin{1})
                    % An index
                    % lgtNames = thisR.assets.mapLgtShortName2Idx.keys;
                    % lgtIdx = varargin{1};
                    thisLight = thisR.get('asset', varargin{1});
                    assert(isequal(thisLight.type,'light'));
                    val = thisLight;
                elseif isstruct(varargin{1})
                    % ZLY: I think it should not be here?
                    % The user sent in the material.  We hope.
                    % We should have a slot in material that identifies itself as a
                    % material.  Maybe a test like "material.type ismember valid
                    % materials."
                    %
                    % Added on July 29 2022.  No warning issued by August
                    % 11.
                    warning("We should not be in this code segment.");
                    thisLight = varargin{1};
                elseif ischar(varargin{1})
                    % Search for the light by name, find its index
                    varargin{1} = piLightNameFormat(varargin{1});
                    thisLight = thisR.get('asset', varargin{1});
                end

                if isempty(thisLight)
                    warning('Could not find the light from ')
                    disp(varargin{1})
                    return;
                end

                if numel(varargin) == 1
                    % If only one varargin, return the light
                    val = thisLight;
                elseif numel(varargin) >= 2
                    % Return the light property in varargin{2}
                    thisLgtStruct = thisLight.lght{1};
                    switch ieParamFormat(varargin{2})
                        case 'name'
                            % This light's specific name stored in the
                            % asset, not the lght struct within the
                            % asset.  They should be the same.
                            val = thisLight.name;
                        case 'namesimple'
                            % Simplified version of this light's name
                            % without ID  or _L and replacing
                            % underscores with a dash.
                            val = thisLight.name;
                            tmp = strsplit(val,'_');
                            val = join(tmp(2:(end-1)),'-');
                        case {'pathtoroot'}
                            % thisR.get('light',lightName,'path to root');
                            %
                            % Returns the sequence of ids from this
                            % light node id to just below the root of
                            % the tree. 
                            id = piAssetSearch(thisR,'light name',thisLight.name);
                            val = thisR.assets.nodetoroot(id);
                        case 'worldposition'
                            % thisR.get('light',idx,'world position')
                            if isfield(thisLgtStruct,'cameracoordinate') && thisLgtStruct.cameracoordinate
                                % The position may be at the camera, so we need
                                % this special case.
                                val = thisR.get('from');
                            elseif isfield(thisLgtStruct,'from')
                                val = thisLgtStruct.from.value;
                            elseif isequal(thisLgtStruct.type,'infinite')
                                val = Inf;
                            elseif isequal(thisLgtStruct.type,'area')
                                % Area light will need a different approach
                                val = thisR.get('asset', thisLight.name, 'world position');
                            else
                                val = Inf;
                            end
                        case {'rotate','rotation'}
                            % Pull out the three rotation parameters
                            % from the stored matrices with respect to
                            % world coordinates.
                            val = thisR.get('asset', thisLight.name, 'rotation');
                        case {'worldrotationangle', 'worldorientation', 'worldrotation'}
                            val = thisR.get('asset', thisLight.name, 'world rotation angle');
                        case {'light', 'lght'}
                            val = thisLight.lght{1};
                        case {'shape'}
                            % For an area light, there will be a shape
                            val = thisLight.lght{1}.shape;
                        otherwise
                            % Most light properties use this method
                            val = piLightGet(thisLgtStruct, varargin{2});
                    end
                end
        end
    case {'nlight', 'nlights', 'light number', 'lights number'}
        % thisR.get('n lights')
        % Number of lights in this scene.
        val = numel(thisR.get('light', 'names'));
    case {'lightsprint', 'printlights', 'lightprint', 'printlight'}
        % thisR.get('lights print');
        piLightPrint(thisR);

        % Node (asset) gets
    case {'node','nodes','asset', 'assets'}
        % thisR.get('asset',varargin)
        %
        %   varargin{1} is typically the name or ID
        %
        % thisR.get('asset',name or ID);        % Returns the asset
        % thisR.get('asset',name or ID, param); % Returns the param val
        % thisR.get('asset',name or ID,'world position')
        % thisR.get('asset',name or ID,'size')

        % We are starting to call nodes 'nodes', rather than 'assets'.
        % We think of an asset as, say, a car with all of its parts. A
        % node is the node in a tree.  The node may contains multiple
        % assets in the subtree. (BW, Sept 2021).

        if ischar(varargin{1})
            [id,thisAsset] = piAssetFind(thisR.assets,'name',varargin{1});
            % If only one asset matches, turn it from cell to struct.
        else
            % Not sure when we send in varargin as an array.  Example?
            % (BW)
            if numel(varargin{1}) > 1,  id = varargin{1}(1);
            else,                       id = varargin{1};
            end
            [~, thisAsset] = piAssetFind(thisR.assets,'id', id);
        end
        if isempty(id)
            error('Could not find asset %s\n',varargin{1});
        end
        if iscell(thisAsset), thisAsset = thisAsset{1}; end
        if length(varargin) == 1
            val = thisAsset;
            return;
        else
            if strncmp(varargin{2},'material',8)
                if iscell(thisAsset.material)
                    material = thisR.materials.list(thisAsset.material{1}.namedmaterial);
                else
                    material = thisR.materials.list(thisAsset.material.namedmaterial);
                end
            end
            switch ieParamFormat(varargin{2})
                case 'id'
                    val = id;
                case 'subtree'
                    % thisR.get('asset', assetName, 'subtree', ['replace', false]);
                    % The id is retrieved above.
                    val = thisR.assets.subtree(id);

                    % The current IDs only make sense as part of the whole
                    % tree.  So we strip them and replace the names in the
                    % current structure.
                    if numel(varargin) >= 4
                        replace = varargin{4};
                    else
                        replace = true;
                    end
                    % This seems wrong. Second param is an ID, 3rd should
                    % be replace. 
                    [~, val] = val.stripID([],replace);

                case 'children'
                    % Get the children of a node
                    val = thisR.assets.getchildren(id);
                case {'parent','parentid'}
                    % There is asset parent id below, but I think this is
                    % the right way to get it.
                    val = thisR.assets.Parent(id);
                case {'nodetoroot','pathtoroot'}
                    % thisR.get('asset',assetName,'node to root');
                    %
                    % Returns the sequence of ids from this node id to
                    % root of the tree.
                    val = thisR.assets.nodetoroot(id);

                    % Get material properties from this asset
                case 'materialname'
                    val = material.name;
                case 'materialtype'
                    val = material.type;
                    % Leafs (objects) in the tree.

                    % World position and orientation properties.  These
                    % need more explanation.
                case 'worldrotationmatrix'
                    % This is a 4x4 matrix, that represents accumulated
                    % rotation effects of ALL rotation action.
                    nodeToRoot = thisR.assets.nodetoroot(id);
                    [val, ~] = piTransformWorld2Obj(thisR, nodeToRoot);
                case {'worldrotationangle', 'worldorientation', 'worldrotation'}
                    rotM = thisR.get('asset', id, 'world rotation matrix');
                    val = piTransformRotM2Degs(rotM);
                case {'worldtranslation', 'worldtranslationmatrix'}
                    nodeToRoot = thisR.assets.nodetoroot(id);
                    [~, val] = piTransformWorld2Obj(thisR, nodeToRoot);
                case 'worldposition'
                    % thisR.get('asset',idOrName,'world position')
                    val = thisR.get('asset', id, 'world translation');
                    val = val(1:3, 4)';
                case 'worldscale'
                    % Find the scale factors that apply to the object size
                    nodeToRoot = thisR.assets.nodetoroot(id);
                    [~, ~, val] = piTransformWorld2Obj(thisR, nodeToRoot);

                    % These are local values, not world
                case 'translation'
                    % Translation is always in the branch, not in the
                    % leaf.
                    if thisR.assets.isleaf(id)
                        parentID = thisR.get('asset parent id', id);
                        val = thisR.get('asset', parentID, 'translation');
                    else
                        val = piAssetGet(thisAsset, 'translation');
                    end
                case 'rotation'
                    if thisR.assets.isleaf(id)
                        parentID = thisR.get('asset parent id', id);
                        val = thisR.get('asset', parentID, 'rotation');
                    else
                        val = piAssetGet(thisAsset, 'rotation');
                    end

                case 'size'
                    % thisR.get('asset',objectName,'size');
                    % Size of one object in meters
                    if thisR.assets.isleaf(id)
                        % Only objects
                        thisScale = thisR.get('assets',id,'world scale');
                        % We are not sure why this is sometimes a
                        % cell and sometimes not
                        if iscell(thisAsset.shape)
                            pts = thisAsset.shape{1}.point3p;
                        else
                            pts = thisAsset.shape.point3p;
                        end
                        val(1) = range(pts(1:3:end))*thisScale(1);
                        val(2) = range(pts(2:3:end))*thisScale(2);
                        val(3) = range(pts(3:3:end))*thisScale(3);
                    else
                        warning('Only objects have a size');
                        val = [];
                    end
                otherwise
                    % Give it a try.
                    val = piAssetGet(thisAsset,varargin{2});
            end
        end
    case {'nnodes'}
        % Number of nodes in the asset tree
        val = numel(thisR.assets.Node);
    case {'nodeid','assetid'}
        % ID from name
        % thisR.get('asset id',assetName);
        val = piAssetFind(thisR.assets,'name',varargin{1});
    case {'noderoot','assetroot'}
        % The root of all assets only has a name, no properties.
        val = thisR.assets.get(1);
    case {'nodenames','assetnames'}
        % We have a confusion between nodes and assets.  The assets should
        % refer to the objects, not all the nodes IMHO (BW).
        % The names without the XXXID_ prepended
        % What about objectnames and assetnames should be the same
        % thing.  But somehow nodenames and assetnames became the
        % same.
        val = thisR.assets.stripID([],'');
    case {'nodeparentid','assetparentid'}
        % thisR.get('asset parent id',assetName or ID);
        % Deprecated.
        % Please use
        %
        %    thisR.get('asset',id,'parent')
        %
        % Returns the id of the parent node
        thisNode = varargin{1};
        if isstruct(thisNode)
            thisNodeID = piAssetFind(thisR.assets,'name',thisNode.name);
        elseif ischar(thisNode)
            % It is a name, get the ID
            thisNodeID = piAssetFind(thisR.assets,'name',thisNode);
        elseif isnumeric(thisNode)
            thisNodeID = thisNode;
        end
        val = thisR.assets.getparent(thisNodeID);
    case {'nodeparent','assetparent'}
        % thisR.get('asset parent',assetName)
        %
        thisNode = varargin{1};
        parentNode = thisR.get('asset parent id',thisNode);
        val = thisR.assets.Node{parentNode};

    otherwise
        error('Unknown parameter %s\n',param);
end

end
