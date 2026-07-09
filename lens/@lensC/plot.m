function hdl = plot(obj,pType,varargin)
%@lens.plot - Gateway routine for lens object plotting.
%
% Syntax
%    lens.plot(...)
%
% Description:
%   Interface to plot different lens characteristics. 
%
% Plot types
%     'focal distance'
%
%   
% Wandell, ISETBIO, Feb. 2018
%
% See also:  lens.draw
%

%%

% Squeeze out the spaces and force slower case
pType    = ieParamFormat(pType);
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('pType',@ischar)
p.parse(pType,varargin{:});

pType = p.Results.pType;

%%
switch(pType)
    case 'focaldistance'
        % We used to plot the data in the FL files were constructed using
        % s_focusLensTable.m 
        %
        % Now we calculate the focal lengths on the fly for a range of
        % object distances (about 1.25 mm to 10,000 mm)
        %
        %    dist = logspace(0.1,4,30);
        %
        % Old:
        % FLname = fullfile(ilensRootPath,'data','lens',[obj.name,'.FL.mat']);
        % load(FLname,'objDistance','filmDistance');
        
        objDist = logspace(0.1,4,30);
        filmDistance = lensFocus(obj,objDist);
        filmDistance(filmDistance < 0) = NaN;

        hdl = ieFigure;
        semilogx(objDist,filmDistance,'ko-','LineWidth',1); grid on;
        xlabel('Obj dist (mm)'); ylabel('Focal distance (mm)');
        title(sprintf('%s',obj.name));
    otherwise
end

end
