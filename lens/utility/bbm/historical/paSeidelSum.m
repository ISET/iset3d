function [SeidelCoeff,log]=paSeidelSum(object,ImagSyst,angle_type,varargin)
% Historical reference only.
%
% This function was recovered from an old 2021 stash while setting up the
% ISETLens tests. It is retained as a record of the previous Seidel
% aberration implementation, but it is not part of the supported API. The
% current plan is to implement Seidel aberrations afresh, in a smaller,
% tested design parallel to the Zernike/wavefront utilities.
%
% Compute the Seidel Coeffs for the imaging system highlighting the contribution
% of each elements usign two rays (principal ray or chief ray, and
% secondary ray or marginal ray)
%
% PROGRAMMING BUG -  See comments towards end about A4, and the hack BW
% introduced here to make this run for the 2-element lens
%
%INPUT
%
%object:  structure describing the object which is imaged through the
%imaging system
%ImagSyst: imaging system through which theobject is imaged
% varargin {1} abbenumber of the object space; {2} abbenumber of the image
% space
%
%
%OUTPUT
%SeidelCoeffs:structure with the seidel coeffs of the overal system
%log: descrive each elements 
%
%NOTE: N: #sampling wavelength
%      M: #of surface
% The Seidel Sum is computed usign two different rays (called here as CHIEF
% RAY/principal ray and MARGINAL RAY/secondary ray).
% The secondary ray can be selected to be the REAL marginal ray of the
% system or the a ZONAL rays
%
% MP Vistasoft Team, Copyright 2014


%% CHECK INPUT
if (nargin>3) && not(isempty(varargin{1}{1})) && not(isempty(varargin{1}{2}))
    special_rays{1}=varargin{1}{1}; %type of ray selected for the Principal Ray
    special_rays{2}=varargin{1}{2}; %type of ray selected for the Secondary Ray
else
    special_rays{1}='chief';
    special_rays{2}='marginal';
end

if (nargin>4) && not(isempty(varargin{2}{1})) && not(isempty(varargin{2}{2}))
    special_param{1}=varargin{2}{1}; %parameters for  the Principal Ray
    special_param{2}=varargin{2}{2}; %parameters for the Secondary Ray
else
    special_param{1}='none';
    special_param{2}='upper'; %selected upper marginal ray
end


%% GET and ARRANGE the PARAMETERs from the IMAGING SYSTEM: 2 rays at first surface, serie of :refractive indices,abbe numbers, curvatures,aspherical conic constant,list of surface augmented list, ABCD matrix transformation at each surface and ABCD matrix fro translation between surface 
[CR_0,MR_0,N,abbeNumber,C,k,augmParam_list,Msurf,Mtrans]=paGetImagSystParameters(object,ImagSyst,angle_type,special_rays,special_param);

%% CHECK if one or both rays are CUSTUMIZED [i.e. y and u coordinates at first surface given by the user]
if (nargin>5) && not(isempty(varargin{3}{1})) && not(isempty(varargin{3}{2}))
    CR_0=varargin{3}{1}; %parameters for  the Principal Ray
    MR_0=varargin{3}{2}; %parameters for the Secondary Ray
    if not(size(CR_0,2)==size(N,1))
        CR_0=repmat(CR_0,1,size(N,1));
    end
    if not(size(MR_0,2)==size(N,1))
        MR_0=repmat(MR_0,1,size(N,1));
    end
end

%% INITIATE PARAMETES
%number of wavelength sample
nw=size(N,1);

%ray heights
y_CR(:,1)=CR_0(1,:);%chief ray
y_MR(:,1)=MR_0(1,:);%chief ray
%ray angles (paraxial)
u_CR(:,1)=CR_0(2,:);%chief ray
u_MR(:,1)=MR_0(2,:);%chief ray
rInd=1; %ray index

%Incident Angle on the surfaces
i_CR=zeros(nw,length(C)); %for chief ray
i_MR=zeros(nw,length(C)); %for marginal ray

%Delta
D_CR=zeros(nw,length(C)); %for chief ray
D_MR=zeros(nw,length(C)); %for marginal ray

%Refraction invarian
A_CR=zeros(nw,length(C)); %for chief ray
A_MR=zeros(nw,length(C)); %for marginal ray

%Petzval sum term
P=zeros(nw,length(C));

%Seidel Coeff.
SI=zeros(nw,length(C));
SII=zeros(nw,length(C));
SIII=zeros(nw,length(C));
SIV=zeros(nw,length(C));
SV1=zeros(nw,length(C));
SV2=zeros(nw,length(C));

%% LOOP

