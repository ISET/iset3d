function drawPrincipalRay(camera,pointSource,pupilname,wave0,wave,coord_type)
% Drawthe principal rays from the point to the center of the specified pupil
%
% Syntax:
%   drawPrincipalRay(obj,pointSource,pupilname,wave0,wave,coord_type)
%
% INPUT
%  pointSource: [x,y,z]
%  pupilname: 'entrance' or 'exit' pupil
%  wave0: specify the wavelength to plot
%  wave: set of all possible wavelength
%  coord_type: specify which coordinate to plot {'x';'y'}
%                  
% OUTPUT
%
% MP Vistasoft 2014
%
% See also
%   psfCameraC
%

%% Parse


%% CHECK if wavelength matches

%{
wave0 = 550; %nm   select a wavelength
indW = find(wave==wave0);
%}
indW = 1;

pointSource = camera.pointSource{1}
coord_type = 'y-axis';
pupilname = 'entrancepupil';

if size(pointSource,1)==1
    pZ=pointSource(3);%Z coord
    switch coord_type
        case {'x';'x-axis'}
            pH = pointSource(1); 
        case {'y';'y-axis'}
            pH = pointSource(2); 
        case {'eccentricity';'x-y';'r'}
            pH     = sqrt(pointSource(1).^2+pointSource(2).^2);
            pAngle = atan(pointSource(2)/pointSource(1)) ; % useful for 3D plot
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
switch pupilname
    case {'entrancepupil';'EnP';'EntrancePupil';'EntPupil'}
        [Pupil]=camera.lens.get('bbm','entrancepupil');
        
    case {'exitpupil';'ExP';'ExitPupil'}
        [Pupil]=camera.lens.get('bbm','exitpupil');
        
    otherwise
        error(['Not valid "',pupilname,'" as pupil type'])
end

P_zpos =  mean(Pupil.zpos(indW,:));   % Z coord
P_upH  =  mean(Pupil.diam(indW,:))/2; % Upper rim of the pupil
P_loH  = -mean(Pupil.diam(indW,:))/2; % lower rim of the pupil


%% Parameters for the PLOT
colorLine='--b'; %black line
Lwidth=2; %line width

% Upper Coma Ray
hold on
plot([pZ P_zpos],[pH 0],colorLine,'LineWidth',Lwidth)

% LowerComa Ray
plot([pZ P_zpos],[pH 0],colorLine,'LineWidth',Lwidth)

end
