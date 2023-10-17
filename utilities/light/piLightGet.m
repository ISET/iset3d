function [val, txt] = piLightGet(lght, param, varargin)
% Read a light source struct in the recipe
%
% Description
%   piLightGet takes in a light struct and returns a value (first) and
%   the text that can be printed in the PBRT rendering file (usually
%   the geometry file).
%
% Synopsis
%    [val, txt] = piLightGet(lght, param, varargin)
%
% Inputs
%   lght  - light struct
%   param - parameter name
%
% Optional key/val:
%   pbrttext - flag of whether parse text for light
%
% Returns:
%   val - returns the value specified by the param
%   txt - The light text for pbrt files.  Convenient for piWrite.
%
% ZLY, SCIEN, 2020
%
% See also
%   piLightSet

% Examples:
%{
    lght = piLightCreate('new light');
    lght = piLightSet(lght, 'spd', 'D50');
    piLightGet(lght, 'spd struct')

    lght = piLightSet(lght, 'from', [10 10 10]);
    piLightGet(lght, 'from')

    piLightGet(lght, 'spd')        % Gets the value
    piLightGet(lght, 'spd type')   % Gets the type

    piLightGet(lght, 'from')
    piLightGet(lght, 'from type')

    piLightGet(lght,'spd struct')

%}

%% Parse inputs

% If there is a space, we want the first string for the parameter name.
nameTypeVal = strsplit(param, ' ');
pName       = nameTypeVal{1};

% If there is a second string after the space, save it to indicate whether
% we want to return the type or the value of this parameter.  The user can
% also indicate that they want the whole 'struct' back.
pTypeVal  = 'val';
if numel(nameTypeVal) > 1
    pTypeVal = nameTypeVal{2};
end

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('lght', @isstruct);
p.addRequired('param', @ischar);
p.addParameter('pbrttext', false, @islogical);

p.parse(lght, param, varargin{:});

pbrtText = p.Results.pbrttext;

%% How we return just the values
val = [];

if isfield(lght, pName)
    % If asking name, type or camera coordinate
    if (isequal(pName, 'name') || isequal(pName, 'type') ||...
            isequal(pName, 'cameracoordinate')) || isempty(pTypeVal)
        val = lght.(pName);
    elseif isequal(pTypeVal, 'type')
        val = lght.(pName).type;
    elseif isequal(pTypeVal,'struct')
        val = lght.(pName);
    elseif isequal(pTypeVal, 'value') || isequal(pTypeVal, 'val')
        val = lght.(pName).value;
    end
elseif strcmpi(lght.type, 'infinite')
    % do nothing
else
    warning('Parameter: %s does not exist in light type: %s',...
        param, lght.type);
end

% If the user didn't ask for text, we are done.
if nargout == 1, return; end

