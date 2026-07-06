classdef lensC <  handle
    % Create a multiple element lens object
    %
    % Syntax:
    %   lens = lensC(varargin);
    %
    % Inputs:
    %   N/A
    %
    % Optional key/value pairs
    %   'filename' - string to lens file name descriptor (JSON or dat)
    %   'name', string - Name of this lens
    %   'type', string
    %   'units', {'um','mm','m'}
    %   'wave', vector
    %   'surface array'
    %   'microlens'
    %   'aperture sample'
    %   'aperture middle d'   - Maximum aperture size
    %   'diffraction enabled' - Run HURB as part of the calculation
    %   'figure handle'
    %   'blackbox model'
    %
    % Outputs:
    %   lens - a lensC object
    %
    % Distance units are millimeters, unless otherwise specified.
    %
    % We represent multi-element lenses as a sequence of spherical surfaces
    % and circular apertures. Each surface has a curvature, position, and
    % index of refraction (as a function of wavelength).
    %
    % The surface position of each surface is specified with respect to the
    % final component of the lens. Rays travel from left (the scene) to
    % right (the image). The zero position is the right-most spherical
    % surface. The film (sensor) is at a positive position.
    %
    %     Scene ->  | Lens Surfaces ->|   Film
    %                    -            0     +
    %
    % Apertures are circular and their center is in the (0,0) position.
    % Hence, apertures are specified by a single parameter (diameter in
    % mm).
    %
    % The index of refraction (n) attached to a surface defines the
    % material to the left of the surface.
    %
    % Lens files and surface arrays are specified from the left most
    % element (closest to the scene), to the right-most element (closest to
    % the sensor). Hence, surface arrays are listed from negative positions
    % to positive positions.
    %
    % The lens object works with the 'realistic' camera class. The
    % 'pinhole' cameras has simpler properties.
    %
    % We aim to be consistent with the PBRT lens files, and the Zemax as
    % far possible.
    %
    % AL/BW Vistasoft Copyright 2014
    %
    % See also:
    %    lens.draw, lens.plot, lens.set, lens.get

    % Examples:
    %{
      % Create a lens object
      thislens = lensC('filename','dgauss.22deg.3.0mm.json');
      thislens.draw;
      thislens.plot('focal distance');
      thislens.thickness
    %}
    %{
      % Read in explicitly stating that the file contains 'mm'
      thislens = lensC('filename','2ElLens.json','units','mm');
      thislens.draw;
    %}
    %{
      % To convert a file in millimeters to meters
       thislens = lensC('filename','2ElLens.json','units','mm');
       thislens.fileWrite('2ElLensMeters.json','units','m')
       type '2ElLens.json'
       type '2ElLensMeters.json'
       delete('2ElLensMeters.json');
    %}
    %{
        lens = lensC('filename','dgauss.22deg.100.0mm.json')
    %}
    
    properties
        name = 'default';
        type = 'multi element lens';
        description = 'description';   % Patents or related
        fullFileName = '';             % If read from a file
        surfaceArray = surfaceC();     % Set of spherical surfaces and apertures
        diffractionEnabled = false;    % Do not run HURB by default
        wave = 400:50:700;             % nm
        focalLength = 50;              % mm, focal length of multi-element lens
        apertureMiddleD = [];           % mm, diameter of the middle aperture
        apertureSample = [151 151];    % Number of spatial samples in the aperture.  Use odd number
        centerZ = 0;                   % Theoretical center of lens (length-wise) in the z coordinate
        
        % When we read a lens from a JSON file, we store the struct
        % here
        lensData = [];
        
        % When we draw the lens we store the figure handle here
        fHdl = [];
        
        % Spatial units defined in the input file
        units = 'mm';

        % Black Box Model - Used for certain efficient analyses and
        % computations, largely in Matlab
        BBoxModel=[]; % Empty
        
        % microlens array definition used by PBRT
        microlens = [];         % lensC
        microlensarray = [];    % number of microlenses in x,y dim
        microlenstofilm = [];   % Distance in mm
    end
    
    properties (SetAccess = private)
        centerRay = [];                 % for use for ideal Lens
        inFocusPosition = [0 0 0];
    end
    
    methods (Static)
        files = list(varargin);
    end
    
    methods (Access = public)        

        % Multiple element lens constructor
        function obj = lensC(varargin)
            % thisLens = lens(varargin)
            %   
            % Optional key/value pairs
            %   'filename',...,
            %   'name', string
            %   'type', string
            %   'units', {'um','mm','m'}
            %   'wave', vector
            %   'surface array'
            %   'aperture sample'
            %   'figure handle'
            %   'diffraction enabled'  (Run HURB or huygens)
            %   'blackbox model'
            %
            
            %{
            
            %}
            p = inputParser;
            varargin = ieParamFormat(varargin);
            
            % Set defaults to empty.  Only fill in if not empty.
            p.addParameter('name','',@ischar);
            p.addParameter('type','',@ischar);
            p.addParameter('units','mm',@(x)(ismember(x,{'um','mm','m'})));
            p.addParameter('aperturesample',[],@isvector);
            p.addParameter('aperturemiddled',[],@isscalar);
            p.addParameter('focallength',[],@isnumeric);
            p.addParameter('diffractionenabled',false,@islogical);
            p.addParameter('wave',[],@isvector)
            p.addParameter('figurehandle',[],@isgraphics);
            p.addParameter('blackboxmodel',[])
            
            % Changed to look in isetcam/data/lens (Aug 2, 2022).
            % Allow
            fullFileName = fullfile(piDirGet('lens'),'2ElLens.json');
            p.addParameter('filename', fullFileName, @localLensFileExists);
            
            p.parse(varargin{:});
            if isstruct(p.Results.filename)
                if isfield(p.Results.filename,'folder') && ~isempty(p.Results.filename.folder)
                    filename = fullfile(p.Results.filename.folder,p.Results.filename.name);
                else
                    filename = p.Results.filename.name;
                end
            else
                filename = p.Results.filename;
            end
            
            % Initialize with the lens file and default name
            obj.fileRead(filename,'units',p.Results.units);
            [~,obj.name,~] = fileparts(filename);
            obj.fullFileName = which(filename);
            
            % Basics
            if ~isempty(p.Results.name), obj.name  = p.Results.name; end
            if ~isempty(p.Results.type), obj.name  = p.Results.type; end
            if ~isempty(p.Results.units),obj.units = p.Results.units; end
            obj.diffractionEnabled = p.Results.diffractionenabled;

            % Parameters
            if ~isempty(p.Results.aperturesample)
                obj.apertureSample = p.Results.aperturesample;
            end

            if ~isempty(p.Results.wave), obj.set('wave',p.Results.wave);  end
            % if ~isempty(p.Results.diffractionenabled)
            %     obj.diffractionEnabled = p.Results.diffractionenabled;
            % end
            
            % Window
            if ~isempty(p.Results.figurehandle)
                obj.fHdl = p.Results.figurehandle;
            end
            
            % Advanced
            if ~isempty(p.Results.blackboxmodel)
                obj.BBoxModel = p.Results.blackboxmodel;
            end
            
            % Find the middle aperture (diaphragm) and set this parameter
            % equal to it.  I think we rely on this is a short-cut
            % somewhere.
            if ~isempty(p.Results.aperturemiddled)
                obj.set('middle aperture diameter', p.Results.aperturemiddled);
                obj.apertureMiddleD = p.Results.aperturemiddled;
            else
                obj.apertureMiddleD = obj.get('middle aperture d');
            end
            
            % Set the focal length (compute it unless the user says
            % otherwise).
            if ~isempty(p.Results.focallength)
                obj.focalLength = p.Results.focallength;
            else
                % {
                    % Was here. But this is not focal length, but the
                    % position of focal point
                    obj.focalLength = lensFocus(obj,1e6);
                %}
