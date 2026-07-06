function [obj, fHdl] =  draw(obj, fHdl, lColor)
% Draw the the multi-element lens surfaces and microlens in a graph window
%
% Syntax
%   lens.draw
%
% Brief description
%   Draw a set of curves showing the lens surfaces (cross section view).
%   If there is a microlens field, then the figure is drawn with two
%   panels, for the imaging lens and the microlens.
%   Tip:
%       The position of shutter is the place where the aperture size is
%       zero.
%
% Parameters
%  obj  -   A lens object
%  fHdl -   A figure handle or a subplot description.  
%           called and that figure handle is set in the lens object
%           field fHdl 
%  lColor - RGB value of lens lines (lens color).  Default is black [0 0 0]
%
% AL/BW Vistasoft Team, Copyright 2014
%
% See also:  
%    psfCameraC.draw
%

%{
  thisLens = lensC('filename','2ElLens.json');
  thisLens.draw;                          % A window of its own
  thisLens.draw([1,2,1]);                 % In a subplot
  thisLens.draw(ieNewGraphWin,[0 0 1]);   % Blue lenses
  thisLens.draw([1,2,1],[0 0 1]);         % Subplot and a Blue lenses
%}

%% Create the figure and set the parameters

useSubplot = false; % default
drawLegend = true; % default
if ~exist('fHdl','var'), fHdl = ieNewGraphWin; axis equal;
elseif isempty(fHdl)     % Do nothing
elseif isa(fHdl,'double') 
    % User sent in a 3-vector describing the subplot dimensions and panel
    assert(numel(fHdl) == 3);
    thisF = ieNewGraphWin;
    subplot(fHdl(1),fHdl(2),fHdl(3));    
    fHdl = thisF;    
    drawLegend = false; % overlays graphic when in a subplot
else,                    figure(fHdl); % Raise the figure
end
obj.fHdl = fHdl;
if ~exist('lColor','var'), lColor = [0 0 0]; end

%% Draw one surface/aperture at a time

if ~isempty(obj.microlens)
    subplot(1,2,1);
end
idx = obj.get('aperture index');

nSurfaces = obj.get('n surfaces');
for lensEl = 1:nSurfaces
    % Get each surface element and draw it
    curEl = obj.surfaceArray(lensEl);
    if lensEl == idx
        curEl.draw('fig',gcf,'color',[1 0.2 0]);
    else
        curEl.draw('fig',gcf,'color',lColor);
    end
end

% Make sure the surfaces are all shown within the range
%
% We believe that maxx and maxy are always positive, and minx and miny are
% always negative.  But maybe we should deal with the sign issue here for
% generality in the future.  If you have a bug, that might be.

% X axis limits
t = obj.get('total offset'); 
set(gca,'xlim',[-1.1,0.1]*t)

% Y axis limits should be from aperture
% Not yet set, but could be

% HACK: Set the window NAME to the lens name.  Setting the subplot stitle
% takes up too much space on the drawing.  We assume that the name of the
% microlens begins with 'microlens'.  If so, don't run this line.
if ~strncmp(obj.name,'microlens',9)
    set(gcf,'Name',sprintf('%s',obj.name))
end

axis image
xlabel('mm'); ylabel('mm');
title(sprintf('Lens:  %s\n',obj.get('name')));

%% Set Focal point, principle point and nodal point
hold all

% Image focal point
p1 = pointVisualize(obj, 'image focal point', 'p size', 10, 'color', 'b');

% Image principle point
p2 = pointVisualize(obj, 'image principal point', 'p size', 10, 'color', 'g');

% Image nodal point
p3 = pointVisualize(obj, 'image nodal point', 'p size', 5, 'color', 'r');

% we don't have room for the legend in a typical sub-plot:
if drawLegend
    legend([p1 p2 p3],...
        {'Image focal point', 'Image principal point', 'Image nodal point'});
end
%% Now the microlens
if isempty(obj.microlens)
    return;
else
    microlens = obj.microlens;
    subplot(1,2,2);
    microlens.draw('');
end

end
