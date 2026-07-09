function figHdl = plot(rays,pType,varargin)
% Ray plotting utilities
%
% Inputs
%   rays:  rayC
%   pType:  Plot type
%
% Optional Key/val pairs
%   wave:    Which wavelength to plot
%   figHdl:  Figure for plotting
%
% Output 
%   figHdl
%
% Plot type
%    origin
%    endpoint
%    entrance pupil
%    middle pupil
%    exit pupil
%
% See also
%


%%
p = inputParser;

p.addRequired('rays',@(x)(isa(x,'rayC')));
p.addRequired('pType',@ischar)
p.addParameter('wave',550,@isscalar);
p.addParameter('figHdl',[],@(x)(isa(x,'matlab.ui.Figure')));

p.parse(rays,pType,varargin{:});
wave   = p.Results.wave;
figHdl = p.Results.figHdl;

if isempty(figHdl), figHdl = ieNewGraphWin; end

%% Switch to relevant plot

pType = ieParamFormat(pType);
switch pType
    case 'origin'
        idx = rays.wave2index(wave);
        origin = rays.get('origin','wave index',idx);
        plot(origin(:,1),origin(:,2),'.'); 
        grid on; axis equal; xlabel('Position (mm)'); ylabel('Position (mm)');
        
    case 'endpoint'
        % Not sure I understand the whole endpoint, direction, distance
        % situation yet.  But this might look something like this some day.
        disp('Warning.  Endpoint not really understood yet')
        idx = rays.wave2index(wave);
        origin    = rays.get('origin','wave index',idx);
        direction = rays.get('direction','wave index',idx);
        distance  = rays.get('distance','wave index',idx);
        
        % New Matlab handles the multiplication correctly
        endpoint = origin + bsxfun(@times,distance,direction);
        plot(endpoint(:,1),endpoint(:,2),'.');
        grid on; xlabel('Position (mm)'); ylabel('Position (mm)');
        
    case 'entrancepupil'
        % Sample points in the entrance pupil - xy coordinates in
        % millimeters
        xy = rays.aEntranceInt.XY;
        plot(xy(:,1),xy(:,2),'.');
        axis equal
        grid on; axis equal; xlabel('Position (mm)'); ylabel('Position (mm)');

    case 'middlepupil'
        % Sample points in the entrance pupil - xy coordinates in
        % millimeters
        xy = rays.aMiddleInt.XY;
        plot(xy(:,1),xy(:,2),'.');
        axis equal
        grid on; axis equal; xlabel('Position (mm)'); ylabel('Position (mm)');
        
    case 'exitpupil'
        % Sample points in the exit pupil - xy coordinates in
        % millimeters
        xy = rays.aExitInt.XY;
        plot(xy(:,1),xy(:,2),'.');
        axis equal
        grid on; axis equal; xlabel('Position (mm)'); ylabel('Position (mm)');
        
    otherwise
        error('Unknown plot type %s\n',pType);
end

end
