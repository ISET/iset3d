function h = draw(obj,varargin)
% Draw a surface element from a lens
%
%    surfaceC.draw('figure',h);
%
% See also:  lens.draw
%
% Wandell

%% Parse
p = inputParser;
p.addRequired('obj',@(x)(isa(x,'surfaceC')));
p.addParameter('fig',[],@(x)(isa(x,'matlab.ui.Figure')));
p.addParameter('color',[0 0 0],@isvector);
p.addParameter('width',2,@isscalar);
p.addParameter('linestyle','-',@isscalar);

p.parse(obj,varargin{:});

h = p.Results.fig;
if isempty(h), h = ieNewGraphWin; end

lColor = p.Results.color;
lWidth = p.Results.width;
lStyle = p.Results.linestyle;

%% Initialize
c = obj.sCenter(3);
r = obj.sRadius;

% lWidth = 2; lColor = 'k';  % Drawing parameters

%% Draw
if (r ~= 0)
    
    % One edge of the lens sits at this z intercept
    zIntercept = obj.get('z intercept');
    
    % Solve for the points on the curve for this lens surface
    % element.  We are drawing in the z-y plane because the
    % z-axis is the horizontal axis, and the y-axis is the
    % vertical. The center of the sphere is at (0,0,c), so the
    % formula is
    %
    %     r^2 = (x)^2 + (y)^2 + (z - c)^2
    %
    % But since we are in the x=0 plane this simplifies to
    %
    %   r^2 = (y)^2 + (z - c)^2
    %
    % We solve for y in terms of z.
    
    % Solve for the Z-range we will need
    %  r^2 = (apertureD)^2 + (Zedge - c)^2
    %  zEdge = sqrt(r^2 - (apertureD)^2 ) + c
    %
    % -------------------------------------- 
    %
    % Trisha: When modeling the eye, instead of a spherical surface we
    % use a conicoid. According to Navarro's paper, each quadric
    % surface in the model is represented by the formula
    %
    %    x^2 + y^2 + (1-Q)*z^2 - 2*r*z = 0
    %
    % Note that when Q = 0, it is a simplification of the standard sphere
    % equation when the sphere is centered at "r" (passing through the
    % origin). To clarify:
    %
    %   x^2 + y^2 + (z-r)^2 = r^2 ---> x^1 + y^2 + z^2 -2*r*Z = 0
    
    Q = obj.get('conicConstant');
    yExtent = obj.apertureD/2;
    
    if(Q ~= -1)
        zEdgeN = (r-sqrt(-Q*yExtent^2+r^2-yExtent^2))/(Q+1);
        zEdgeP = (r+sqrt(-Q*yExtent^2+r^2-yExtent^2))/(Q+1);
    else
        zEdgeN = yExtent^2/(2*r);
        zEdgeP = zEdgeN;
    end
    
    % Choose the zEdge depending on the sign of the radius
    if(r > 0)
        zEdge = zEdgeN;
    elseif(r < 0)
        zEdge = zEdgeP;
    else
        warning('radius = 0! Not possible!')
    end
    
    % This is the range of z values we will consider.
    zPlot = linspace(0, zEdge, 100);
    
    % We get the positive and negative y-values
    yPos = @(Q,z) sqrt(-z.*(Q.*z-2.*r+z));
    yNeg = @(Q,z) -sqrt(-z.*(Q.*z-2.*r+z));
    % Some changes allow plotting aspherics here.  But this is not fully
    % integrated into the processing yet.
    yPlot  = yPos(Q,zPlot);
    yPlotN = yNeg(Q,zPlot);
    
    zPlotShift = zPlot + zIntercept;
   
    % The positive solutions
    line('xData',zPlotShift, 'yData',yPlot,...
        'color',lColor,'linewidth',lWidth);
    
    % The negative solutions
    line('xData',zPlotShift, 'yData',yPlotN,...
        'color',lColor,'linewidth',lWidth,'linestyle',lStyle);
    
else
    %Draw the aperture
    zIntercept  = obj.sCenter(3);
    
    line(zIntercept * ones(2,1), ...
        -1*[obj.apertureD/2 obj.apertureD], ...
        'linewidth',lWidth,'color',[1 0.2 0]);
    
    line(zIntercept * ones(2,1), ...
        [obj.apertureD obj.apertureD/2], ...
        'linewidth',lWidth,'color',[1 0.2 0]);
    
end

end