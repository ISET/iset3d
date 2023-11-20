function [pts, radius, pRA] = piRotateFrom(thisR,direction,varargin)
% Return a set of points that sample around the from direction
%
% Synopsis
%    [pts, radius, pRA] = = piRotateFrom(thisR,direction,varargin)
%
% Brief description
%  Sample points with respect to a direction vector whose endpoint is at
%  the recipe 'from' location. The first and last point are the same, so
%  nsamples 4 returns a triangle. The sample points can be either on a
%  circle around the direction vector or on a planar grid perpendicular to
%  the direction vector.
%
%  (Maybe there should be an option to not duplicate first and last).
%
% Inputs
%   thisR     - Recipe
%   direction - vector direction to rotate around
%
% Optional key/val
%   n samples - Number of points.  For circle first=last.  For grid, nxn
%               samples
%   show      - Plot the 3D graph showing the sampled 'from' points
%   radius    - Circle radius of the sample points, or if grid this
%               overloaded to be the width of the grid.  We should change.
%   degrees   - Circle radius specified in degs from the 'from-to' line
%   method    - 'circle' or 'grid'.  
%
% Output
%   pts - Sample points in 3-space
%   radius -
%   pRA - vectors defining the plane perpendicular to the direction
%
% Description
%   More words needed for sampling method, radius and degree parameters.  n
%   samples is the number of samples on the circle or an n x n grid
%   centered on the 'from'.
%   
% See also
%   oiLights (oraleye), t_arealightArray

% Examples:
%{
thisR = piRecipeDefault('scene name','chessset');
direction = thisR.get('fromto');
n = 20;
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'show',true);
thisR.set('from',[0 0.2 0.2]);

% The plane is no longer perpendicular to the direction.  Why?
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'show',true);

%}
%{
thisR = piRecipeDefault('scene name','chessset');
direction = thisR.get('fromto');
n = 4;
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'method','grid','show',true);
%}
%{
direction = thisR.get('up');
n = 35;
pts = piRotateFrom(thisR, direction,'n samples',n, 'show',true);
%}
%{
direction = [0 0 1]
n = 4;
pts = piRotateFrom(thisR, direction,'n samples',n, 'radius',1,'show',true);
%}
%{
n = 5;
direction = thisR.get('up');
pts = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'method','grid','show',true);
%}
%{
n = 10;
pts = piRotateFrom(thisR, direction,'n samples',n);
%}
%% Parse parameters

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addRequired('direction',@isvector);
p.addParameter('nsamples',5,@isnumeric);
p.addParameter('radius',[],@isnumeric);      % derived from deg or spec'd
p.addParameter('degrees',5,@isnumeric);      % 5 degree radius if a circ
p.addParameter('show',false,@islogical);
p.addParameter('method','circle',@(x)(ismember(x,{'circle','grid'})));

p.parse(thisR,direction,varargin{:});
nSamples = p.Results.nsamples;
show     = p.Results.show;
radius   = p.Results.radius;
degrees  = p.Results.degrees;
method   = p.Results.method;

% The radius is part of the triangle tan(theta) = opposite/adjacent
% We use it for a circle, or we use it as the sample distance between a
% grid of nSample x nSample points
if isempty(radius)
    % The angle is tand(theta) = radius/(fromto distance);
    radius = thisR.get('fromto distance')*tand(degrees);
end

%% Circle in the z=0 plane
switch method
    case 'circle'
        [x,y] = ieCirclePoints(2*pi/(nSamples-1));
        z = zeros(numel(x),1)';
        C = radius * [x(:),y(:),z(:)]';
    case 'grid'
        % nSample^2 points, centered on lookat
        [x,y] = meshgrid(1:nSamples,1:nSamples);
        x = x - mean(x(:)); y = y - mean(y(:));
        z = zeros(numel(x),1)';
        C = radius*[x(:),y(:),z(:)]';        
    otherwise
        error('Unknown sampling method %s.',method);
end

%{
ieNewGraphWin;
plot3(x,y,z,'o');
axis equal; grid on;
%}

% Make sure direction is a unit vector
direction = direction/norm(direction);

% Plane perpendicular to direction
pRA = null(direction(:)');
basisAround = [pRA,direction(:)];

% Find the coordinates in the Around frame
%
%   C = basisAround * Caround;
%
% These should be a circle perpendicular to the direction direction.
% I thought there should be a transpose here, but ...
Caround = basisAround * C;

%{
ieNewGraphWin;
plot3(Caround(1,:),Caround(2,:),Caround(3,:),'o')
hold on;
line([0 direction(1)],[0 direction(2)],[0 direction(3)],'Color','b');
axis equal; grid on;
%}

% Shift the center of the circle to be centered at the from position
pts = Caround + thisR.get('from')';

if show
    % The from (black), to (green) connected by a black line
    % The pts (red)
    % The direction line (blue)
    ieNewGraphWin;
    plot3(pts(1,:),pts(2,:),pts(3,:),'o');  % The points 
    hold on;
    
    from = thisR.get('from');

    % {
    % The direction line.  Often equal to the fromto line
    tmp = from + direction;
    line([from(1) tmp(1) ],[from(2) tmp(2)],[from(3) tmp(3)],...
        'Color','b', ...
        'LineStyle',':');
    hold on;
    %}

    % The from-to direction - often the same as the direction line
    plot3(from(1),from(2),from(3),'bo');
    to = thisR.get('to');
    plot3(to(1),to(2),to(3),'go');

    line([from(1),to(1)],[from(2),to(2)],[from(3),to(3)],'Color','k','LineStyle','--');

    axis equal; grid on; rotate3d;
end

end

%%