for si=1:length(C)
    
    % Aspherical contribution - 
    % Aspherical Lens{http://www.edmundoptics.com/technical-resources-center/optics/all-about-aspheric-lenses/}
    % Sometimes C is infinite (2 element lens case) which produces A4 as a
    % NaN and creates problems with any(A4) ~=0 below.
    A4(si)=(k(si).*C(si).^3)/8;
    
    %% Paraxial ray tracing: REFRACTION
    % Set input
        %Chief Ray
        CR_input(1,:)=[y_CR(:,si)'];
        CR_input(2,:)=[u_CR(:,si)'];
        %Marginal Ray
        MR_input(1,:)=[y_MR(:,si)'];
        MR_input(2,:)=[u_MR(:,si)'];
        
    if all(augmParam_list(:,si)==0)
        % Apply refraction or reflection        
        CR_output=paraxMatrixTransformation(Msurf{si},CR_input);%Chief ray        
        MR_output=paraxMatrixTransformation(Msurf{si},MR_input);%Marginal ray
    else
        % Apply refraction or reflection        
        CR_output=paraxMatrixTransformation(Msurf{si},CR_init,augmParam_list(:,si)); %Chief ray        
        MR_output=paraxMatrixTransformation(Msurf{si},MR_init,augmParam_list(:,si));%Marginal ray
    end
    % GET estimated Parameters: refracted angles 
    u_CR(:,si+1)=CR_output(2,:)'; %chief ray
    u_MR(:,si+1)=MR_output(2,:)'; %marginal ray
    
    
         
 %% Paraxial ray tracing: TRANSFERT        
    if si<length(C)
        %transfert to next surface      
        CR_output=paraxMatrixTransformation(Mtrans{si},CR_output);%Chief ray        
        MR_output=paraxMatrixTransformation(Mtrans{si},MR_output);%Marginal ray 
        % GET estimated Parameters: refracted angles 
        y_CR(:,si+1)=CR_output(1,:)'; %chief ray
        y_MR(:,si+1)=MR_output(1,:)'; %marginal ray
%     else
%         y_CR(:,si+1)=CR_output(1,:)'; %chief ray
%         y_MR(:,si+1)=MR_output(1,:)'; %marginal ray    
    end
    
%% RELEVANT PARAMETERs to compute SEIDEL COEFFs
     deltaN(:,si)=N(:,si+1)-N(:,si); %refraction index difference
     P(:,si)=C(si).*(1./N(:,si+1)-1./N(:,si)); %petzval term
     % LAGRANGE INVARIANT
     if si==1
         LG(:,1)=N(:,si).*(u_MR(:,si).*y_CR(:,si)-u_CR(:,si).*y_MR(:,si)); % used the refractive index before refraction (different to Sasian formulation)
     end
     LagrInv(:,si)=N(:,si).*(u_MR(:,si).*y_CR(:,si)-u_CR(:,si).*y_MR(:,si)); %store Lagrange Invariant
     % CHIEF RAY   
     i_CR(:,si)=u_CR(:,si)+y_CR(:,si).*C(si);%incident angle
     A_CR(:,si)=i_CR(:,si).*N(:,si);%refraction invariant
     alfa_CR(:,si)=y_CR(:,si).*C(si);
     D_CR(:,si)=u_CR(:,si+1)./N(:,si+1)-u_CR(:,si)./N(:,si);
     % MARGINAL RAY   
     i_MR(:,si)=u_MR(:,si)+y_MR(:,si).*C(si);%incident angle
     A_MR(:,si)=i_MR(:,si).*N(:,si);%refraction invariant
     alfa_CR(:,si)=y_MR(:,si).*C(si);
     D_MR(:,si)=u_MR(:,si+1)./N(:,si+1)-u_MR(:,si)./N(:,si);
     
     
     %% COMPUTE SEIDEL COEFF [the negative sign is included in the formulation]
     SI(:,si)=-A_MR(:,si).^2.*y_MR(:,si).*D_MR(:,si); % SI= Delta(um/n)(ym)(Ac)^2
     SII(:,si)=-A_CR(:,si).*A_MR(:,si).*y_MR(:,si).*D_MR(:,si); % SII= Delta(um/n)(ym)(Ac)(Am)
     SIII(:,si)=-A_CR(:,si).^2.*y_MR(:,si).*D_MR(:,si); % SIII= Delta(um/n)(yc)(Am)^2
     SIV(:,si)=-LG.^2.*P(:,si); % SIV=-(LG.^2)(P)
     SV(:,si)=(A_CR(:,si)./A_MR(:,si)).*(SIII(:,si)+SIV(:,si));% SV=Ac/Am*(SIII+SIV)
     %Similar versions for SV
     SV1(:,si)=-(A_CR(:,si)./A_MR(:,si)).*(LG.^2.*P(:,si)+A_CR(:,si).^2.*y_MR(:,si).*D_MR(:,si)); %SV1=(Ac/Am)[(LG^2)P+(Ac^2)ym Delta(um/n) ]
     SV2(:,si)=-(A_CR(:,si).*(A_CR(:,si).^2.*(1./N(:,si+1).^2-1./N(:,si).^2).*y_MR(:,si)-(LG+A_CR(:,si).*y_MR(:,si)).*y_CR(:,si).*P(:,si))); 
     %SV2=(Ac[(Ac^2) Delta(1/n^2) ym- (LG-Ac)yc P])
%     
    
     %% CONTRIBUTE OF THE ASPHERICAL COMPONENT 
     % From "Introduction ti aberration in Optical Imaging System-Sasian"
     % {Chapter 10- pag 143}
     if A4(si)~=0
         a=8.*A4(si).*y_MR(:,si).^4.*deltaN(:,si); % intermediate parameter
         y_ratio=y_CR(:,si)./y_MR(:,si); % aka Eccentricity of the Chief (principal) Ray
         %single contribute
         dSI(:,si)=a;
         dSII(:,si)=y_ratio.*a;
         dSIII(:,si)=y_ratio.^2.*a;
         dSIV(:,si)=0;
         dSV(:,si)=y_ratio.^3.*a;
         %% ADD apsherical contributes
         SI(:,si)=SI(:,si)+dSI(:,si); 
        SII(:,si)=SII(:,si)+dSII(:,si); 
        SIII(:,si)=SIII(:,si)+dSIII(:,si); 
        SIV(:,si)=SIV(:,si)+dSIV(:,si); 
         SV(:,si)=SV1(:,si)+dSV(:,si); 
         
%         SV1(:,si)=SV1(:,si)+dSV(:,si); 
%         SV2(:,si)=SV2(:,si)+dSV(:,si); 

  
         
     end
     
end

%%  Sum Coeff Seidel for all surface
SIt=sum(SI,2); %Seidel Coeff 1
SIIt=sum(SII,2); %Seidel Coeff 2
SIIIt=sum(SIII,2); %Seidel Coeff 3
SIVt=sum(SIV,2); %Seidel Coeff 4
SVt=sum(SV,2); %Seidel Coeff 5_v1
% SV2t=sum(SV2,2); %Seidel Coeff 5_v2


%% Set Output
SeidelCoeff.SI=SIt;SeidelCoeff.SII=SIIt;SeidelCoeff.SIII=SIIIt;
SeidelCoeff.SIV=SIVt;SeidelCoeff.SV=SVt;
%Append unit of coefficients
SeidelCoeff.unit=ImagSyst.unit;
SeidelCoeff.wave=ImagSyst.wave;
% And log
log.allSeidelCoeff.SI=SI;log.allSeidelCoeff.SII=SII;log.allSeidelCoeff.SIII=SIII;
log.allSeidelCoeff.SIV=SIV;log.allSeidelCoeff.SV=SV;
%Append unit of coefficients
log.allSeidelCoeff.unit=ImagSyst.unit;
log.allSeidelCoeff.wave=ImagSyst.wave;
%Lagrange Invariant
log.LagrangeInvariant=LagrInv;
%principal ray (by default Chief Ray)
log.principalRay.A=A_CR;
log.principalRay.Delta=D_CR;
log.principalRay.y=y_CR;
log.principalRay.u=u_CR;
%secondary ray (by default Marginal Ray)
log.secondaryRay.A=A_MR;
log.secondaryRay.Delta=D_MR;
log.secondaryRay.y=y_MR;
log.secondaryRay.u=u_MR;
%Specify which rays have been used
log.principalRay.name=special_rays{1}; %name of principal ray
log.secondaryRay.name=special_rays{2}; %name of secondary ray
log.principalRay.selection=special_param{1}; %extra parameter for the selection of  principal ray
log.secondaryRay.selection=special_param{2}; %extra parameter for the selection of  secondary ray

l = (A4 ~= 0);
if ~isnan(A4(l))
    log.asphericalCoeff.SI=dSI;log.asphericalCoeff.SII=dSII;
    log.asphericalCoeff.SIII=dSIII;log.asphericalCoeff.SIV=dSIV;
    log.asphericalCoeff.SV=dSV;log.asphericalCoeff.SVI=dSVI;
end
