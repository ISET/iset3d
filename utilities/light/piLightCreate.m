function lght = piLightCreate(lightName, varargin)
%% Create a light source struct for a recipe
%
% Synopsis:
%   lght = piLightCreate(lightName,varargin)
%
% Brief
%   Create a light struct.  The various types of lights have different
%   slots in their struct.  All lights have the slots 
%      name - Required
%      type - One of the light types.  Default:  'point'
%      spd  - rgb or spectrum.  Default: 'rgb'
%      specscale - How to scale RGB values.  Default: [1,1,1].
%
% Inputs:
%   lightName   - name of the light
%
% Optional key/val pairs (No ieParamFormat.  Use the exact string.)
%
%   type   - light type. Default is point light.  There are light specific
%            properties depend on the light type. 
%   from   - Distant, point, and spot lights have a 'from' and 'to'
%   to       Area lights have a shape. Goniometric and projection
%            lights have?
%   cameracoordinate - Place the light at the camera 'from'.  Applies
%                      to point, spot, area lights. When applicable,
%                      Default is true  
%   shape  - Shape of the area light.  This can be a geometric file or
%            a string, such as 'sphere'
%   radius - Radius of the area light sphere (m)
% 
%  To see the light types use
%
%      lightTypes = piLightCreate('list available types');
%
%  To see the settable properties we have implemented for each light
%  type use 
%
%        piLightProperties(lightTypes{1})
%
%  Look here for the PBRT website information about lights.
%    https://pbrt.org/fileformat-v4#lights
%
% Description:
%   This function creates an ISET3d light struct.  The value of the
%   slots in the struct can be specified when the function is called
%   by key/val pairs. In adition, you can use key/val pairs in the
%   calling function via piLightSet.
%
%   The 'spd' property defines how we will create the light spectrum.
%   The options are 'rgb','blackbody', or 'spectrum'.
%
%   If  spd.type is 'spectrum', then the spd.value is a string that
%   defines which mat file from ISETCam/data/lights should be read in.
%   TODO:  There are lights in iset3d-tiny/data/lights.  I think they
%   should be moved over to ISETCam (BW).
%
%    spd.type = 'spectrum';
%    spd.value= 'Tungsten', or D50 or ...
%
%   Another possibility is
%
%    spd.type = 'blackbody'
%    spd.value = 5000;  % 5000 degrees K, could be anything
%
%   In this case, the PBRT file just has the string blackbody and the
%   number and PBRT figures out the spectrum for us.
%
%  Third possibility is
%
%    spd.type = 'rgb'
%    spd.value = [ R G B];   % An RGB rendering
%
% Returns
%   lght   - light struct
%
% Examples
%   lightTypes = piLightCreate('list available types');
%
%   lgt = piLightCreate('point light 1')
%   lgt = piLightCreate('point light 1','type','point','spd spectrum','Tungsten');
%   lgt = piLightCreate('blueSpot', 'type','spot','spd',[9000]);
%   lgt = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1])
%   lgt = piLightCreate('whiteLight','type','area');
%   lgt = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1])
%   lgt = piLightCreate('areaTest', 'type','area','shape','sphere','radius',30);
%
% See also
%   piLightSet, piLightGet, piLightProperties, 
%   thisR.set('skypmap',filename)
%   https://polyhaven.com/hdris
%

%% Check if the person just wants the light types

validLights = {'distant','goniometric','infinite','point','area','projection','spot'};

if isequal(ieParamFormat(lightName),'listavailabletypes') || ...
        isequal(ieParamFormat(lightName),'list')
    lght = validLights;
    fprintf('\n\nValid light types\n-------------\n')
    for ii=1:numel(lght)
        fprintf('  %s\n',lght{ii});
    end
    fprintf('-------------\n')
    return;
end

%% Parse inputs

% We replace spaces in the varargin parameter with an underscore. For
% example, 'rgb I' becomes 'rgb_I'. For an explanation, see the code at the
% end of this function.
for ii=1:2:numel(varargin)
    varargin{ii} = strrep(varargin{ii}, ' ', '_');
end

p = inputParser;
p.addRequired('lightName', @ischar);

p.addParameter('type','point',@(x)(ismember(x,validLights)));

% We are unsure about the proper default
p.addParameter('cameracoordinate',true);
p.addParameter('from',[],@isvector);
p.addParameter('to',[],@isvector);

p.addParameter('shape',[],@(x)(isstruct(x) || ischar(x))); % For area light
p.addParameter('radius',30,@isnumeric);

p.KeepUnmatched = true;
p.parse(lightName, varargin{:});

