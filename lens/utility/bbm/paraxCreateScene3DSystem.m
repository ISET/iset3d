% CREATE a SCENE 3D Imaging system according to the properties of the image
% system specify in the input structure

function [surfaceArray,lens,film,object]=paraxCreateScene3DSystem(ImagSyst,Aper_Diam)


%INPUT
%ImagSyst:struct of imaging system with film and object
%Aper_Diam: aperture diameter

%OUTPUT
%surface:
%lens:
%film:
%object:

% GET wavelength and convert to nanometer

wave=ImagSyst.wave'*1e6;

% CREATE SURFACE ARRAY Inverting order of surface
ind_ord=ImagSyst.surfs.order;
z_posEND=ImagSyst.surfs.list{ind_ord(end)}.z_pos;
surfaceArray =surfaceC();
for si=1:length(ind_ord)
    surf0=ImagSyst.surfs.list{ind_ord(si)};
    %Aperture   
    apertureD = surf0.diam;
    switch surf0.type
        case {'diaphragm'}
            Radius= 0;
            N=zeros(length(wave),1);
        otherwise
            Radius= surf0.R;
            N=surf0.N;
    end    
    Zpos=surf0.z_pos-z_posEND;    
    
    %CREATE SURFACE ARRAY
     surfaceArray (si)=surfaceC('apertureD', apertureD, 'wave', wave,...
    'sRadius',Radius,'zpos',Zpos,'n',N);   
    
end

%CREATE LENS SYSTEM

lens=lens('surfaceArray',surfaceArray,'focalLength',median(ImagSyst.cardPoints.fi),'wave',wave,'apertureSample',[100,100]);
% lens=lens('surfaceArray',surfaceArray,'focalLength',median(ImagSyst.cardinalPoint.fi),'wave',wave,'apertureSample',[nS_X,nS_Y]);

% SET APERTURE DIAMETER
lens.apertureMiddleD=Aper_Diam; %desidered diaphragm diameter
%lens.Draw

% CREATE THE FILM
film0=ImagSyst.film{end};
film = pbrtFilmC('position', [0 0 film0.z_pos], 'size', [film0.size_unit], 'wave', wave, 'resolution', [film0.size_pixel,length(wave)]);


%CREATE A  object as point SOURCE to generate a PSF
object=[0,ImagSyst.object{end}.y_ecc,ImagSyst.object{end}.z_pos];

%DEBUG
%  psfCamera = psfCameraC('lens', lens, 'film', film, 'pointsource', object0);
% psfCamera.estimatePSF(1000,true);
%   oi = psfCamera.oiCreate;
%   vcAddObject(oi); oiWindow;