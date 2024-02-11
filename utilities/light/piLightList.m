function nLights = piLightList(thisR)
% Print list of lights in the recipe
%
% Deprecated.  Use piLightPrint
%
% 
% Synopsis
%   nLights = piLightList(thisR)
%
% To list all the lights or their IDs use
%
%   thisR.get('lights')
%   thisR.get('lights','names')
%   thisR.get('lights','names id')
%   thisR.get('lights','names simple')
%
% For a single light, use
%
%   thisR.get('light',id,'name')
%   thisR.get('light',id,'name simple')
% 

nLights = thisR.get('n lights');
if nLights == 0
    disp('---------------------')
    disp('No lights listed in this recipe');
    disp('---------------------')
else
    disp('---------------------')
    disp('*****Light Type******')
    lightNames = thisR.get('light', 'names');
    for ii = 1:numel(lightNames)
        fprintf('%d: name: %s     type: %s\n', ii,...
            lightNames{ii}, thisR.get('light', lightNames{ii}, 'type'));
    end
    disp('*********************')
    disp('---------------------')
end

end
