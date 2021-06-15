function material = piMaterialCreate(name, varargin)
%%
%
% Synopsis:
%   material = piMaterialCreate(name, varargin);
%
% Brief description:
%   Create material with parameters.
%
% Inputs:
%   name  - name of the material
%
% Optional key/val:
%   type  - material type. Default is matte
%     The special case of piMaterialCreate('list available types') returns
%     the available material types.
%
%     Types of materials in PBRT v4:
%                                   diffuse
%                                   coateddiffuse
%                                   coatedconductor
%                                   diffusetransmission
%                                   dielectric
%                                   thindielectric
%                                   hair
%                                   conductor
%                                   measured
%                                   subsurface
%                                   mix
%
%
%   Other key/val pairs depend on the material.  To see the properties of
%   any specific material use
%            piMaterialProperties('materialType')
%
%   The material properties are set by key/val pairs. For keys. it
%   should follow the format of 'TYPE KEYNAME'. It's easier for us to
%   extract type and parameter name using space.
%   Syntax is:
%       material = piMaterialCreate(NAME, 'type', [MATERIAL TYPE],...
%                                   [PROPERTYTYPE PROPERTYNAME], [VALUE]);
%       material = piMaterialCreate(NAME, 'type', [MATERIAL TYPE],...
%                                   [PROPERTYNAME PROPERTYTYPE], [VALUE]);
%
% Returns:
%   material                  - created material
%
% ieExamplesRun('piMaterialCreate')
%
% See Also
% piMaterialRead.m, piMaterialGet

% Examples:
%{
    %
    material = piMaterialCreate('new material', 'type', 'kdsubsurface',...
                                'kd rgb',[1, 1, 1])
    material = piMaterialCreate('new material',...
                                'kd rgb',[1, 1, 1]);
    material = piMaterialCreate('new material', 'type', 'uber',...
                                'spectrum kd', [400 1 800 1]);
%}


%% Special case
if isequal(ieParamFormat(name),'listavailabletypes')
    material = {'matte','uber','plastic','metal','mirror','glass', ...
        'translucent','hair','kdsubsurface','disney','fourier', ...
        'mix','substrate','subsurface'};
    return;
end

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
p.addParameter('type', 'matte', @ischar);
p.KeepUnmatched = true;
p.parse(name, varargin{:});

tp = ieParamFormat(p.Results.type);
%% Construct material struct
material.name = name;

% Fluorescence EEM and concentration
material.fluorescence.type = 'photolumi';
material.fluorescence.value = [];

material.concentration.type = 'float';
material.concentration.value = [];

