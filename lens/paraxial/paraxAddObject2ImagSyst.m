function [ImagSyst]=paraxAddObject2ImagSyst(ImagSyst,Obj,varargin)
% Add an Object to an Imaging System
%
% %INPUT
% %ImagSyst: Structures of the ImagSyst system
% %Obj: Object to be imaged
% %varargin: vararging{1} select one film [useful to find Field Stop]
% 
% %OUTPUT
% %ImagSyst: struct of the imagSyst with a new object
% 
% MP

%Check unit homogenity
if Obj.unit~=ImagSyst.unit
    warning('Unit of object and imaging system are different! Data not reliable!')
end


%check if other object are present
if isfield(ImagSyst,'object')
    index=length(ImagSyst.object)+1;
else
    index=1;
end



ImagSyst.object{index}.profile=Obj.profile;
% ImagSyst.film{index}.size_pixel=Obj.size_pixel;
% ImagSyst.film{index}.size_unit=Obj.size_unit;
% ImagSyst.film{index}.pixel_pitch=Obj.size_unit./Obj.size_pixel;




%HERE
%modify X,Y coordinate according to augmented parameter  and the film
%orientation
%% NOTA
% z position and eccentricity are sampled for extended object (flat,
% spherical,etc) when have been created

%Set position along the optical axis 
ImagSyst.object{index}.z_pos=Obj.z_pos;
if abs(Obj.z_pos)<Inf
    ImagSyst.object{index}.y_ecc=Obj.y_ecc;
else
    ImagSyst.object{index}.y_ecc=Obj.y_ecc;
    ImagSyst.object{index}.u_ecc=Obj.u_ecc; %angular eccentricity
end

%% Transfer Matrix From Object to First Surface
[ImagSyst.object{index}.matrix]=paraxObject2ImgSystTransferMatrix(ImagSyst,ImagSyst.object{index});



%% Conjugate Image of the Object  (Gaussian conjugate points)
%For cycle for z positions for extended object (e.g. spherical surface has
%different optical axis position).
% #sample along z is equal to #sample for z_ecc

for zi=1:size(ImagSyst.object{index}.z_pos,1) 
        t_obj=paraxGet(ImagSyst,'firstvertex')-ImagSyst.object{index}.z_pos;
        if abs(t_obj)<Inf 
            [t_im, m_lat,m_ang]= paraxConjImagingMatrix(ImagSyst,'object',t_obj);
        else
            %Case of object at infinity, required information about field eccenttricity
            [t_im, m_lat,m_ang]= paraxConjImagingMatrix(ImagSyst,'object',t_obj,ImagSyst.object{end}.u_ecc);
        end
        %append values ob: object point   ; im:image point
        ImagSyst.object{index}.ConjGauss.t_ob=t_obj;
        ImagSyst.object{index}.ConjGauss.t_im(:,zi)=t_im;
        
        %Position of the conjugate points
        ImagSyst.object{index}.ConjGauss.z_ob(:,zi)=ImagSyst.object{index}.z_pos;
        ImagSyst.object{index}.ConjGauss.z_im(:,zi)=t_im+paraxGet(ImagSyst,'lastvertex');
       
        if abs(ImagSyst.object{index}.ConjGauss.t_ob)<Inf 
            %Magnification
            ImagSyst.object{index}.ConjGauss.m_lat(:,zi)=m_lat;        
            ImagSyst.object{index}.ConjGauss.m_ang(:,zi)=m_ang;
            % Eccentrivity of the cojugate points
            ImagSyst.object{index}.ConjGauss.y_ob(:,zi)=ImagSyst.object{index}.y_ecc(zi);
            ImagSyst.object{index}.ConjGauss.y_im(:,zi)=ImagSyst.object{index}.y_ecc(zi).*m_lat;
        else
            %Magnification
            ImagSyst.object{index}.ConjGauss.m_lat(:,zi)=NaN;        
            ImagSyst.object{index}.ConjGauss.m_ang(:,zi)=m_ang;
            % Eccentrivity of the cojugate points
            ImagSyst.object{index}.ConjGauss.y_ob(:,zi)=ImagSyst.object{index}.y_ecc(zi);
            ImagSyst.object{index}.ConjGauss.y_im(:,zi)=m_lat; %for the specific case the lateral magnification is equal to the image height
        end
