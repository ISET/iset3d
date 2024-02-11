function material = piMaterialSet(material, param, val, varargin)
% Set a material property.
%
% Brief description:
%   Material set is based on param (material.(param).value) unlike
%   many others in which the param is from a fixed set.
%
% Synopsis
%    material = piMaterialSet(material, param, val, varargin)
%
% Brief description
%   Set one of the material properties.
%
% Inputs:
%   material    - material struct.
%   param       - material property
%   val         - property value
%
% Optional key/value pairs
%   type        - property type
%   val         - property val
%
% Returns
%   material    -  modified material struct
%
% See also
%   piMaterialGet, piMaterial*

% Examples:
%{
    mat = piMaterialCreate('new material', 'kd', [400 1 800 1]);
    mat = piMaterialSet(mat, 'kd val', [1 1 1]);
    mat = piMaterialSet(mat, 'kd', [0.5 0.5 0.5]);
%}

%% Parse inputs

% check the parameter name and type/val flag
nameTypeVal = strsplit(param, ' ');
pName    = lower(nameTypeVal{1});

% Whether it is specified to set a type or a value.
if numel(nameTypeVal) > 1
    pTypeVal = nameTypeVal{2};
elseif isstruct(val)
    % Set a whole struct
    pTypeVal = '';
elseif ischar(nameTypeVal{1})
    % If nameTypeVal has only one part and it is a name of a field
    pTypeVal = 'val';
end

p = inputParser;
p.addRequired('material', @(x)(isstruct(x)));
p.addRequired('param', @ischar);
p.addRequired('val', @(x)(ischar(x) || isstruct(x) || isnumeric(x) || islogical(x) || iscell(x)));

p.parse(material, param, val, varargin{:});

%% if obj is a possible material struct
if isfield(material,pName)
    % Set name or type
    if isequal(pName, 'name') || isequal(pName, 'type')
        material.(pName) = val;
        return;
    end

    % Set a whole struct
    if isempty(pTypeVal)
        material.(pName) = val;
        return;
    end

    % Set parameter type
    if isequal(pTypeVal, 'type')
        material.(pName).type = val;
        return;
    end

    % Set parameter value
    if isequal(pTypeVal, 'value') || isequal(pTypeVal, 'val')
        material.(pName).value = val;

        % Changing property type if the user doesn't specify it.
        if isnumeric(val)
            if numel(val) == 3
                material.(pName).type = 'rgb';
            elseif numel(val) > 3
                if piMaterialISEEM(val)
                    material.(pName).type = 'photolumi';
                else
                    material.(pName).type = 'spectrum';
                end
            else
                % if not a rgb or specrum type, it's a single float.
                material.(pName).type = 'float';
            end
        elseif ischar(val)
            % It is a file name. We decode what it is from the
            % extension and maybe a string in the name itself or the
            % pName.

            [~, ~, e] = fileparts(val); % Check extension

            % This is a stored list of named spectral.  We are not
            % sure who is updating this or how this got here.  ZL?
            pbrtSpectra = load('namedSpectra.mat');

            if isequal(e, '.spd') || ~isempty(find(piContains(pbrtSpectra.namedSpectra,val), 1))
                material.(pName).type = 'spectrum';
            elseif isequal(e, '.bsdf') % not sure whether other type of files are supported
                material.(pName).type = 'string';
            elseif isequal(e, '.png')
                if ~contains(param,'normalmap')
                    material.(pName).type = 'texture';
                else
                    material.(pName).type = 'string';
                end
            elseif isequal(pName, 'normalmap')
                material.(pName).type = 'string';
            else
                material.(pName).type = 'texture';
            end
        elseif islogical(val)
            % Logical!
            material.(pName).type = 'bool';
        end
    end
else
    warning('Parameter: %s does not exist in material type: %s',...
                pName, material.type);
end

end