cameraCoordinate = p.Results.cameracoordinate;
from = p.Results.from;
to   = p.Results.to;
% If the user sent in 'from' or 'to', cameracoordinate must be false.
% Perhaps if we have a 'from' we should require a 'to'.  But for now
% we just make sure the light is pointing in the z-direction.
if ~isempty(from) || ~isempty(to)
    cameraCoordinate = false;
    if isempty(to),   to = from + [0 0 1]; end
    if isempty(from), from = to - [0 0 1]; end
end

%% Construct the appropriate light struct for each type

% Some of the fields are present in all the lights
lght.type = p.Results.type;

lght.name = p.Results.lightName;

% We want light names to end with _L.  So if it does not, we append
% the _L
if ~isequal(lght.name((end-1):end),'_L')
    % warning('Appending _L to light name')
    lght.name = [lght.name,'_L'];
end

% All lights start out with these two slots
lght.specscale.type = 'float';
lght.specscale.value = 1;

lght.spd.type = 'rgb';
lght.spd.value = [1 1 1];

% Each light type has a different set of parameters.
switch ieParamFormat(lght.type)
    case 'distant'
        % The "distant" light source represents a directional light source "at
        % infinity"; in other words, it illuminates the scene with light
        % arriving from a single direction. The direction is specified
        % with this from and to.
        %
        % I am unsure whether we can specify the 'from' and 'to' using
        % the cameraCoordinate

        %        if ~cameraCoordinate
        lght.from.type = 'point3';
        lght.from.value = from;

        lght.to.type = 'point3';
        lght.to.value = to;
        %       else
        %          lght.cameracoordinate = cameraCoordinate;
        %     end

    case 'goniometric'
        %%  We need a file name for goniometric lights in data/lights
        %
        % See t_lightGoniometric

        % From the book
        %{
        % The "goniometric" light represents a point light source with
        % directionally-varying emission, where the emission
        % distribution is represented by an image.   
        %
        % The goniometric light source approximation is widely used to
        % model area light sources in the field of illumination
        % engineering. The rule of thumb there is that once a
        % reference point is five times an area light source%s radius
        % away from it, a point light approximation has sufficient 
        % accuracy for most applications. File format standards have
        % been developed for encoding goniophotometric diagrams for
        % these applications (Illuminating Engineering Society of
        % North America 2002). Many lighting fixture manufacturers
        % provide data in these formats on their Web sites.         
        %}
        %
        % The file is an equal area type exr file that specifies the
        % intensity of the light on the surface of a sphere.  But the
        % sphere is mapped to a square using the this logic:
        %
        % https://github.com/mmp/pbrt-v4/blob/96347e744107f70fafb70eb6054f148f51ff12e4/src/pbrt/util/math.cpp#L292
        %
        % We should find a valid file and make it a default here.  And
        % document the file requirements.  ChatGPT thinks the PBRT
        % code might look like this:
        %{
        AttributeBegin
            LightSource "goniometric"
            "color I" [1 1 1]       # Specify the intensity of the light (RGB values)
            "string filename" "myLightDiagram.exr"  # Provide the path to the goniometric diagram
        AttributeEnd
        %}

        % When this is set, the light is placed at the camera.
        lght.cameracoordinate = cameraCoordinate;

        % The goniometric image showing the light distribution in
        % different directions.
        lght.filename.type = 'string';
        lght.filename.value = '';


    case {'infinite','skymap','environment'}
        % Gets called from thisR.set('skymap',filename,'add');

        % The "infinite" light is probably best labeled a skymap.  It
        % represents an infinitely far away light source that
        % potentially casts illumination from all directions.  The
        % amount of light from different directions is specified by a
        % file.

        % See the code there for rotations and translations.
        lght.nsamples.type = 'integer';
        lght.nsamples.value = [];

        % V4 for infinite lights
        lght.filename.type = 'string';
        lght.filename.value = '';
        
    case 'point'
        % Initializes a light at the origin.
        % "point" defines a simple point light that casts the same
        % amount of illumination in all directions. It takes two
        % parameters:  
        %
        % Point sources emit in all directions, and has no 'to'.

        % This probably overrides the from.  Not sure.
        lght.cameracoordinate = cameraCoordinate;
        
        lght.from.type = 'point';
        lght.from.value = from;

    case 'projection'
        % See t_lightProjection
        %
        % The "projection" light acts like a slide projector; the given image is
        % used to define a 2D emission distribution that is projected with a
        % center of projection at the light's position. Directions outside the
        % frustum of light projection receive no emitted illumination. It is
        % positioned using the world from light transformation matrix.

        % Assumes we want camera orientation by default

        lght.cameracoordinate = cameraCoordinate;

        lght.fov.type = 'float';
        lght.fov.value = [];

        lght.power.type = 'float';
        lght.power.value = [];

        lght.filename.type = 'string';
        lght.filename.value = '';

        lght.scale.type = 'scale';
        lght.scale.value = {};
        
    case {'spot', 'spotlight'}
        lght.cameracoordinate = cameraCoordinate;

        if ~lght.cameracoordinate
            lght.from.type = 'point3';
            lght.from.value = from;

            lght.to.type = 'point3';
            lght.to.value = to;
        end

        lght.coneangle.type = 'float';
        lght.coneangle.value = [];

        lght.conedeltaangle.type = 'float';
        lght.conedeltaangle.value = [];
        
    case {'area', 'arealight'}
        % These are the default parameters for an area light, that are
        % based on the Blender export in arealight.pbrt.

        % From the Book
        % Area lights have geometry associated with them; the shape and size
        % of the emitting shapes have a substantial effect on the resulting
        % emitted radiance distribution. After an AreaLightSource directive,
        % all subsequent shapes emit light from their surfaces according to
        % the distribution defined by the given area light implementation.
        % Note that area lights can currently only be used with triangle,
        % bilinear patch, sphere, cylinder, and disk shapes;
        % AttributeBegin
        %   AreaLightSource "diffuse" "blackbody L" [ 6500 ] "float power" [ 100 ]
        %   Translate 0 10 0
        %   Shape "sphere" "float radius" [ .25 ]
        % AttributeEnd
        lght.type = 'area';

        lght.twosided.type = 'bool';
        lght.twosided.value = [];

        lght.nsamples.type = 'integer';
        lght.nsamples.value = [];

        lght.spread.type = 'float';
        lght.spread.value = [];

        % We need a piShapeCreate() method.  The default is a basic
        % rectangular shape we use for the area light.
        if isempty(p.Results.shape)
            thisShape = struct('meshshape','trianglemesh', ...
                'filename','', ...
                'integerindices', [0 1 2 3 4 5], ...
                'point3p',[-1 -1 0 -1 1 0 1 1 0 -1 -1 0 1 1 0 1 -1 0], ...
                'point2uv',[0 0 0 1 1 1 0 0 1 1 1 0], ...
                'normaln',[0 0 -1 0 0 -1 0 0 -1 0 0 -1 0 0 -1 0 0 -1], ...
                'height', '',...
                'radius','',...
                'zmin','',...
                'zmax','',...
                'p1','',...
                'p2','',...
                'phimax','',...
                'alpha','');
        else
            thisShape = p.Results.shape;
        end
        lght.shape{1} = thisShape;

        lght.spread.type = 'float';
        lght.spread.value = 30;

        lght.ReverseOrientation.type = 'ReverseOrientation';
        lght.ReverseOrientation.value = false;