end



%% FIND PUPILs  {METHOD from Principles of Optics -Born and Wolf)
%For ON Axis object point (Po), the stop (considering also the lens/mirror) rims determines the cross-section of the
%image-forming pencil, and it is called APERTURE STOP. To determine its
%position use this procedure:
%1) the Gaussian image of each 'potential' stop must be found in the part %of the system which precedes it
%2) The image which subtends the smallest angle at Po is called the ENTRANCE PUPIL
%3) The physical stop which gives rise to the entrance pupil is the aperture stop
%4) The ANGULAR APERTURE on THE OBJECT SIDE (AN) is given by the double of the subtended angle
%5) The image of the aperture STOP formed by the part of the system which follows it is know as EXIT PUPIL
%6)The double angle subtended at P1(conj point) from the exit pupil is the angulas aperture on the image side (projection angle)

%Possible Entrance and Exit Pupils
pupil1=paraxGet(ImagSyst,'pupils');
wave1=paraxGet(ImagSyst,'wave');
object1=paraxGet(ImagSyst,'object',index);
list1=paraxGet(ImagSyst,'surflist');
% Pupil.EnPs=paraxGet(ImagSyst,'entrancepupils'); 
% Pupil.ExPs=paraxGet(ImagSyst,'exitpupils'); 
% Pupil.computed_order=paraxGet(ImagSyst,'surforder');
% [ImagSyst.object{index}.Radiance]=paraxFindPupil4Object(Pupil,ImagSyst.object{index},ImagSyst.surfs.list,ImagSyst.wave);
[ImagSyst.object{index}.Radiance]=paraxFindPupil4Object(pupil1,object1,list1,wave1);

%Other parameters are estimated: 

if not(all(ImagSyst.object{index}.Radiance.ExP.z_pos(:,1)==ImagSyst.object{index}.Radiance.ExP.z_pos(:,2)))
    warning ('The limiting aperture for upper bundle of ray is different from the one for the lower. Effective focal distance and F-number can differ from what computed!')
