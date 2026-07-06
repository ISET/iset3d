function obj = recordOnFilm(obj,varargin)
% Record the point spread function onto the film
%
% Sets up the call to the raysC of either the standard rays or the ppsfRays
% to produce an image on the film object.  If the ppsfRays are empty, it
% uses the rays.
%
% Input parameters
%   rayType:  'rays' or 'ppsfRays'
%
% Example:
%   psfCamera.recordOnFilm;
%
% Wandell, CISET Team, 2016

%% Figure out ray type
p = inputParser;
permitted = {'rays','ppsfRays'};
p.addParameter('rayType',[],@(x)(ismember(x,permitted)));

p.parse(varargin{:});
rayType = p.Results.rayType;

if isempty(rayType)
    if isempty(obj.ppsfRays) && ~isempty(obj.rays)
        rayType = 'rays';
    elseif isempty(obj.rays) && ~isempty(obj.ppsfRays)
        rayType = 'ppsfRays';
    else
        error('Unable to determine ray type.');
    end
end

%% Execute
switch rayType 
    case 'rays'
        % Classic ray trace recording
        obj.rays.recordOnFilm(obj.film);
    case 'ppsfRays'
        % Plenoptic recording
        obj.ppsfRays.recordOnFilm(obj.film);
    otherwise
        error('Unknown ray type %s\n',rayType)
end

end
