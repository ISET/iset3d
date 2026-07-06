function drawMarginalRay(camera,varargin)
% DRAW the marginal rays from a point  on the optical axis to the rims of the specify pupil 
%
% Syntax:
%   out = drawMarginalRay(psfCameraC,varargin)
%
% INPUT
%  obj:         psfCameraC
%  wave0:       specify the wavelength to plot
%  pupil_type:  'entrance' or 'exit' pupil
%  coord_type:  specify which coordinate to plot {'x';'y'}
%                  
% OUTPUT
%   N/A
%
% MP/BW Vistasoft 2014

% Examples:
%{
 camera.drawMarginalRay();
%}

%% Parse

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('camera',@(x)(isa(x,'psfCameraC')));
p.addParameter('wave0',550,@isscalar);
p.addParameter('coord_type','y_axis',@ischar);  % Not sure ...
p.addParameter('pupil_type','exitpupil',@ischar);     % Either entrance or exit
p.parse(camera,varargin{:});

%% CHECK if wavelength matches

lens = camera.get('lens');
wave = camera.get('wave');
pointSource = camera.pointSource{1};  % Could be parameterized by index

% wave0 = 550; %nm   select a wavelengt
indW = find(wave==wave0);

if isempty(indW)
    error(['Not valid matching between wavelength ',wave0,' among ',wave])
end

%%
if size(pointSource,1)==1
    pZ=pointSource(3);%Z coord
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


%% PUPIL
switch pupil_type
    case {'entrancepupil';'EnP';'EntrancePupil';'EntPupil'}
        [Pupil]=camera.bbmGetValue('entrancepupil');
        
    case {'exitpupil';'ExP';'ExitPupil'}
        [Pupil]=camera.bbmGetValue('exitpupil');
    otherwise
        error(['Not valid "',pupilname,'" as pupil type'])
end
        
P_zpos =  mean(Pupil.zpos(indW,:));   % Z coord
P_upH  =  mean(Pupil.diam(indW,:))/2; % Upper rim of the pupil
P_loH  = -mean(Pupil.diam(indW,:))/2; % lower rim of the pupil


%% Parameters for the PLOT
switch pupilname
    case {'entrancepupil';'EnP';'EntrancePupil';'EntPupil'}
        Pupil = camera.bbmGetValue('entrancepupil');
        colorLine='--r'; %black line
    case {'exitpupil';'ExP';'ExitPupil'}
        Pupil = camera.bbmGetValue('exitpupil');
        colorLine = '--m'; %black line
    otherwise
        error(['Not valid "',pupilname,'" as pupil type'])
end

Lwidth=2; %line width

% Upper Coma Ray
hold on
plot([pZ P_zpos],[0 P_upH],colorLine,'LineWidth',Lwidth)
% LowerComa Ray
plot([pZ P_zpos],[0 P_loH],colorLine,'LineWidth',Lwidth)


%%