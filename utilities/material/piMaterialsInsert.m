function thisR = piMaterialsInsert(thisR,varargin)
% Insert preset materials into a recipe
%
% Synopsis
%  thisR = piMaterialsInsert(thisR,varargin)
%
% Brief description
%   Add a collection of materials or individual material to use for
%   a recipe.
%
% Input
%   thisR - Recipe
%
% Optional key/val
%   groups - Cell array of material groups
%   names  - Cell array of specific material names
%   verbose - Print out
%
% Output
%   thisR - ISET3d recipe with the additional materials inserted
%      To see the current list of materials in a recipe use
%
%           thisR.get('print  materials')
%
% Description
%   The materials are created in piMaterialPresets. That routine
%   also enables you to list out the available presets by
%
%       piMaterialPresets('list');
%
%   The major categories may change as we get better over time.  The
%   already include glass, metal, diffuse, glossy, fabric, wood, brick,
%   marble.
%
% See also
%    piMaterialPresets

% TODO
%  Check to avoid over-write when the material exists already.

% Examples:
%{
 thisR = piRecipeDefault('scene name','chessset');
 piMaterialsInsert(thisR,'names',{'wood-medium-knots'}); 
 thisR.get('print materials');
%}
%{
 thisR = piRecipeDefault('scene name','chessset');
 piMaterialsInsert(thisR,'groups',{'testpatterns'}); 
 thisR.get('print materials');
%}
%{
 thisR = piRecipeDefault('scene name','chessset');
 piMaterialsInsert(thisR,'groups',{'testpatterns'},'names',{'glass-bk7'}); 
 thisR.get('print materials');
%}

%% Parse
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('groups','',@(x)(iscell(x) || ischar(x)));
p.addParameter('names','',@(x)(iscell(x) || ischar(x)));
p.addParameter('verbose',false,@islogical);

p.parse(thisR,varargin{:});

% Decides which class of materials to insert
mType  = p.Results.groups;
mNames = p.Results.names;

% Make a char into a single entry cell
if ischar(mType), mType = {mType}; end
if ischar(mNames), mNames = {mNames}; end



%% We should have either material type (mType) or material names (mNames)

% Individually named materials
if ~isempty(mNames{1})

    % Remove the mNames entries that are already present, informing the
    % user.
    Names = thisR.get('material', 'names');

    % A 1 entry in lst means the name is already present in the recipe.
    % contains unfortunately seems to match on a 0 cell
    lst = matches(mNames,Names);
    if sum(lst) > 0
        fprintf('Materials already in the recipe\n  %s  \n',mNames{lst});
    end

    % Preserve the names that are NOT in the recipe.
    mNames = mNames(~lst);

    for ii=1:numel(mNames)
        
        newMat = piMaterialPresets(mNames{ii},mNames{ii});
        thisR.set('material','add',newMat);

        % Some materials are more complex and require a mixture of
        % secondary materials.  These are returned in the mixMat slot.  We
        % add each of those materials as well.  You only set the main
        % material, but when it is set it uses the mixture materials as
        % part of its definition.
        if isfield(newMat,'mixMat')
            for jj=1:numel(newMat.mixMat)
                thisR.set('material','add',newMat.mixMat{jj});
            end
        end
    end
end

% Material types, not individual materials.
if ~isempty(mType{1})
    for ii=1:numel(mType)
        thisGroup = ieParamFormat(mType{ii});
        if ismember(thisGroup,{'all','glass'})
            glass = piMaterialPresets('glass list');
            for gg = 1:numel(glass)
                newMat = piMaterialPresets(glass{gg},glass{gg});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','metal'})
            metals = piMaterialPresets('metal list');
            for me = 1:numel(metals)
                newMat = piMaterialPresets(metals{me},metals{me});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','diffuse'})
            diffuse = piMaterialPresets('diffuse list'); 
            for dd = 1:numel(diffuse)
                newMat = piMaterialPresets(diffuse{dd},diffuse{dd});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','glossy'})
            glossy = piMaterialPresets('glossy list');
            for gl = 1:numel(glossy)
                newMat = piMaterialPresets(glossy{gl},glossy{gl});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','wood'})
            woods = piMaterialPresets('wood list');
            for ww = 1:numel(woods)
                newMat = piMaterialPresets(woods{ww},woods{ww});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','brick'})
            bricks = piMaterialPresets('brick list');
            for bb = 1:numel(bricks)
                newMat = piMaterialPresets(bricks{bb},bricks{bb});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','marble'})
            marbles = piMaterialPresets('marble list');
            for mm = 1:numel(marbles)
                newMat = piMaterialPresets(marbles{mm},marbles{mm});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(thisGroup,{'all','testpatterns'})
            testpatterns = piMaterialPresets('testpatterns list');
            for tp = 1:numel(testpatterns)
                newMat = piMaterialPresets(testpatterns{tp},testpatterns{tp});
                thisR.set('material', 'add', newMat);
            end
        end

    end
end

% Show a summary of the materials in this recipe, when set.
if p.Results.verbose
    thisR.get('print materials');
end

end