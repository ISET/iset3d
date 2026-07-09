


function [ImagSyst,vararging]=paraxOpt2Imag(OptSys,F,pSource,unit)


% Build imaging system composed by Optical System (OptSyst) + Film + point Source
%
%           function [ImagSyst,vararging]=paraxOpt2Imag(OptSys,F,pSource,unit)
%
% INPUT
% OptSys: struct of the optical system,  analisis through parax optics
%
% F: struct   .z= position
%                .res= resolution [Nx,Ny]
%                .pp= pixel pitch
% pSource:  [x y z ]
%
% unit: 'mm'

% OUTPUT
% ImagSyst: struct of the imaging system,  analisis through parax optics
%
% MP Vistasoft 2014


%% Default parameters

%% CREATE IMAGING SYSTEM
%film object
film_zpos=F.z;
profile='flat'; resFilm=F.res; pixel_pitch=F.pp; %um x um

[filmObj]=paraxCreateFilm(0,profile,resFilm,pixel_pitch,unit);
%Imaging system
[ImagSyst]=paraxCreateImagSyst(OptSys,filmObj,film_zpos,[0 0]);
% Point source object
if iscell(pSource)
    p = pSource{1};
    [ps_height,ps_angle,zOUT]=coordCart2Polar3D(p(1),p(2),p(3));
else
    [ps_height,ps_angle,zOUT]=coordCart2Polar3D(pSource(1),pSource(2),pSource(3));
end

% ps_height=sqrt(pSource(1).^2+pSource(2).^2); %distance of the point source to optical axis
% if not(pSource(2)==0) && not(pSource(1)==0)
%     ps_angle=atan(pSource(2)/pSource(1)); %angle subtended by the point source and the x-axis in the object plane
% else
%     if (pSource(2)==0)
%         ps_angle=0;
%     else
%         ps_angle=pi/2;
%     end
% end
lV=paraxGet(OptSys,'lastvertex'); % last vertex of the optical system
ps_zpos=zOUT+lV; %point source position along the optical axis
profile='point';
[pSourceObj]=paraxCreateObject(ps_zpos,ps_height,profile,unit);
%Add to the Imaging System
[ImagSyst]=paraxAddObject2ImagSyst(ImagSyst,pSourceObj);