end
% effective focal distance (distance(ExP-imagePoint))
ImagSyst.object{index}.Radiance.efl=ImagSyst.object{index}.ConjGauss.z_im-ImagSyst.object{index}.Radiance.ExP.z_pos(:,1); %arbitrary choise (upper limit for ray bundle)
%pupil magnification: (Diam ExP)/(Diam EnP)
ImagSyst.object{index}.Radiance.RatioPupils=(ImagSyst.object{index}.Radiance.ExP.diam(:,1)-ImagSyst.object{index}.Radiance.ExP.diam(:,2))./(ImagSyst.object{index}.Radiance.EnP.diam(:,1)-ImagSyst.object{index}.Radiance.EnP.diam(:,2));
%F-number
%ideal f-number  (distance(ExP-focalPoint)/(Diam ExP)
% ImagSyst.object{index}.Radiance.Fnumber.ideal=(ImagSyst.cardPoints.lastVertex+ImagSyst.cardPoints.dFi-mean(ImagSyst.object{index}.Radiance.ExP.z_pos,2))./abs(ImagSyst.object{index}.Radiance.ExP.diam(:,1)-ImagSyst.object{index}.Radiance.ExP.diam(:,2));
ImagSyst.object{index}.Radiance.Fnumber.ideal=(paraxGet(ImagSyst,'imagefocalpoint')-mean(ImagSyst.object{index}.Radiance.ExP.z_pos,2))./abs(ImagSyst.object{index}.Radiance.ExP.diam(:,1)-ImagSyst.object{index}.Radiance.ExP.diam(:,2));

%effective f-number (distance(ExP-imagePoint)/(Diam ExP)
% ImagSyst.object{index}.Radiance.Fnumber.eff=(ImagSyst.object{index}.Radiance.efl)./abs(ImagSyst.object{index}.Radiance.ExP.diam(:,1)-ImagSyst.object{index}.Radiance.ExP.diam(:,2));
ImagSyst.object{index}.Radiance.Fnumber.eff=(ImagSyst.object{index}.Radiance.efl)./abs(ImagSyst.object{index}.Radiance.ExP.diam(:,1)-ImagSyst.object{index}.Radiance.ExP.diam(:,2));

% %% SPECIAL RAYs
% %7) For a point (also OFF AXIS) the ray passing through the center of the entrance pupi (aka PRINCIPAL RAY or CHIEF RAY or REFERENCE RAY)
% %The chief ray, in absence of aberrations, will pass through the center of
% %the APERTURE STOP and through the center of the EXIT PUPIL
% 
% [ImagSyst.object{index}.meridionalPlane]=paraxFindMeridionalSpecialRays(ImagSyst.object{index},ImagSyst.cardPoints);
% %Numerical Aperture
% % teta_comaRay(1)=
% % ImagSyst.object{index}.meridionaPlane.NumApert=


% %% ANGULAR APERTURE
% %is defined as NA= n sin (alfa) and it measures the amount of light
% %traveling the system
% %In object Space
% 
% % From on axis point
% typ_comp='paraxial';
% teta_meanParax=mean([ImagSyst.object{index}.meridionalPlane.comaRay.upper.angleParax,ImagSyst.object{index}.meridionalPlane.comaRay.lower.angleParax],2); %Computation needed for considering non centered EnP
% ImagSyst.object{index}.meridionalPlane.NumericalAperture.onaxis_parax=paraxEffectiveNumericalAperture(ImagSyst.n_ob,teta_meanParax,ImagSyst.object{index}.meridionalPlane.marginalRay.upper.angleParax,typ_comp);
% typ_comp='paraxial';
% teta_mean=mean([ImagSyst.object{index}.meridionalPlane.comaRay.upper.angle,ImagSyst.object{index}.meridionalPlane.comaRay.lower.angle],2); %Computation needed for considering non centered EnP
% ImagSyst.object{index}.meridionalPlane.NumericalAperture.onaxis=paraxEffectiveNumericalAperture(ImagSyst.n_ob,teta_mean,ImagSyst.object{index}.meridionalPlane.marginalRay.upper.angle,typ_comp);
% % From offaxis point
% typ_comp='paraxial';
% ImagSyst.object{index}.meridionalPlane.NumericalAperture.offaxis_parax=paraxEffectiveNumericalAperture(ImagSyst.n_ob,ImagSyst.object{index}.meridionalPlane.referenceRay.angleParax,ImagSyst.object{index}.meridionalPlane.comaRay.upper.angleParax,typ_comp);
% typ_comp='paraxial';
% ImagSyst.object{index}.meridionalPlane.NumericalAperture.offaxis=paraxEffectiveNumericalAperture(ImagSyst.n_ob,ImagSyst.object{index}.meridionalPlane.referenceRay.angle,ImagSyst.object{index}.meridionalPlane.comaRay.upper.angle,typ_comp);


%% FIND FIELD STOPs
% Field stops determine what proportion of the surface of an extended
% object is image by the instrument
%8)Use the image find at 1)
%9)That image which subtends the smallest angle at the center of the image
%pupil is called the ENTRANCE WINDOW
%10) The double of such a subtended angle is called the ANGULAR FIELD of
%VIEW
%11) The Image of the ENTRANCE PUPIL  by the insturment (coinciding witht
%he image of the FIELD STOP by the part of the SYSTEM which follow it) is
%called the EXIT WINDOW.
%12) the double of the angle subtended at the center of the EXIT PUPIL by
%the EXIT WINDOW is the IAMGE FILED ANGLE

%Selected the  film used to which the object is imaged
if isempty(varargin)
    film_index=1;
else
    film_index=varargin{1};
end

Pupils=paraxGet(ImagSyst,'pupils');
[Field]=paraxFindWindow4Object(ImagSyst.object{index}.Radiance.EnP,ImagSyst.object{index}.Radiance.ExP,Pupils,ImagSyst.film{film_index},ImagSyst.surfs,ImagSyst.wave);
%Append to output
ImagSyst.object{index}.Radiance.EnW=Field.EnW;
ImagSyst.object{index}.Radiance.ExW=Field.ExW;
ImagSyst.object{index}.Radiance.fieldStop=Field.fieldSTOP;
ImagSyst.object{index}.Radiance.FoV=Field.FoV;
% ImagSyst.object{index}.Radiance.NA=Field.NA.*ImagSyst.n_ob;
%% SPECIAL RAYs
%7) For a point (also OFF AXIS) the ray passing through the center of the entrance pupi (aka PRINCIPAL RAY or CHIEF RAY or REFERENCE RAY)
%The chief ray, in absence of aberrations, will pass through the center of
%the APERTURE STOP and through the center of the EXIT PUPIL

