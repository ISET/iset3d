function properties = piMaterialProperties(materialType)
% Return the properties of a particular material type
%
% Synopsis
%   properties = piMaterialProperties(materialType)
%
% Input
%   materialType:   See the possible material types using
%      piMaterialCreate('list available types')
%
% Optional key/val
%   N/A
%
% Return
%   properties:  Cell array of material properties
%
% See also
%   piMaterialCreate
%

% Examples:
%{
materialType = 'coateddiffuse';
piMaterialProperties(materialType)
%}
%{
materialType = 'hair';
piMaterialProperties(materialType)
%}
%{
materialType = 'mix';
piMaterialProperties(materialType)

%}

%% Check that the material type is valid

allTypes = piMaterialCreate('list available types');
ii =  find(contains(allTypes,materialType));  %#ok<EFIND>
if isempty(ii)
    error('Not a recognized material type: %s\n',materialType);
end

%% If so, create it and return the field names

thisMaterial = piMaterialCreate('thisName','type',allTypes{ii});
properties = fieldnames(thisMaterial);

end