%% compose pbrt text
txt = '';
if pbrtText && ~isempty(val) &&...
        (isequal(pTypeVal, 'value') || isequal(pTypeVal, 'val') || isequal(pName, 'type')) ||...
        isequal(pTypeVal, 'struct')
    switch pName
        case 'type'
            if ~isequal(val, 'area')
                txt = sprintf('LightSource "%s"', val);
            else
                txt = sprintf('AreaLightSource "diffuse"');
            end
        case 'spd'
            spectrumScale = lght.specscale.value;
            
            % Maybe fix specscale earlier and more gnerally.
            if isempty(spectrumScale), spectrumScale = 1; end
            spectrumScale = 1; % tmp, we scale spd with a seperate paramter.
            if ischar(lght.spd.value)
                [~, ~, ext] = fileparts(lght.spd.value);
                if ~isequal(ext, '.spd')
                    % If the extension is not .spd, it indicates the
                    % spectrum is written out from isetcam, which is
                    % supposed to be in spds/lights. Otherwise, the spd
                    % file exists from the input folder already, it should
                    % be copied in the target directory.
                    
                    % use 'scale' to scale the radiance.
                    lightSpectrum = sprintf('"spds/lights/%s.spd"', ieParamFormat(lght.spd.value));
                else
                    lightSpectrum = sprintf('"%s"', lght.spd.value);
                end
            elseif isnumeric(lght.spd.value)
                txt = piNum2String(lght.spd.value * spectrumScale);
                lightSpectrum = ['[' ,txt,']'];
            end
            switch lght.type
                case {'point', 'goniometric', 'projection', 'spot', 'spotlight'} % I
                    txt = sprintf(' "%s I" %s', lght.spd.type, lightSpectrum);
                case {'distant', 'infinite', 'area'} % L
                    txt = sprintf(' "%s L" %s', lght.spd.type, lightSpectrum);
            end
        case 'from'
            txt = sprintf(' "point3 from" [%.4f %.4f %.4f]', val(1), val(2), val(3));
        case 'to'
            txt = sprintf(' "point3 to" [%.4f %.4f %.4f]', val(1), val(2), val(3));
        case 'mapname'
            % We think we replaced calls to mapname with filename
            warning('No mapname gets should be left.')
        case 'filename' 
            % Both the goniometric, projection, and skymaps have a
            % filename. 
            % 
            % Point, distant, infant, area, spot do not.
            %
            % We for goniometric in v4 this changed to filename from mapname
            % Below, mapname is for skymaps
            txt = sprintf(' "string filename" "%s"', val);

            % DJC Use skymaps only where they belong
            % but allow for instanced files
            if contains(val,'instanced/')
                prefix = '';
            elseif ~contains(val,'skymaps/'), prefix = 'skymaps/';
            else,                         prefix = '';
            end

            % in v4 this changed to filename from mapname
            txt = sprintf(' "string filename" "%s%s"', prefix, val);
        case 'fov'
            txt = sprintf(' "float fov" [%.4f]', val);
        case 'nsamples'
            txt = sprintf(' "integer nsamples" [%d]', val);
        case 'coneangle'
            txt = sprintf(' "float coneangle" [%.4f]', val);
        case 'conedeltaangle'
            txt = sprintf(' "float conedeltaangle" [%.4f]', val);
        case 'twosided'
            if val
                txt = sprintf(' "bool twosided" %s', 'true');
            else
                txt = sprintf(' "bool twosided" %s', 'false');
            end
        case 'shape'
            txt = piShape2Text(val);
        case 'power'
            txt = sprintf(' "float power" [%.4f]', val);
        case 'translation'
            txt = {}; % Change to cells
            % val can be a cell array
            if ~iscell(val)
                val = {val};
            end
            for ii=1:numel(val)
                txt{end + 1} = sprintf('Translate %.3f %.3f %.3f',...
                    val{ii}(1), val{ii}(2),...
                    val{ii}(3));
            end
        case 'rotation'
            % piLightGet(lgt,'rotation')

            % val can be a cell array
            if ~iscell(val)
                val = {val};
            end
            for ii = 1:numel(val)
                curRot = val{ii};
                [rows, cols] = size(curRot);
                if rows>cols
                    curRot = curRot';
                    rows = cols;
                end
                for rr = 1:rows
                    thisRot = curRot(rr,:);
                    txt{end + 1} = sprintf('Rotate %.3f %d %d %d', thisRot(1),...
                        thisRot(2), thisRot(3), thisRot(4));
                end
            end
        case 'ctform'
            % Not sure why the cell stuff became a problem here ...
            if ~iscell(val), val = {val}; end % BW
            for ii=1:numel(val)
                txt{end + 1} = sprintf('ConcatTransform [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]', val{ii}(:));
            end
        case 'scale'
            % Or here.
            % in pbrt-v4 scale appears to only take 1 parameter
            if ~iscell(val), val = {val}; end % BW
            for ii=1:numel(val)
                txt{end + 1} = sprintf('"float scale" %.3f', val{ii}(1));
            end
        case 'specscale'
%             if ~iscell(val), val = {val};end
            txt = sprintf(' "float scale" [%.5f]',val);
            
        case 'spread'
            txt = sprintf(' "float spread" [%.2f]',val);
    end
end

end