[ImagSyst.object{index}.meridionalPlane]=paraxFindMeridionalSpecialRays(ImagSyst.object{index},paraxGet(ImagSyst,'cardpoint'));
%Numerical Aperture
% teta_comaRay(1)=
% ImagSyst.object{index}.meridionaPlane.NumApert=
%% ANGULAR APERTURE
%is defined as NA= n sin (alfa) and it measures the amount of light
%traveling the system
%In object Space

% From on axis point
typ_comp='paraxial';
teta_meanParax=mean([ImagSyst.object{index}.meridionalPlane.comaRay.upper.angleParax,ImagSyst.object{index}.meridionalPlane.comaRay.lower.angleParax],2); %Computation needed for considering non centered EnP
ImagSyst.object{index}.meridionalPlane.NumericalAperture.onaxis_parax=paraxEffectiveNumericalAperture(ImagSyst.n_ob,teta_meanParax,ImagSyst.object{index}.meridionalPlane.marginalRay.upper.angleParax,typ_comp);
typ_comp='paraxial';
teta_mean=mean([ImagSyst.object{index}.meridionalPlane.comaRay.upper.angle,ImagSyst.object{index}.meridionalPlane.comaRay.lower.angle],2); %Computation needed for considering non centered EnP
ImagSyst.object{index}.meridionalPlane.NumericalAperture.onaxis=paraxEffectiveNumericalAperture(ImagSyst.n_ob,teta_mean,ImagSyst.object{index}.meridionalPlane.marginalRay.upper.angle,typ_comp);
% From offaxis point
typ_comp='paraxial';
ImagSyst.object{index}.meridionalPlane.NumericalAperture.offaxis_parax=paraxEffectiveNumericalAperture(ImagSyst.n_ob,ImagSyst.object{index}.meridionalPlane.referenceRay.angleParax,ImagSyst.object{index}.meridionalPlane.comaRay.upper.angleParax,typ_comp);
typ_comp='paraxial';

ImagSyst.object{index}.meridionalPlane.NumericalAperture.offaxis = ...
    paraxEffectiveNumericalAperture(ImagSyst.n_ob,...
        ImagSyst.object{index}.meridionalPlane.referenceRay.angle,...
        ImagSyst.object{index}.meridionalPlane.comaRay.upper.angle,...
        typ_comp);


%% ABERRATION
% Aberration coefficient are compute with the formulas described by Sasia
% Chapter 10 (pag 139): Aberration coefficients Sasián, José. Introduction to Aberrations in Optical Imaging Systems. Cambridge University Press, 2012
% [CR_0,MR_0,N,abbeNumber,C,k,augmParam_list,Msurf,Mtrans]=paraxAberrationGetImgagSystParameters(ImagSyst.object{index},ImagSyst);
% % Compute Seidel Sum
% [ImagSyst.object{index}.SeidelCoeffs,ImagSyst.object{index}.log]=paraxAberrationSeidelSum(CR_0,MR_0,N,abbeNumber,C,k,augmParam_list,Msurf,Mtrans);

[ImagSyst.object{index}.Wavefront.SeidelCoeff,ImagSyst.object{index}.Wavefront.log]=paSeidelSum(ImagSyst.object{index},ImagSyst,'parax');
%Convert to 4th order wavefront coeffs
[ImagSyst.object{index}.Wavefront.WaveCoeff]=paSeidel2Wave4thOrder(ImagSyst.object{index}.Wavefront.SeidelCoeff);
[ImagSyst.object{index}.Wavefront.log.allWaveCoeff]=paSeidel2Wave4thOrder(ImagSyst.object{index}.Wavefront.log.allSeidelCoeff);
% Convert to peak value (assuming full field of view for the given object
y_max=1;y0=1;
[ImagSyst.object{index}.Wavefront.PeakCoeff]=paWave4thOrder2PeakValue(ImagSyst.object{index}.Wavefront.WaveCoeff,y0,y_max);