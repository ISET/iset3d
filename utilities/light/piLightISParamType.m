function val = piLightISParamType(str)
%   Check if a string is light property type
% 
% Synopsis:
%   val = piLightIsParamType(str)
%
% Brief description:
%    The light struct slots can have string names like 'rgb spd'. This
%    function validates whether the string is one of the permissible
%    types that is part of such a pair.
%  
% Inputs:
%   str - a string
%
% Returns:
%   val - bool

%% parse input
p = inputParser;
p.addRequired('str', @ischar);
p.parse(str);

str = ieParamFormat(str);

%%
paramTypes = {'string', 'float', 'integer', 'point', 'shape', 'bool',...
            'spectrum', 'rgb', 'color'};
val = ismember(str, paramTypes);

end