end


%% Set additional key/val pairs

% We can set some, but not all, of the light properties on creation. We use
% a method that does not require us to individually list and set every
% possible property for every possible light.
%
% This code, however, is not complete.  It works for many cases, but it can
% fail.  Here is why.
%
% PBRT uses strings to represent properties, such as
%
%    'rgb spd', or 'cone angle'
%
% ISET3d initializes the light this way
%
%   piLightCreate(lightName, 'type','spot','rgb spd',[1 1 1])
%   piLightCreate(lightName, 'type','spot','float coneangle',10)
%
% We parse the parameter values, such as 'rgb spd', so that we can
% set the struct entries properly.
%

% These are the key/val arguments to skip
skip = {'type','shape','radius'};

for ii=1:2:numel(varargin)
    thisKey = varargin{ii};
    thisVal = varargin{ii + 1};

    if ismember(thisKey,skip)
        continue;
    end

    % This is a new key value we are setting.  Generally, we are
    % setting the property that is before any 'underscore'
    keyTypeName = strsplit(thisKey, '_');

    % Sometimes the first part of 'TYPE_NAME' is the key, and other
    % times the second part.  For example, rgb spd, versus spd
    % spectrum.
    if piLightISParamType(keyTypeName{1})
        % Permissible.  Get the second.
        keyName = ieParamFormat(keyTypeName{2});
    else
        keyName = ieParamFormat(keyTypeName{1});
    end

    % If the light has a slot with the keyName, we run piLightSet.
    if isfield(lght, keyName)
        % If the field exists, we set it.
        lght = piLightSet(lght, sprintf('%s value', keyName),...
                              thisVal);
    else
        % If the field does not exist, we tell the user, but do not
        % throw an error.
        warning('Parameter %s does not exist in light %s',...
                    keyName, lght.type)
    end
end

end
