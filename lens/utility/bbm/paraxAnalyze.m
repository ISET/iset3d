function [OptSyst] = paraxAnalyze(lens)
% Create the black box model of the lens structure of SCENE3D to the Optical System structure to
% get its analysis through paraxial approximation (first order optics)
%
%  OptSys = paraxAnalyze(lens)
%
%
%INPUT
%   lens: lens object of SCENE3D
%
%OUTPUT
%   OptSys: Optical System structure.
%
% MP Vistasoft 2014


%% TODO
%
% Put paraxAnalyze into the @lens directory as a function called
% bbmCreate.  And then the syntax will be
%
%   lens.bbmCreate
%  
%   Inside of the @lens directory the function bbmCreate(obj) does what is
%   in paraxAnalyze.
%   
%  


%% GET RELEVANT PARAMETERs for the COMPUTATION

unit='mm'; %unit
wave=lens.wave*1e-6; % in mm
nw=length(wave); %num wavelength

nelem=length(lens.surfaceArray);

%Initialize some vector
N=ones(nw,nelem); 

%Useful parameter
inD=1;

%% Get the parameter to build the Optical System
for ni=1:nelem
    %Get the structure
    S=lens.surfaceArray(ni);
    if all(S.n==0)
        surftype{ni}='diaphragm';  
        if (S.apertureD==lens.apertureMiddleD) %Check if the aperture size is changed
            Diam(ni)=S.apertureD; %aperture diameter
        else
            Diam(ni)=lens.apertureMiddleD; %set aperture change
        end
        %save indices of the aperture
        indDiaph(inD)=ni;
        inD=inD+1;

        if ni>1
            N(:,ni)=N(:,ni-1); %refractive indices
       end
    else
        surftype{ni}='refr';
        N(:,ni)=S.n';           %refractive indices                
        Diam(ni)=S.apertureD; %aperture diameter
    end
    Radius(ni)=S.sRadius; %radius of curvature
    posZ(ni)=S.get('zintercept');
end
% Set new origin as the First Surface
PosZ=posZ-posZ(1);

%% Build several surface
for k=1:length(Radius)
    R(k)=Radius(k);
    z_pos(k)=PosZ(k);
    n(:,k)=N(:,k);
    diam(k)=Diam(k);
    switch surftype{k}
        case {'refr'}          
            surf{k}=paraxCreateSurface(z_pos(k),diam(k),unit,wave,surftype{k},R(k),n(:,k));
        case {'diaphragm','diaph'}
            surf{k}=paraxCreateSurface(z_pos(k),diam(k),unit,wave,surftype{k});
        case {'film'}
    end
end


%% CREATE OPTICAL SYSTEM
if nargin>2
    n_ob=varagin{1};
    n_im=varargin{2};
else            
    n_ob=1; n_im=1;
end
[OptSyst] = paraxCreateOptSyst(surf,n_ob,n_im,unit,wave);

%% END