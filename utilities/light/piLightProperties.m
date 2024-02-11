function properties = piLightProperties(lightType,varargin)
%  Prints a list of properties for a given light type
%
% Synopsis
%    properties = piLightProperties(lightType,varargin);
%
% Input
%
% lightType -  Use piLightCreate('list available types') for the possible
%     types.
%
% Optional key/val
%    quiet - Just return the properties, no print out.  Default false.
%
% Return
%    properties - cell array of light properties
%
% See also
%   piLightCreate

% Examples:
%{
   piLightProperties('spot');
%}
%{
   properties = piLightProperties('goniometric');
%}
%{
   properties = piLightProperties('point','quiet',true);
%}

%% Parse

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('lightType',@ischar);
p.addParameter('quiet',false,@islogical);

p.parse(lightType,varargin{:});

%% Create a light of that type
thisLight = piLightCreate('ignoreMe','type',lightType);

% Here are its field names, which we return
properties = fieldnames(thisLight);

if ~p.Results.quiet
    fprintf('\n\nLight type:  %s\n----------\n',lightType);
    for ii=1:numel(properties)
        fprintf('  %s\n',properties{ii});
    end
    fprintf('----------\n');
end

end
