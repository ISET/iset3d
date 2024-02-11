function medium = piMediumCreate(name, varargin)


%% Special case
validmedia = {'homogeneous'};

%% Replace the space in parameters.

% For example, 'rgb kd' won't pass parse with the space, but we need the
% two parts in the string apart to extract type and key. So we replace
% space with '_' and use '_' as key word.
for ii=1:2:numel(varargin)
    varargin{ii} = strrep(varargin{ii}, ' ', '_');
end

%% Parse inputs
p = inputParser;
p.addRequired('name', @ischar);
p.addParameter('type', 'homogeneous', @(x)(ismember(x,validmedia)));
p.KeepUnmatched = true;
p.parse(name, varargin{:});

tp = ieParamFormat(p.Results.type);

medium.name = name;

switch tp
    % Different materials have different properties
    case 'homogeneous'
        % This has defaults.  Maybe they should be here?
        medium.type = 'homogeneous';

        medium.g.type = 'float';
        medium.g.value = [];
        
        medium.Le.type = 'spectrum';
        medium.Le.value = [];
        
        medium.Lescale.type = 'float';
        medium.Lescale.value = [];
        
        medium.preset.type = 'string';
        medium.preset.value = '';
        
        medium.sigma_a.type = 'spectrum';
        medium.sigma_a.value = [];
        
        medium.sigma_s.type = 'spectrum';
        medium.sigma_s.value = [];
        
        medium.scale.type = 'float';
        medium.scale.value = [];

end

%% Put in key/val

for ii=1:2:numel(varargin)
    thisKey = varargin{ii};
    thisVal = varargin{ii + 1};

    if isequal(thisKey, 'type')
        % Skip since we've taken care of material type above.
        continue;
    end

    keyTypeName = strsplit(thisKey, '_');

    % keyName is the property name. if it follows 'TYPE_NAME', we need
    % later, otherwise we need the first one.
    if piMaterialIsParamType(keyTypeName{1})
        keyName = ieParamFormat(keyTypeName{2});
    else
        keyName = ieParamFormat(keyTypeName{1});
    end

    if isfield(medium, keyName)
        medium = piMaterialSet(medium, sprintf('%s value', keyName),...
            thisVal);
    else
        warning('Parameter %s does not exist in medium %s',...
            keyName, medium.type)
    end
end

end