switch tp
    % Different materials have different properties
    case 'diffuse'
        material.type = 'diffuse';
        
        material.reflectance.type = 'spectrum';
        material.reflectance.value = [];
        
        material.sigma.type = 'float';
        material.sigma.value = [];
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
    case 'coateddiffuse'
        material.type = 'coateddiffuse';
        
        % base reflectance of material
        material.reflectance.type = 'spectrum';
        material.reflectance.value = [];
        
        % object's index of refraction
        material.eta.type = 'float';
        material.eta.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.roughness.type = 'float';
        material.roughness.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.uroughness.type = 'float';
        material.uroughness.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.vroughness.type = 'float';
        material.vroughness.value = [];
        
        material.remaproughness.type = 'bool';
        material.remaproughness.value = [];
        
        material.maxdepth.type = 'integer';
        material.maxdepth.value = [];
        
        material.nsamples.type = 'integer';
        material.nsamples.value = [];
        
        material.g.type = 'float';
        material.g.value = [];
        
        material.albedo.type = 'spectrum';
        material.albedo.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.thickness.type = 'float';
        material.thickness.value = [];
        
    case 'coatedconductor'
        material.type = 'coatedconductor';
        
        material.reflectance.type = 'spectrum';
        material.reflectance.value = [];
        
        material.remaproughness.type = 'bool';
        material.remaproughness.value = [];
        
        material.maxdepth.type = 'integer';
        material.maxdepth.value = [];
        
        material.nsamples.type = 'integer';
        material.nsamples.value = [];
        
        material.g.type = 'float';
        material.g.value = [];
        
        material.albedo.type = 'spectrum';
        material.albedo.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.thickness.type = 'float';
        material.thickness.value = [];
        
        material.interface_eta.type = 'float';
        material.interface_eta.value = [];
        
        material.interface_roughness.type = 'float';
        material.interface_roughness.value = [];
        
        material.interface_uroughness.type = 'float';
        material.interface_uroughness.value = [];
        
        material.interface_vroughness.type = 'float';
        material.interface_vroughness.value = [];
        
        material.conductor_k.type = 'float';
        material.conductor_k.value = [];
        
        material.conductor_eta.type = 'float';
        material.conductor_eta.value = [];
        
        material.conductor_roughness.type = 'float';
        material.conductor_roughness.value = [];
        
        material.conductor_uroughness.type = 'float';
        material.conductor_uroughness.value = [];
        
        material.conductor_vroughness.type = 'float';
        material.conductor_vroughness.value = [];
        
    case 'diffusetransmission'
        material.type = 'diffusetransmission';
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.reflectance.type = 'spectrum';
        material.reflectance.value = [];
        
        material.transmittance.type = 'spectrum';
        material.transmittance.value = [];
        
        material.sigma.type = 'float';
        material.sigma.value = [];
        
        material.scale.type = 'float';
        material.scale.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
    case 'dielectric'
        material.type = 'dielectric';
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
                % object's index of refraction
        material.eta.type = 'float';
        material.eta.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.roughness.type = 'float';
        material.roughness.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.uroughness.type = 'float';
        material.uroughness.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.vroughness.type = 'float';
        material.vroughness.value = [];
        
        material.remaproughness.type = 'bool';
        material.remaproughness.value = [];
        
         material.tint.type = 'spectrum';
        material.tint.value = [];       
        
    case 'thindielectric'
        material.type = 'thindielectric';
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
        material.eta.type = 'float';
        material.eta.value = [];
    case 'hair'
        material.type = 'hair';
        
        material.sigma_a.type = 'spectrum';
        material.sigma_a.value = [];
        
        material.color.type = 'spectrum';
        material.color.value = [];
        
        material.eumelanin.type = 'float';
        material.coeumelaninlor.value = [];
        
        material.pheomelanin.type = 'float';
        material.pheomelanin.value = [];
        
        material.eta.type = 'float';
        material.eta.value = [];
        
        material.beta_m.type = 'float';
        material.beta_m.value = [];
        
        material.beta_n.type = 'float';
        material.beta_n.value = [];
        
        material.alpha.type = 'float';
        material.alpha.value = [];
        
    case 'conductor'
        material.type = 'conductor';
        
        % base reflectance of material
        material.reflectance.type = 'spectrum';
        material.reflectance.value = [];
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.k.type = 'spectrum';
        material.k.value = [];
        
        material.eta.type = 'float';
        material.eta.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.roughness.type = 'float';
        material.roughness.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.uroughness.type = 'float';
        material.uroughness.value = [];
        
        % material's roughness affecting specular reflection & transmission
        material.vroughness.type = 'float';
        material.vroughness.value = [];
        
        material.remaproughness.type = 'bool';
        material.remaproughness.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
    case 'measured'
        material.type = 'measured';
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
        
        material.filename.type = 'string';
        material.filename.value = [];
    case 'subsurface'
        material.type = 'subsurface';
        
        material.displacement.type = 'texture';
        material.displacement.value = [];
        
        material.normalmap.type = 'string';
        material.normalmap.value = [];
 
        material.reflectance.type = 'texture';
        material.reflectance.value = [];
        
        material.mfp.type = 'texture';
        material.mfp.value = [];
        
        material.g.type = 'float';
        material.g.value = [];        
        
        material.roughness.type = 'float';
        material.roughness.value = [];
        
    case 'mix'
        material.type = 'mix';
        
        %  a cell array
        material.materials.type = 'string';
        % ["mat1" "mat2"]
        material.materials.value = [];
        
        material.amount.type = 'float';
        material.amount.value = [];
    otherwise
        warning('Material type: %s does not exist', tp)
        return;
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
    
    
    if isfield(material, keyName)
        material = piMaterialSet(material, sprintf('%s value', keyName),...
            thisVal);
    else
        warning('Parameter %s does not exist in material %s',...
            keyName, material.type)
    end
end

%%
%{
%% Get how many materials exist already
if isfield(thisR.materials, 'list')
    val = numel(piMaterialGet(thisR, 'print', false));
else
    val = 0;
end
idx = val + 1;


%% Construct material structure
material.name = strcat('Default material ', num2str(idx));
thisR.materials.list(material.name) = material;

if isempty(varargin)
    material.stringtype = 'matte';
    thisR.materials.list(material.name) = material;
else
    for ii=1:2:length(varargin)
        material.(varargin{ii}) = varargin{ii+1};
        piMaterialSet(thisR, idx, varargin{ii}, varargin{ii+1});
    end
end
%}
%%
%{
m.name = '';
m.linenumber = [];

m.string = '';
m.floatindex = [];

m.texturekd = '';
m.texturekr = '';
m.textureks = '';

m.rgbkr =[];
m.rgbks =[];
m.rgbkd =[];
m.rgbkt =[];

m.colorkd = [];
m.colorks = [];
m.colorreflect = [];
m.colortransmit = [];
m.colormfp = [];

m.floaturoughness = [];
m.floatvroughness = [];
m.floatroughness =[];
m.floateta = [];

m.spectrumkd = '';
m.spectrumks ='';
m.spectrumkr = '';
m.spectrumkt ='';
m.spectrumk = '';
m.spectrumeta ='';
m.stringnamedmaterial1 = '';
m.stringnamedmaterial2 = '';
m.texturebumpmap = '';
m.bsdffile = '';
m.boolremaproughness = '';

% Added photolumi for fluorescence materials
m.photolumifluorescence = '';
m.floatconcentration = [];
%}
end