%                 obj.bbmCreate;
%                 obj.focalLength = mean(obj.get('bbm', 'effective focal length'));
            end
            
        end
        
        function val = thickness(obj)
            % This works when the first surface is a spherical lenses.
            %
            % The most rear position of the multielement lens array is
            % at 0.  The front position, therefore, defines the lens thickness. 
            %
            % We find the front surface center position, which is
            % always a negative number, and add the radius.
            %
            % Units are mm.  I considered, but did not, add
            % ieUnitScaleFactor.
            
            val = obj.surfaceArray(1).sRadius + (-obj.surfaceArray(1).sCenter(3));
        end
        
    end
    
    %% Not sure why these are private. (BW).
    methods (Access = private)
        
        % These values should be obtained using the 'get' function, which
        % is public.  So, obj.get('aperture mask') would be the way to call
        % this function.  Similarly for the others.
        
        function apertureMask = apertureMask(obj)
            % Identify the grid points that fall within the circular
            % aperture. The initial grid is sampled on a rectangular
            % plane.
            
            % Here is the full sampling grid for the resolution and
            % aperture radius
            aGrid = obj.fullGrid;
            
            % We assume a circular aperture. This mask is 1 for the sample
            % points within a circle of the aperture radius
            firstApertureRadius = obj.surfaceArray(1).apertureD/2;
            apertureMask = (aGrid.X.^2 + aGrid.Y.^2) <= firstApertureRadius^2;
            
            % ieFigure;  mesh(double(apertureMask))
            
        end        
    end
end

function tf = localLensFileExists(fileName)
if isstruct(fileName)
    if isfield(fileName,'folder') && ~isempty(fileName.folder)
        fileName = fullfile(fileName.folder,fileName.name);
    else
        fileName = fileName.name;
    end
end
tf = ischar(fileName) && exist(fileName,'file');
end
