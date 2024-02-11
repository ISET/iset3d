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
%      'fov'                - Field of view, horizontal (deg)
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
%      'film diagonal'      - Diagonal size in mm
%      'film size'          - (width, height) in mm
%
%      % Special retinal properties for human eye models
%      % See the discussion in sceneEye about the geometry of the
%      % retinal model.  Also, have a look here
%
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
%    % Node information
%        The code uses asset and node interchangeably.  We should have used
%        object and asset interchangeably, node for everything, and
%        branch for nodes that are not leaves.  Trying to do better over
%        time.
%
%       'nodes'      - This struct includes the objects and their
%                       properties in the World
%       'node names'
%       'node id'
%       'node root'
%       'node parent id'
%       'node parent'
%       'nodes list'  - a list of nodes (branches).
%
%    % Object information
%        Objects have an _O at the end and are the leaves of the asset
%        tree.  Other nodes have a branch (_B) or Instance (_I) or light
%        (_L) indicator.  (We consider lights to be assets/objects.
%     'object ids'        - Indices of the objects
%     'object names'           - Full names
%     'object name material'   - Two cell arrays names and materials
%     'object materials'       - Just the materials
%     'object names noid'
%     'object simple names'
%     'object coords','object coordinates'
%     'object sizes'
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

    % Metadata
    case {'name'}
        val = thisR.name;

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
    case {'outputdir','workingdirectory','dockerdirectory','outputfolder'}
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
        if ~isempty(thisR.metadata)
            val = thisR.metadata.rendertype;
        else
            val = [];
        end
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
        % Differences between the 'from' and 'to'.  Points towards 'to'
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
        % thisR.get('lens dir output')
        % Directory where we plan to store the lens file for rendering
        %
        % The directory depends on the scene - outputdir/lens. If
        % no scene is defined the output dir is empty and we use
        % iset3d/local/lens.
        outdir = thisR.get('output dir');
        if isempty(outdir)
            val = fullfile(piRootPath,'local','lens');
            if ~exist(val,'dir'), mkdir(val); end
        else
            val = fullfile(thisR.get('outputdir'),'lens');
        end
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
        % This is called when the camera model is a human eye.
        %
        % For typical optics (not eye models) the accommodation means
        % 1/focal distance.  A simple lens is accommodated to a focal
        % distance and its accommodation is the inverse of that
        % distance.
        %
        % Given the new system for writing lens files when rendering,
        % perhaps it could all be merged into 'accommodation'.  We
        % always store focal dsitance and accommodation is its
        % inverse.  Always.
        %
        % The Navarro and Arizona eye models have an accommodation
        % value for the lens/cornea.  The retina distance is fixed,
        % and accommodation is achieved by rebuilding the eye model
        % file at render time.
        %
        % Trying that.

        val = 1 / thisR.get('focal distance');

        %{
        if isequal(thisR.get('camera subtype'),'humaneye')
            % If it is a human eye model and the lens file is written out,
            % we get the accommodation from the file.

            lensFile = thisR.get('lensfile output');
            if exist(lensFile,'file')
                fprintf('Reading accommodation from output lens file: %s\n',lensFile);
                % Read the output lens file
                txtLines = piReadText(lensFile);

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
                fprintf('Reading accommodation from focal distance.\n')
                val = 1 / thisR.get('focal distance');
            end
        else
            % For camera lenses people call the accommodation the inverse
            % of the focal distance.
            val = 1 / thisR.get('focal distance');
        end
        %}

    case {'focusdistance','focaldistance'}
        % Distance in object space that is in focus on the film. If the
        % camera model has a lens, we check whether the lens can bring this
        % distance into focus on the film plane.
        %
        %   recipe.get('focal distance')  (m)
        %
        % N.B.  The phrasing can be confusing.  This is the distance to the
        %       plane in OBJECT space that is in focus. This can be easily
        %       confused with the lens' focal length - which is a different
        %       thing!
        %
        %       In PBRT parlance this value is stored differently depending
        %       on the camera model.
        %
        %       For pinhole PBRT calls this focal distance.  But oddly, for
        %            a pinhole, all distances are in focus.  So, maybe we
        %            misunderstand something about PBRT here?
        %       For lens, PBRT calls this focus distance.
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
                        % the lens model.  The accommodation is found
                        % in the header of an existing lens file.
                        val = thisR.camera.focaldistance.value;
                        % val = 1/thisR.get('lens accommodation');
                    otherwise
                        % For other types of lenses this value can be
                        % set, and PBRT adjusts the film distance to
                        % achieve this.
                        val = thisR.camera.focusdistance.value; % Meters
                end

                % If the isetlens repository is on the path, we convert the
                % distance to the focal plane into millimeters and warn if
                % there is no film distance that will bring the object into
                % focus.
                %{
                if isempty(val) && exist('lensFocus','file')
                    % If isetlens is on the path, we run lensFocus to check
                    % that the specified focus distance is a legitimate
                    % value.
                    lensFile     = thisR.get('lens file');
                    filmdistance = lensFocus(lensFile,val*1e+3); %mm
                    if filmdistance < 0
                        warning('%s lens cannot focus an object at this distance.', lensFile);
                    end
                end
                %}
            otherwise
                error('Unknown camera type %s\n',opticsType);
        end

        % Adjust spatial units per user's specification
        if isempty(varargin), return;
        else, val = val*ieUnitScaleFactor(varargin{1});
        end

    case {'accommodation'}
        % For typical lenses, we return accommodation as 1/focaldistance.
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
                warning('No film distance for pinhole.  Only fov');
            case 'humaneye'
                warning('Use retina distance for human eye.')
                val = thisR.get('retina distance','mm');
            case 'lens'
                % We separate out the omni and humaneye models
                if strcmp(thisR.get('camera subtype'),'humaneye')
                    % For the human eye model we store the distance to the
                    % retina in millimeters.  So we explicitly return it in
                    % meters here.
                    val = thisR.get('retina distance','m');
                else
                    % We assume the film is at the focal length of the
                    % lens file. We calculate the focal length.
                    lensFile = thisR.get('lens file');
                    if exist('lensFocus','file')
                        % If isetlens is on the path, we convert the
                        % distance to the in-focus object plane into
                        % millimeters and see whether there is a film
                        % distance so that that object plane is in focus.
                        %
                        % We return the value in meters
                        val = lensFocus(lensFile,1e+3*thisR.get('focal distance'))*1e-3;
                        if ~isempty(val) && val < 0
                            warning('%s lens cannot focus an object at this distance.', lensFile);
                        end
                    else
                        % No lensFocus, so tell the user about isetlens
                        warning('Add isetlens to your path to calculate the film distance.')
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

    case {'filmshapefile'}
        % JSONFileName = thisR.get('film shape file');
        %
        % Should be the full path to the file specifying the film
        % shape, as in the examples in the ISETBio directory
        % retinaShape.
        %
        % The JSON file that represents the XYZ values of the film
        % shape (units are meters)
        %
        % We considered naming this filmshape.  To do that requires
        % recompiling PBRT to look for 'filmshape' and rebuilding the
        % Docker containers (TG/BW).
        if isfield(thisR.camera,'lookuptable')
            val = thisR.camera.lookuptable.value;
        end
    case {'filmshapeoutput'}
        % The full path to the file after it is copied to the output
        % area where the film shape lookup table is stored.
        outputDir = thisR.get('outputdir');
        filmshapebasename = thisR.get('film shape basename');
        val = fullfile(outputDir,'filmshape',filmshapebasename);
    case {'filmshapebasename'}
        val = thisR.get('filmshape file');
        [~,val,~] = fileparts(val);

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

        % Back to the general camera case
    case {'fov','fovshorter','fieldofview'}
        % recipe.get('fov') - degrees
        %
        % Different for different lens models.
        %
        opticsType = thisR.get('camera subtype');
        switch opticsType
            case 'pinhole'
                % For pinhole PBRT applies the fov to the shorter of the
                % two dimensions. <https://pbrt.org/fileformat-v4>
                % "Specifies the field of view for the perspective camera.
                % This is the spread angle of the viewing frustum along the
                % narrower of the image's width and height."
                val = thisR.camera.fov.value;
                return;
            case 'humaneye'
                % The retinal geometry parameters are retinaDistance,
                % retinaSemidiam and retinaRadius.
                %
                % The field of view depends on the size of a chord placed
                % at the 'back' of the sphere where the image is formed.
                % The length of half of this chord is called the semidiam.
                % The distance from the lens to this chord can be
                % calculated using 'lens 2 chord'.
                rd = thisR.get('lens 2 chord','mm');
                rs = thisR.get('retina semidiam','mm');
                val = atand(rs/rd)*2;
            otherwise
                % A lens model (omni).
                %
                % We estimate the diagonal FOV (degrees) for the lens case.
                % Film diagonal size and distance from the film to the back
                % of the lens determine the angle.
                %
                % Perhaps we should match the pinhole case instead, and
                % make this the FOV of the shorter dimension?
                if ~exist('lensFocus','file')
                    warning('To calculate FOV of a lens, you need isetlens on your path');
                    return;
                end
                lensFile      = thisR.get('lens file');
                filmDiag      = thisR.get('film diagonal','mm');
                if isempty(filmDiag)
                    filmDiag = 5;
                    warning('Film diag not set. Assuming %.2f film diagonal',filmDiag);
                end
                % We always have this be very large and thus the focal
                % length of the lens is how we specify the field of view
                objectDistance = 1e6; % 1 Kilometer

                % filmDistance is returned in mm
                filmDistance  = lensFocus(lensFile,objectDistance);

                % tand(fov/2) = (filmDiag/2) / filmDistance
                % fov/2       = atand((filmDiag/2) / filmDistance)
                val           = 2 * atand(filmDiag/2/filmDistance);
        end
    case {'fovother'}
        % thisR.get('fov other')
        %
        % Used only for the pinhole camera.  This calculates the field of
        % view of the larger dimension.
        %
        opticsType = thisR.get('camera subtype');
        if isequal(opticsType,'pinhole')
            fov = thisR.get('fov');    % FOV Shorter dimension
            ss = thisR.get('spatial samples');  % x,y
            k = ss(2)/ss(1); if k < 1, k = 1/k; end
            val = fov*k;
        else
            warning('fov other only applies to pinhole cameras.');
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
        val = 'false';  % If not set, return false
        if isfield(thisR.camera,'diffractionEnabled')
            % val = thisR.camera.diffractionEnabled.type; = 'bool';
            val = thisR.camera.diffractionEnabled.value;
        end

    case 'chromaticaberration'
        % thisR.get('chromatic aberration')
        % True or false (on or off)
        val = false;  % If it doesn't exist, call it false.
        if isfield(thisR.camera,'chromaticAberrationEnabled')
            val = thisR.camera.chromaticAberrationEnabled.value;
        end

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
    case 'microlenssensoroffset'
        % thisR.get('microlens sensor offset',val)
        %
        % Distance between microlens and sensor. Default units
        % meters
        %
        if isfield(thisR.camera,'microlenssensoroffset')
            val = thisR.camera.microlenssensoroffset.value;
        end
        if isempty(varargin), return;
        else
            val = val*ieUnitScaleFactor(varargin{1});
        end

        % Film (because of PBRT.  ISETCam it would be sensor).
    case {'spatialsamples','filmresolution','spatialresolution'}
        % thisR.get('film resolution');
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
        % thisR.get('sample spacing',unit)
        %
        % Distance between the row and col samples.  Default is 'mm'
        val = thisR.get('filmdiagonal','mm')/norm(thisR.get('spatial samples'));

        %         opticsType = thisR.get('camera subtype');
        %         switch opticsType
        %             case 'pinhole'
        %                 % warning('Pinhole sample spacing is based on an arbitrary film diagonal.')
        %             otherwise
        %                 % This formula assumes film diagonal pixels
        %         end

        if isempty(varargin), return;
        else
            val = val*1e-3;  % Convert to meters from mm
            val = val*ieUnitScaleFactor(varargin{1});
        end

    case 'filmxresolution'
        % An integer specifying number of samples
        val = thisR.film.xresolution.value;
    case 'filmyresolution'
        % An integer specifying number of samples
        val = [thisR.film.yresolution.value];

    case {'filmwidth'}
        % thisR.get('film width',unit);
        % x-dimension, columns
        unit = 'mm';
        if numel(varargin) == 1
            unit = varargin{1};
        end
        ss   = thisR.get('spatial samples'); % Number of samples
        val = ss(1)*thisR.get('sample spacing',unit);
    case {'filmheight'}
        % thisR.get('film height',unit);
        % y-dimension, rows
        % Default 'mm'
        unit = 'mm';
        if numel(varargin) == 1
            unit = varargin{1};
        end
        ss   = thisR.get('spatial samples'); % Number of samples
        val = ss(2)*thisR.get('sample spacing',unit);
    case 'filmsize'
        unit = 'mm';
        if numel(varargin) == 1
            unit = varargin{1};
        end
        val(1) = thisR.get('film width',unit);
        val(2) = thisR.get('film height',unit);

    case 'aperturediameter'
        % thisR.get('aperture diameter',units);
        %
        % Default units are millimeters
        if isfield(thisR.camera, 'aperturediameter') ||...
                isfield(thisR.camera, 'aperture_diameter')
            val = thisR.camera.aperturediameter.value;
        else
            val = NaN;
        end

        % Starts in mm.  Convert to meters and then apply scale factor.
        if isempty(varargin), return;
        else, val = val*1e-3*ieUnitScaleFactor(varargin{1});
        end

    case {'filmdiagonal','filmdiag'}
        % thisR.get('film diagonal');  % in mm
        %
        % A pinhole camera can store a film diagonal size in mm. But that
        % value is not used in the rendering.  It is only used by ISET3d so
        % to calculate units for the sample spacing.
        if isfield(thisR.film,'diagonal')
            val = thisR.film.diagonal.value;
        end

        % By default the film diagonal is stored in mm.  So we scale to
        % meters and then apply unit scale factor.  Bummer.
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

        % Media related (e.g underwater, see HB's script t_mediumExample)
    case {'mediaoutputfile'}
        % Unclear why this is still here.  Probably deprecated.
        val = thisR.media.outputfile;
    case {'media','medium'}
        % Full medium (e.g., under water) data structure
        val = thisR.media;
    case {'mediaabsorption'}
        % val = thisR.get('media absorption','seawater');
        name = varargin{1};
        val.wave = thisR.media.list(name).sigma_a.value(1:2:end);
        val.absorption = thisR.media.list(name).sigma_a.value(2:2:end);
    case {'mediascattering'}
        % val = thisR.get('media scattering','seawater');
        name = varargin{1};
        val.wave = thisR.media.list(name).sigma_s.value(1:2:end);
        val.scatter = thisR.media.list(name).sigma_s.value(2:2:end);

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
        % thisR.get('object',id,param)
        % But for now, it is all 'objectparam'
    case {'objectids','objects','object'}
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
    case 'objectmesh'
        % thisR.get('object mesh',idxOrName) 
        % 
        % Returns the whole mesh struct, including vertices, faces, normals
        % and colors when there is a file.  Otherwise, it returns the whole
        % shape struct
        node = thisR.get('asset',varargin{1});
        theShape = node.shape;
        if isfield(theShape,'filename')
            val = readSurfaceMesh(theShape.filename);
        elseif ~isempty(theShape.point3p)
            val = theShape;
        else
            val = [];
            warning('No file or mesh data found for node %d',varargin{1});
        end
    case 'objectvertices'
        % v = thisR.get('object mesh',name/id);
        %
        % Returns the vertices of the object mesh.
        % mean(v) is the average position of the mesh vertices
        %
        msh = thisR.get('object mesh',varargin{1});
        if isa(msh,'surfaceMesh')
            % When there is a file
            val = msh.Vertices;
        elseif isstruct(msh) && isfield(msh,'point3p')
            % When the theShape has the point3p slot
            val = msh.point3p;
        else
            val = [];
            warning('No vertices found for node %d',varargin{1});
        end

    case {'nobjects'}
        % Count the number of objects
        val = numel(thisR.get('objects'));

    case {'objectnamematerial'}
        % val = thisR.get('object name material');
        %
        % Two cell arrays - object names and its material names.
        % See also thisR.show('object');
        %
        ids = thisR.get('objects');
        leafMaterial = cell(1,numel(ids));
        leafNames = cell(1,numel(ids));
        cnt = 1;
        for ii=ids
            thisAsset = thisR.get('asset',ii);
            if iscell(thisAsset), thisAsset = thisAsset{1}; end
            leafNames{cnt}    = thisAsset.name;
            leafMaterial{cnt} = piAssetGet(thisAsset,'material name');
            cnt = cnt + 1;
        end
        val.leafNames = leafNames;
        val.leafMaterial = leafMaterial;
    case {'objectmaterials'}
        % A list of materials in the recipe
        tmp = thisR.get('object name material');
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
        % We think there may be: ID_Instance_ObjectName_O.
        % So we try to delete the first two and the O at the end.
        % If there are fewer parts, we delete less.  There is surely
        % a better algorithm for doing this.
        ids = thisR.get('object ids');
        names = thisR.assets.names;
        val = cell(1,numel(ids));
        for ii = 1:numel(ids)
            nameParts = split(names{ids(ii)},'_');
            if numel(nameParts) > 3
                tmp = join(nameParts(3:(end-1)),'-');
                val{ii} = tmp{1};
            elseif numel(nameParts) > 2
                tmp = join(nameParts(2:(end-1)),'-');
                val{ii} = tmp{1};
            elseif numel(nameParts) > 1
                val{ii} = nameParts{2};
            else
                val{ii} = nameParts{1};
            end
        end
    case {'objectcoords','objectcoordinates'}
        % coords = thisR.get('object coordinates');
        %
        % Returns the world position of the objects (leafs of the asset
        % tree). Units should be in meters.

        Objects  = thisR.get('objects');
        nObjects = numel(Objects);

        % Get the world positions.  I don't know which element of the shape
        % mesh this applies to.
        val = zeros(nObjects,3);
        for ii=1:nObjects
            thisNode = thisR.get('assets',Objects(ii));
            if iscell(thisNode), thisNode = thisNode{1}; end
            val(ii,:) = thisR.get('assets',thisNode.name,'world position');
        end

    case 'objectsizes'
        % thisR.get('object sizes');
        %
        % Sizes for all of the objects.  These cannot be determined in all
        % cases - the ply files need to be present in the output directory.
        idx  = thisR.get('objects');
        nObjects = numel(idx);
        val = zeros(nObjects,3);
        for ii=1:nObjects
            val(ii,:) = thisR.get('asset',idx(ii),'size');
        end

        % -------Instances and references
    case {'instance','instances'}
        % idx = thisR.get('instances'); % Return idx of all instances
        %
        % Branch nodes that have a non-empty referenceObject are the
        % copies (instances).  The reference object is named in the
        % slot, and it can be found using
        %  thisR.get('reference objects');
        assert(isempty(varargin))

        % idx = thisR.get('instances');  % All instances.
        % Return all the indices of the branch indices
        n = thisR.get('n nodes');
        val = zeros(1,n);
        for ii=1:n
            % Instances are branch nodes, not object nodes.
            if isequal(thisR.get('asset',ii,'type'),'branch')
                b = thisR.get('asset',ii);
                % There is a non-mepty reference object, and the name
                % contains _I_.  So this is an instance.
                if isfield(b,'referenceObject') && ~isempty(b.referenceObject) && contains(b.name,'_I_')
                    val(ii) = 1;
                end
            end
        end
        val = find(val);

        % % User sent a name or an index
        % if ischar(varargin{1})
        %     [id,thisAsset] = piAssetFind(thisR.assets,'name',varargin{1});
        %     % If only one asset matches, turn it from cell to struct.
        % else
        %     % This implies that we have a number.
        %     if numel(varargin{1}) > 1,  id = varargin{1}(1);
        %     else,                       id = varargin{1};
        %     end
        %     [~, thisAsset] = piAssetFind(thisR.assets,'id', id);
        % end
        % if isempty(id)
        %     error('Could not find asset %s\n',varargin{1});
        % end
        % if iscell(thisAsset), thisAsset = thisAsset{1}; end
        %
        % % We are not getting the _I_ into the name.  Maybe we do not
        % % need to because we have the isObjectInstance field? (BW)
        % % assert(contains(thisAsset.name,'_I_'));
        %
        % % Enable various parameters - todo!!!!
        % try
        %     val = thisAsset.(varargin{2});
        % catch
        %     disp('Unknown parameter')
        %     val = fieldnames(thisAsset);
        %     disp(val)
        % end

        % These are the other form, without a parameter
    case {'instanceid','instanceids'}
        val = thisR.get('instances');
    case {'instancenames'}
        % thisR.get('instance names')
        % Returns names, stripping the IDs.
        if isempty(thisR.assets), return; end

        idx   = thisR.get('instances');
        names = thisR.get('node names');  % No ID in the name
        val = names(idx(:));
    case {'referenceobjects'}
        % thisR.get('reference objects')
        %
        % A branch node that has isObjectInstance set to true is used
        % as an instance. The object at the leaf node defines the object.
        assert(isempty(varargin));
        n = thisR.get('n nodes');
        val = zeros(1,n);
        for ii=1:n
            % Instances are branch nodes, not object nodes.
            if isequal(thisR.get('asset',ii,'type'),'branch')
                b = thisR.get('asset',ii);
                % This is the flag indicated we are at a branch node
                % that contains an object instance.
                if b.isObjectInstance, val(ii) = 1; end
            end
        end
        val = find(val);

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
                val.positions(cnt,:) = thisPos;
                val.names{cnt} = thisR.get('light',lightIDX(ii),'name simple');
            end
        end
    case{'light', 'lights'}
        % Many different light paramters
        % thisR.get('lights',name or id,property)
        % thisR.get('lights',idx,property)
        % thisR.get('light',idx,'shape')
        % [idx,names] = thisR.get('lights');
        % thisR.get('lights',lightName,'from') - NOT WORKING. to
        % also.

        if isempty(varargin)
            % thisR.get('lights')
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

        % The argument design is bad; varargin{1} has too many
        % possibilities.  It can be the light identifier, or it can be
        % a parameter.  Here is the logic.
        %
        % If it is a number or struct, then it is a light identifier.
        % If it is a char, there are some special cases we check
        % first. If it is none of those, then it is the name of a light.
        thisLight = [];
        if isnumeric(varargin{1})
            % A numerical index
            % lgtNames = thisR.assets.mapLgtShortName2Idx.keys;
            % lgtIdx = varargin{1};
            thisLight = thisR.get('asset', varargin{1});
            assert(isequal(thisLight.type,'light'));
        elseif isstruct(varargin{1}) && isfield(varargin{1},'name')
            % The argument is probably a light struct.  We get
            % the name and then get the light.
            thisLight = thisR.get('asset',varargin{1}.name);
        elseif ischar(varargin{1})
            % There are some special chars.  Otherwise it is the name
            switch ieParamFormat(varargin{1})
                case {'names','namesnoid'}
                    % thisR.get('lights','names')
                    % All the light names (full)
                    val = thisR.assets.mapLgtFullName2Idx.keys;
                    for ii=1:numel(val), val{ii} = val{ii}(10:end); end
                    return;
                case {'namesid','namesidx'}
                    % thisR.get('lights','names id');
                    % All the light names, with the ID
                    val = thisR.assets.mapLgtFullName2Idx.keys;
                    return;
                case {'id','ids'}
                    % The node ids of the lights
                    fullNames = thisR.assets.mapLgtFullName2Idx.keys;
                    val = zeros(size(fullNames));
                    for ii=1:numel(fullNames)
                        val(ii) = str2double(fullNames{ii}(1:6));
                    end
                    return;
                otherwise
                    idx = piAssetSearch(thisR,'light name',varargin{1});
                    thisLight = thisR.get('asset', idx);
                    assert(isequal(thisLight.type,'light'));
            end
        end

        % We made it here.  We should have thisLight.
        if isempty(thisLight), error('No light found.'); end

        % There may be a varargin{2} for the light property to
        % return.
        if numel(varargin) == 1
            % If only one varargin, we return the light
            val = thisLight;
        elseif numel(varargin) >= 2
            % Return the property specified by varargin{2}
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
                    % The logic here is not accounting for
                    % translations after specifying camera
                    % coordinate as true.  We also may not have the
                    % different types of lights properly accounted
                    % for. (BW/DJC).

                    % thisR.get('light',idx,'world position')
                    if isfield(thisLgtStruct,'cameracoordinate') && thisLgtStruct.cameracoordinate
                        % The position may be at the camera.
                        val = thisR.get('from');
                    elseif isfield(thisLgtStruct,'from')
                        val = thisLgtStruct.from.value;
                    elseif isequal(thisLgtStruct.type,'infinite')
                        val = Inf;
                    elseif isequal(thisLgtStruct.type,'area')
                        % Area light will need a different approach
                        val = thisR.get('asset', thisLight.name, 'world position');
                    else
                        % Projection and goniometric should work
                        % this way.
                        val = thisR.get('asset', thisLight.name, 'world position');
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
                case {'cameracoordinate'}
                    % A logical as to whether we initialize at the
                    % camera coordinate
                    val = thisLight.lght{1}.cameracoordinate;

                otherwise
                    % Most light properties use this method
                    val = piLightGet(thisLgtStruct, varargin{2});
            end
        end

    case {'nlight', 'nlights', 'light number', 'lights number'}
        % thisR.get('n lights')
        % Number of lights in this scene.
        val = numel(thisR.get('light', 'names'));
    case {'lightsprint', 'printlights', 'lightprint', 'printlight'}
        % thisR.get('lights print');
        [~,val] = piLightPrint(thisR);

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
                    % The node id is retrieved above.
                    %
                    % The extra varargin which allows the user to specify
                    % the 'replace' value as true or false.  By default,
                    % replace seems to be true.

                    % Get the subtree of this asset
                    val = thisR.assets.subtree(id);

                    % The current IDs only make sense as part of the whole
                    % tree.  So we strip them and replace the names in the
                    % current structure.
                    if numel(varargin) >= 4
                        warning('subtree call has 4th varargin.  Surprised I am.')
                        replace = varargin{4};
                    else
                        replace = true;
                    end

                    % This step strips removes the ID from the Node names
                    % in val. These IDs only make sense in the context of
                    % the original tree.  New IDs will need to be recreated
                    % by the calling function.
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
                case {'size','objectsize'}
                    % thisR.get('asset',objectID,'size');
                    %
                    % Only objects have a size.  No branches.
                    %
                    % We store the shape of the objects either as point3p
                    % in the shape field or as a filename that points to a
                    % ply file with the mesh points.

                    if thisR.assets.isleaf(id)
                        % Only objects
                        thisScale = thisR.get('assets',id,'world scale');

                        % Not sure why this is sometimes a cell and
                        % sometimes not
                        if iscell(thisAsset.shape)
                            theShape = thisAsset.shape{1};
                        else
                            theShape = thisAsset.shape;
                        end

                        val = zeros(1,3);
                        if isempty(theShape)
                            % Sometimes we have the points and
                            % sometimes only a pointer to a PLY file.
                            % Sometimes the shape is a string?  Like
                            % 'Sphere'?
                            warning('Object %d has no shape.',id);
                        elseif ~isempty(theShape.point3p)
                            pts = theShape.point3p;
                            val(1) = (max(pts(1:3:end))-min(pts(1:3:end)))*thisScale(1);
                            val(2) = (max(pts(2:3:end))-min(pts(2:3:end)))*thisScale(2);
                            val(3) = (max(pts(3:3:end))-min(pts(3:3:end)))*thisScale(3);
                        elseif ~isempty(theShape.filename)
                            % Read a shape file.  The shape file needs to
                            % be in the output directory. (BW).
                            [~,~,ext] = fileparts(theShape.filename);
                            if isequal(ext,'.ply')
                                fname = fullfile(thisR.get('inputdir'),theShape.filename);
                                if ~exist(fname,'file')
                                    warning('Can not find the ply file %s\n',fname);
                                    return;
                                end
                                msh = readSurfaceMesh(fname);
                                val = range(msh.Vertices);
                                % I do not understand how the scale is
                                % working yet.  I think we need to
                                % scale.  But t_assetsCopy is better
                                % without it. Confused (BW).  It might
                                % be this is millimeters for many
                                % objects.
                                val = val.*thisScale;
                            elseif isequal(ext,'.pbrt')
                                fprintf('%s - size from PBRT not yet implemented.\n',theShape.filename)
                                % We have some cases, like for chess set.
                            end
                        end
                        % I suppose?
                    else
                        warning('Only objects have a size');
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
