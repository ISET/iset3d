function lght = piLightSet(lght, param, val, varargin)
% Set a light source parameter
%
% Synopsis
%  lght = piLightSet(lght, param, val, varargin)
%
% Inputs
%   lght:     An ISET3d light struct
%   param:    The parameter to set
%   val:      The new value
%
% Describe
%  The list of settable light parameters is determined by the light
%  parameters in PBRT. For v3 those were defined on this web-page
%
%      https://www.pbrt.org/fileformat-v3.html#lights
%
% There isn't yet a similar list that incorporates all the changes in v4.
%
% Here is a partial list and there are some examples below.  We seem to be
% missing the 'Projection' light type from our use cases (BW).
%
%  'type'  - The type of light source to insert. Can be the following:
%             'point'   - Casts the same amount of illumination in all
%                         directions. Takes parameters 'to' and 'from'.
%             'spot'    - Specify a cone of directions in which light is
%                         emitted. Takes parameters 'to','from',
%                         'coneangle', and 'conedeltaangle.'
%             'distant' - A directional light source "at
%                         infinity". Takes parameters 'to' and 'from'.
%             'area'    - convert an object into an area light. (TL: Needs
%                         more documentation; I'm not sure how it's used at
%                         the moment.)
%             'infinite' - A global illumination, infinitely far away, that
%                          potentially casts illumination from all
%                          directions. Takes no parameters.  Sometimes
%                          called a skymap and based on an exr file
%                          (mapname).
%
%  'spectrum'          - The spectrum that the light will emit. Read
%                          from ISETCam light data. See
%                          "isetcam/data/lights."
%  'specscale'         - scale the spectrum. Important for setting
%                          relative weights for multiple light sources.
%  'camera coordinate' - true or false. automatically place the light
%                            at the camera location.
%
%  To see the light types use
%
%      lightTypes = piLightCreate('list available types');
%
%  To see the settable properties for each light type use
%
%        piLightProperties(lightTypes{3})
%
% ieExamplesPrint('piLightSet');
%
% Zheng,BW, SCIEN, 2020 - 2021
%
% See also
%   piLightCreate, piLightProperties, piLightGet
%

% Examples:
%{
    lgt = piLightCreate('new light');
    lgt
    lgt = piLightSet(lgt, 'spd', 'D50');
    lgt.spd
    lgt = piLightSet(lgt, 'from', [10 10 10]);
    lgt.from

    val.value = 'D50';
    val.type  = 'spectrum';
    lgt = piLightSet(lgt, 'spd', val);
    lgt.spd

%}


%% Parse inputs

% check the parameter name and type/val flag
nameTypeVal = strsplit(param, ' ');
pName       = nameTypeVal{1};

if isstruct(val) && ~isequal(pName, 'shape')
    % The user sent in a struct, we will loop through the entries and set
    % them all. Shape is an exception, because it has to be stored as
    % struct
    pTypeVal = '';
else
    % Otherwise, we assume we are setting a specific val
    pTypeVal = 'val';

    % But we do allow the user to override the 'val'
    if numel(nameTypeVal) > 1
        pTypeVal = nameTypeVal{2};
    end
end

p = inputParser;
p.addRequired('lght', @isstruct);
p.addRequired('param', @ischar);
p.addRequired('val', @(x)(ischar(x) || isstruct(x) || isnumeric(x) ||...
                            islogical(x) || iscell(x)));

p.parse(lght, param, val, varargin{:});

%%
if isfield(lght, pName)
    % Set name, type or camera coordinate
    if isequal(pName, 'name') || isequal(pName, 'type') ||...
            isequal(pName, 'cameracoordinate')
        lght.(pName) = val;
        return;
    end

    % Set the whole struct
    if isempty(pTypeVal)
        lght.(pName) = val;
        return;
    end

    % Set parameter type
    if isequal(pTypeVal, 'type')
        lght.(pName).type = type;
        return;
    end

    if isequal(pName, 'from') || isequal(pName, 'to')
        lght.cameracoordinate = false;
    end

    % Set parameter value.  This code uses the pName as the slot in the
    % struct.  So, if you send in 'spread val' the assignment will be
    %
    %   thisStruct.spread = val
    %
    if isequal(pTypeVal, 'value') || isequal(pTypeVal, 'val')
        
        % Set the value, which is all we need for almost all cases
        lght.(pName).value = val;

        % Set the property type for the 'spd' or 'scale' case
        if isequal(pName, 'spd') || isequal(pName, 'scale')
            if numel(val) == 3 && ~ischar(val)
                % User sent in 3 values, so this is an rgb type light
                lght.(pName).type = 'rgb';
            elseif isscalar(val) && ~ischar(val)
                % User sent in 1 value so this is blackbody temperature
                lght.(pName).type = 'blackbody';            
            elseif numel(val) > 3 || ischar(val)
                if ischar(val) % || mod(numel(val), 2) == 0
                    % Do nothing
                elseif val(1) - val(3) == val(3) - val(5)
                    % Do nothing
                else % It only contains the spd data but not wavelength
                    error('No wavelength information, call piSPDCreate and send in return value instead');
                end
                % User sent in either
                %  * a numerical vector of (wave, val, wave, val)
                %  pairs or
                %  * a string that defines a spectrum or a spectral
                %  file.
                %
                % The possible strings include Equal Energy, Tungsten.
                % We are trying to make it possible the entry to be
                % any file that can be read by ieReadSpectra().  So,
                % if 'value' is a string, we read the file and use
                % piSPDCreate to fill in the data.
                lght.(pName).type = 'spectrum';
            end
            return;
        end
    end
else
    warning('Parameter: %s does not exist in light type: %s',...
                pName, lght.type);
end

end
