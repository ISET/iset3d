function [coords,boxRange,hdl] = piAssetGeometry(thisR,varargin)
% Plot the object world positions, along with auxiliary information
%
% Synopsis
%  [coords,boxRange,hdl] = piAssetGeometry(thisR,vararign)
%
% Input
%   thisR - ISET3d recipe
%
% Optional key/val
%   size - Logical, add size to graph (default false)
%   name - Logical, add name to graph (default true)
%   position - World coordinates (default false)
%   inplane  - Default view, either 'xz' or 'xy' plane
%   show     - Show (or not) the image; used to just return coords and boxRange
%
% Outputs
%    coords   - Coordinates of the object positions
%    boxRange - Bounding box around all the objects - about 10 percent
%               bigger than the true range
%               dim 1 min max; dim 2 min max; dim 3 min max; 
%    hdl - Figure handle
%
% To set the xz plane or xy plane views use
%   xz plane view(0,0)
%   xy plane view(0,90) or view(0,270)
%
% Other useful views - RIght click for X-Y, X-Z and Y-Z
%  az = 180, el = -60
%  az = 0, el = 22;
%  az = -180, 0
%  az = 5, el = 14
%
% See also
%  thisR.get('objects')
%

% Examples:
%{
   thisR = piRecipeDefault('scene name','simplescene');
   coords = piAssetGeometry(thisR);
%}
%{
   thisR = piRecipeDefault('scene name','chessset');
   coords = piAssetGeometry(thisR,'size',true);
%}
%{
   thisR = piRecipeDefault('scene name','macbethchecker');
   coords = piAssetGeometry(thisR,'inplane','xz');
%}

%%  Check that we have assets
if isempty(thisR.assets)
    warning('No assets stored in the recipe');
    coords = [];
    return;
end

%% Parser
p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('size',false,@islogical);
p.addParameter('name',true,@islogical);
p.addParameter('position',false,@islogical);
p.addParameter('inplane','xz',@ischar);
p.addParameter('show',true,@islogical);

p.parse(thisR,varargin{:});

show = p.Results.show;

%% Find names and positions of objects and lights

objectcoords = thisR.get('object coordinates');   % World coordinates, meters of each object
objectnames  = thisR.get('object simple names');  % We might do a better job with this.
shapesize = thisR.get('object sizes');

% We plot points for objects and lights differently
nObjects = numel(objectnames);

% World coordinates, meters of each light.  Also the simple names
lightInfo = thisR.get('light positions');   

if isfield(lightInfo,'names')
    % If there are lights specified ...
    names = cat(1,objectnames{:},lightInfo.names{:});
    coords = cat(1,objectcoords,lightInfo.positions);
else
    names  = objectnames;
    coords = objectcoords;
end

% The notes we plot alongside the objects.
notes = cell(size(names));
for ii=1:numel(notes), notes{ii} = ' '; end   % Start them out empty

%% Find the range of the three axes
lookat = thisR.get('lookat');

% Equation of the line is start + t*direction
% We draw the line from to for a lineLength
% direction  = thisR.get('lookat direction'); % lookat.to - lookat.from;
% start = lookat.from;
% viewDirection  = lookat.from + direction;

% Equation of the line is start + t*direction
% We draw the line from to for a lineLength
upDirection = lookat.up;
upDirection = upDirection/norm(upDirection);
upPoint  = lookat.from + upDirection;

