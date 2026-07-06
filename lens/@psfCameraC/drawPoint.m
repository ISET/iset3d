


function [out]=drawPoint(obj,pointSource,wave0,wave,coord_type,varargin)

% DRAW the specify point
%
%   [out]=drawPoint(obj,pointSource,wave0,wave,coord_type)
%
% INPUT
% Pupil: struct   .zpos  (optical axis position)
                      % .diam   (diameter)
% wave0: specify the wavelength to plot
% wave: set of all possible wavelength
% coord_type: specify which coordinate to plot {'x';'y'}
%                
%OUTPUT
%out: 0 or 1
%
% MP Vistasoft 2014


%% Select wavelength

if isempty(wave0) || isempty(wave)
    indW=1;
else
    wave0=550; %nm   select a wavelengt
    indW=find(wave==wave0);

    if isempty(indW)
        error(['Not valid matching between wavelength ',wave0,' among ',wave])
    end
end


%% Which coordinate

if size(pointSource,1)==1
    pZ=pointSource(3); %Z coord
    switch coord_type
        case {'x';'x-axis'}
            pH=pointSource(1); 
        case {'y';'y-axis'}
            pH=pointSource(2); 
        case {'eccentricity';'x-y';'r'}
            pH=sqrt(pointSource(1).^2+pointSource(2).^2);
            pAngle=atan(pointSource(2)/pointSource(1)) ; % useful for 3D plot
        otherwise
            error(['Not valid ',coord_type,' as axis'])
    end
else
    pZ=pointSource(indW,3); %Z coord
    switch coord_type
        case {'x';'x-axis'}
            pH=pointSource(indW,1); 
        case {'y';'y-axis'}
            pH=pointSource(indW,2); 
        case {'eccentricity';'x-y';'r'}
            pH=sqrt(pointSource(indW,1).^2+pointSource(indW,2).^2);
            pAngle=atan(pointSource(indW,2)/pointSource(indW,1)) ; % useful for 3D plot
        otherwise
            error(['Not valid ',coord_type,' as axis'])
    end
end



%% Parameters for the PLOT
colorLine='--g'; %black line
Lwidth=2; %line width
Msize=6; %mark size
Mcolor=''; %mark colour
%  Point source
hold on
stem(pZ,pH,colorLine,...
    'MarkerFaceColor','red','MarkerEdgeColor','blue','MarkerSize',Msize,'LineWidth',Lwidth)
if nargin>5
    labelT=varargin{1};
    text(pZ,pH*1.1,...
        [labelT],'FontSize',10,'VerticalAlignment','cap') 
end
   



%% SET OUTPUT
out=1;