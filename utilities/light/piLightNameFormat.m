function newLghtName = piLightNameFormat(lghtName)
% The node in the asset tree has an '_L'
%
% See also
%   piLightPrint, recipeGet('lights','names')

if ~isequal(lghtName(end-1:end), '_L') && ~isequal(lghtName, 'all')
    newLghtName = [lghtName, '_L'];
else
    newLghtName = lghtName;
end
end