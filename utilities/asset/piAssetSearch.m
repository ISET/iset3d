function val = piAssetSearch(thisR,srchtype,param,varargin)
% A method to search through the assets, returning the indices
%
% Brief description
%  Search the asset list to find the node indices that meet a search
%  criterion specified by the param
%
% Synopsis
%    val = piAssetSearch(thisR,srchType,param)
%
% Inputs
%  thisR     - recipe
%  srchType  - string that defines the search
%              'object name', 'light name', 'material name', 'branch name'
%  param     - value of the string
%
% Optional key/val
%  'ignore case'  -  ignore case in the str (default: true)
%
% Output
%   val - numeric array of node indices meeting the conditions
%
% Description
%   We often want to find assets that meet a particular condition, such as
%   objects that have a string in their name, or use a specific material,
%   or whose positions are within a certain distance range.  We might then
%   change the material, set the camera to point at one of these assets,
%   and so forth. 
%
%   This is a slow method that searches through the assets finding the ones
%   that meet a criterion.  We have implemented these so far
%
%     object name -   Indices of objects whose name contains param
%     material name - Indices of objects whose material name contains param
%     light name - Indices of lights whose name contains param
%
% See also
%   piAssetFind

% Examples:
%{
 thisR = piRecipeDefault('scene name','chess set');

 idx = piAssetSearch(thisR,'object name','GroundMaterial');
 thisR.get('asset',idx)
%}
%{
 thisR = piRecipeDefault('scene name','chess set');
 thisR.set('skymap','sky-room.exr');
 idx = piAssetSearch(thisR,'light name','room')
 idx = piAssetSearch(thisR,'object name','plane')
 idx = piAssetSearch(thisR,'material name','Mrke_brikker_004')
 for ii=1:numel(idx)
   thisR.get('asset',idx(ii),'material name')
 end
%}

%% Parse the search parameters

srchtype = ieParamFormat(srchtype);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addRequired('srchtype',@ischar);

p.addParameter('ignorecase',true,@islogical);

p.parse(thisR,srchtype,varargin{:});

ignoreCase = p.Results.ignorecase;

%%  Start searching

val = [];

switch srchtype
    case {'objectname','objectnames','object'}
        % Material name or distance or name contains str
        oNames = thisR.get('object names');
        for ii=1:numel(oNames)
            if contains(oNames{ii},param,'IgnoreCase',ignoreCase)
                % This should be the Node index
                % Some seem to only have 4 digits?
                foundIndex = str2double(oNames{ii}(1:6));
                if isequaln(foundIndex, NaN)
                    foundIndex = str2double(oNames{ii}(1:4));
                end    
                val(end+1) = foundIndex; 
            end
        end
    case {'lightname','lightnames','light'}
        lNames = thisR.get('light','names id');
        for ii=1:numel(lNames)
            if contains(lNames{ii},param,'IgnoreCase',ignoreCase)
                val(end+1) = str2double(lNames{ii}(1:6)); 
            end
        end
    case {'branchname','branchnames','branch'}
        bNames = thisR.get('branch names');
        for ii=1:numel(bNames)
            if contains(bNames{ii},param,'IgnoreCase',ignoreCase)
                val(end+1) = str2double(bNames{ii}(1:6)); 
            end
        end
    case {'materialname','materialnames','material'}

        % Find the full material name
        mNames = thisR.get('material','names');
        for ii=1:numel(mNames)
            if contains(mNames{ii},param,'IgnoreCase',ignoreCase)
                fullmaterialName = mNames{ii}; 
                break
            end
        end

        % Loop through the object indices to find the ones with the material
        oID = thisR.get('objects');
        for jj=1:numel(oID)
            if contains(thisR.get('asset',oID(jj),'material name'),fullmaterialName)
                val(end+1) = oID(jj); %#ok<*AGROW> 
            end
        end

    otherwise
        error('Unknown or NYI search type %s',srchType);
end
    
end