% Find the range of each dimension, including the assets and the lookat
% positions.
boxMax = zeros(3,1);
boxMin = boxMax;
for ii=1:3
    boxMax(ii) = max([coords(:,ii)',lookat.to(ii),lookat.from(ii),upPoint(ii)]);
    boxMin(ii) = min([coords(:,ii)',lookat.to(ii),lookat.from(ii),upPoint(ii)]);
end

% Increase the box size just a bit, by default, one tenth of the range of
% each axis.  But if the min equals the max (happens rarely, but it happens
% for a plane) then set delta to 0.1;
delta = (boxMax - boxMin)*0.1;
delta(delta==0) = 0.1;
boxMax = boxMax + delta;
boxMin = boxMin - delta;

boxRange = [boxMin(1) boxMax(1); boxMin(2) boxMax(2); boxMin(3) boxMax(3)];

% If we are not making the figure, we are done here.
if ~show, return; end

%% Include names
if p.Results.name
    for ii=1:numel(names)
        notes{ii} = sprintf('%s',names{ii});
    end
end

%% Add positions of the objects and lights
if p.Results.position
    for ii=1:numel(names)
        notes{ii} = sprintf('%s (%.1f %.1f %.1f)p ',notes{ii},coords(ii,1),coords(ii,2),coords(ii,3));
    end
end

%% Add size
if p.Results.size
    for ii=1:numel(objectnames)
        notes{ii} = sprintf('%s (%.1f %.1f %.1f)s ',notes{ii},shapesize(ii,1),shapesize(ii,2),shapesize(ii,3));
    end
end

% Start out with legend text size equal to the asset names
legendtext = cell(numel(objectnames,1));

%% Open a figure to plot

% We should have no plot switch
hdl = ieNewGraphWin;


% Shift is a few percent of the range.  This should become a parameter
sx = (max(coords(:,1)) - min(coords(:,1)))*0.04;
sy = (max(coords(:,2)) - min(coords(:,2)))*0.04;
sz = (max(coords(:,3)) - min(coords(:,3)))*0.04;

if show
    % Plot the object and light coords
    for ii=1:numel(names)
        if ii <= nObjects
            hold on;
            plot3(coords(ii,1),coords(ii,2),coords(ii,3),'ko','MarkerSize',10,'MarkerFaceColor','k');
        else
            hold on;
            plot3(coords(ii,1),coords(ii,2),coords(ii,3),'k*','MarkerSize',10,'MarkerFaceColor',[0.3 0.3 0.3]);
        end
        text(coords(ii,1)+sx,coords(ii,2)+sy,coords(ii,3)+sz,notes{ii},'FontSize',14);
        legendtext{ii} = names{ii};
    end

%% The camera position (red) and where it is looking (green)
hold on;
plot3(lookat.from(1),lookat.from(2),lookat.from(3),'ro',...
    'Markersize',12,...
    'MarkerFaceColor','r');
legendtext{end+1} = 'from';

hold on;
plot3(lookat.to(1),lookat.to(2),lookat.to(3),'go',...
    'Markersize',12,...
    'MarkerFaceColor','g');
legendtext{end+1} = 'to';

start = lookat.from;
stop  = start + 5*thisR.get('lookat direction'); 
% Dashed line of site between them
line([start(1),stop(1)],...
    [start(2), stop(2)],...
    [start(3), stop(3)],'Color','k',...
    'Linestyle',':',...
    'Linewidth',2);
legendtext{end+1} = 'view direction';
 
%% Show the up direction

plot3(upPoint(1) ,upPoint(2),upPoint(3),'bo',...
    'Markersize',12,...
    'MarkerFaceColor','b');
legendtext{end+1} = 'up';

% Make the length of the from-up vector equal to the length of the
% from-to vector
d = thisR.get('fromto distance');
start = lookat.from;
stop  = upPoint;
delta = stop - start;
stop = start + (d/norm(delta))*delta;

line([start(1),stop(1)],...
    [start(2), stop(2)],...
    [start(3), stop(3)],'Color','m',...
    'Linestyle',':',...
    'Linewidth',2);
legendtext{end+1} = 'up direction';

%% Label the graph

xlabel('x coord (m)'); ylabel('y coord (m)'); zlabel('z coord (m)');
grid on
% axis equal; % Not sure we want this.  But maybe.

bName = thisR.get('input basename');
oType = thisR.get('optics type');
title(sprintf('%s (%s)',bName,oType));

%% By default set the xy plane view
switch lower(p.Results.inplane)
    case 'xy'
        view(0,270);
    case 'xz'
        % Good view when assets are rectified.
        view(-180,0);
end

% Set the axis dimensions of the view box
set(gca,'xlim',boxRange(1,:), 'ylim',boxRange(2,:), 'zlim',boxRange(3,:));

% Add the legend
legend(legendtext);

% Leave the window in the rotate mode
rotate3d;

end
