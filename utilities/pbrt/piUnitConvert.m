function thisR = piUnitConvert(thisR, factor)
% Converts critical rendering units to meters.
%
%    thisR = piUnitConvert(thisR, factor)
%
% BW: I am not sure who wrote this.  It looks like the changes are
% from centimeters to meters.  Probably there should be a flag that
% specifies what the current units of the thisR might be.  Centimeters
% or millimeters are two options.
%
% This failed on the first scene I tried because it did not check for
% that the .scale parameter existed.
%
% See also
%

% scale camera position
thisR.lookAt.from = thisR.lookAt.from/factor;
thisR.lookAt.to = thisR.lookAt.to/factor;

% scale objects
for ii = 2:numel(thisR.assets.Node)
    thisNode = thisR.assets.Node{ii};
    if strcmp(thisNode.type, 'branch')
        % fix scale and translation
        if isnumeric(thisNode.scale)
            thisNode.scale = thisNode.scale/factor;
        elseif iscell(thisNode.scale)
            for j = 1:numel(thisNode.scale)
                thisNode.scale{j} = thisNode.scale{j}/factor;
            end
        else
            warning("Not sure how to adjust scale");
        end
        if isnumeric(thisNode.translation)
            thisNode.translation = thisNode.translation/factor;
        elseif iscell(thisNode.translation)
            for j = 1:numel(thisNode.translation)
                thisNode.translation{j} = thisNode.translation{j}/factor;
            end
        else
            warning("Not sure how to adjust translation");
        end
    end
    thisR.assets   = thisR.assets.set(ii, thisNode);
end
end
