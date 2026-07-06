
function [Radiance]=paraxFindPupil4Object(ImagSystPupil,Object,OptSystlist,wave)

%% Find the Entrance Pupil (aperture stop, the exit pupil) for a given obejct and optical system  % FIND PUPILs  {METHOD from Principles of Optics -Born and Wolf)
%For ON Axis object point (Po), the stop (considering also the lens/mirror) rims determines the cross-section of the
%image-forming pencil, and it is called APERTURE STOP. To determine its
%position use this procedure:
%1) the Gaussian image of each 'potential' stop must be found in the part %of the system which precedes it
%2) The image which subtends the smallest angle at Po is called the ENTRANCE PUPIL
%3) The physical stop which gives rise to the entrance pupil is the aperture stop
%4) The ANGULAR APERTURE on THE OBJECT SIDE (AN) is given by the double of the subtended angle
%5) The image of the aperture STOP formed by the part of the system which follows it is know as EXIT PUPIL
%6)The double angle subtended at P1(conj point) from the exit pupil is the angulas aperture on the image side (projection angle)
%
%       function [Radiance]=paraxFindPupil4Object(ImagSystPupil,Object,OptSystlist,wave)
%
%INPUT
%ImagSystPupil: is a structure containing the following information of the optical system
%       .EnPs: possible entrance pupils position (.z_pos), lateral magnification (.m_lat), and edge (.diam)
%               of the object on the optical axis
%       .ExPs: possible exit pupils position (.z_pos), lateral magnification (.m_lat), and edge (.diam)
%               of the object on the optical axis
%       .computed_order order of computation of the optical system surface
%       .y_ecc: eccentricity on the meridional plane of the object
%
%Object: structure describing object in the imaging system containing the  following field:
%       .ConjGauss (conjugate point position (.z_ob) and
%
%OptSystlist: structure containing the list of the surface in the optical system
%wave:  sampling wavelength  

%Object: 
%
%
%OUTPUT
%Radiance : it is a structure with relevant radiance features of the imaging system 
%       .Radiance.aperStop (aperture stop index (.indexSurf) and the surface (.surf))
%       .Radiance.EnP (.diam: y-limits, .z_pos: position in the optical  axis, .angular aperture [rad o deg])
%       .Radiance.ExP (.diam: y-limits, .z_pos: position in the optical  axis, .angular aperture [rad o deg])
%       .Radiance.chromSTOP (describing if a different wavelength there is
%       a different Aperture Stop )
%        .objectSpace (angular aperture [rad or deg])
%        .imageSpace (angular aperture [rad or deg])

% NOTE: all coordinates, distances and wavelengths are consistence with
% [unit] of the Imaging System field used as input
%
% MP Vistasoft 2014

%% CHECK INPUT FIELD
if not(isfield (ImagSystPupil,'EnPs'))
    warning ('There are not possible Entrance Pupils! Return empty output')
    Radiance=[];
    return
end
if not(isfield (Object,'ConjGauss'))
    warning ('The conjugate gaussian point is not compute ! Return empty output')
    Radiance=[];
    return
end


%% FIND PUPILS

%STEP 1

for k=1:length(ImagSystPupil.computed_order)
    if abs(ImagSystPupil.EnPs{k}.z_pos-Object.ConjGauss.z_ob(1))<0
        %If object at finite distance use Entrance Pupil to find Aperture Stop
        %angle top-rim aperture
        angle1(:,k)=atan(ImagSystPupil.EnPs{k}.diam(:,1)./(ImagSystPupil.EnPs{k}.z_pos-Object.ConjGauss.z_ob(1))); %.z_ob because PUPIL defined for ON AXIS point
        %angle bottom-rim aperture
        angle2(:,k)=atan(ImagSystPupil.EnPs{k}.diam(:,2)./(ImagSystPupil.EnPs{k}.z_pos-Object.ConjGauss.z_ob(1))); %.z_ob because PUPIL defined for ON AXIS point
    else
        %If object at infinite distance use Exit Pupil to find Aperture Stop
        %angle top-rim aperture
        angle1(:,k)=atan(ImagSystPupil.ExPs{k}.diam(:,1)./(ImagSystPupil.ExPs{k}.z_pos-Object.ConjGauss.z_im(1))); %.z_ob because PUPIL defined for ON AXIS point
        %angle bottom-rim aperture
        angle2(:,k)=atan(ImagSystPupil.ExPs{k}.diam(:,2)./(ImagSystPupil.ExPs{k}.z_pos-Object.ConjGauss.z_im(1))); %.z_ob because PUPIL defined for ON AXIS point
    
    end
end

%STEP 2 %Find min angle for upper and lower rim
for n=1:length(wave)
    [Min1(n,1),Ind1(n)]=min(abs(angle1(n,:)));
    [Min2(n,1),Ind2(n)]=min(abs(angle2(n,:)));
end

%STEP 3-6

%UPPER LIMIT OF APERTURE
if all(Ind1==Ind1(1))
    Ind=Ind1;
    Radiance.chromSTOP='constant';
    % For upper rim of the aperture
    %Aperture stop
    Radiance.aperSTOP.indexSurf=Ind(1);
    Radiance.aperSTOP.surf{1,1}=OptSystlist{ImagSystPupil.computed_order(Ind(1))};
    %Entrance Pupil 
    Radiance.EnP.z_pos(:,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Radiance.EnP.m_lat(:,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Radiance.EnP.diam(:,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,1);
    %Angular aperture on the object side
    Radiance.EnP.angularAperture_rad(:,1)=Min1; %in rad
    Radiance.EnP.angularAperture_deg(:,1)=Min1*pi/180; % in deg
    % Exit Pupil
    Radiance.ExP.z_pos(:,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Radiance.ExP.m_lat(:,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Radiance.ExP.diam(:,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,1);
    %Angular aperture on the object side
    tanAng_im=Radiance.ExP.diam(:,1)./(Radiance.ExP.z_pos(:,1)-Object.ConjGauss.z_im);
    Radiance.ExP.angularAperture_rad(:,1)=abs(atan(tanAng_im));%in rad
    Radiance.ExP.angularAperture_deg(:,1)=abs(atan(tanAng_im))*180/pi; % in deg
else
    Radiance.chromSTOP='variable';
    % For upper rim of the aperture
    for n=1:length(wave)
        %Aperture stop
        Radiance.aperSTOP.indexSurf(n,1)=Ind1(n);
        Radiance.aperSTOP.surf{n,1}=OptSystlist{ImagSystPupil.computed_order(Ind1(n))};
        %Entrance Pupil 
        Radiance.EnP.z_pos(n,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind1(n))}.z_pos(n,1);
        Radiance.EnP.m_lat(n,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind1(n))}.m_lat(n,1);
        Radiance.EnP.diam(n,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind1(n))}.diam(n,1);
        %Angular aperture on the object side
        Radiance.EnP.angularAperture_rad(n,1)=Min1(n); %in rad
        Radiance.EnP.angularAperture_deg(n,1)=Min1(n)*pi/180; % in deg
        % Exit Pupil
        Radiance.ExP.z_pos(n,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind1(n))}.z_pos(n,1);
        Radiance.ExP.m_lat(n,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind1(n))}.m_lat(n,1);
        Radiance.ExP.diam(n,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind1(n))}.diam(n,1);
        %Angular aperture on the object side
        tanAng_im=Radiance.ExP.diam(n,1)./(Radiance.ExP.z_pos(n,1)-Object.ConjGauss.z_im(n,1));
        Radiance.ExP.angularAperture_rad(n,1)=abs(atan(tanAng_im));%in rad
        Radiance.ExP.angularAperture_deg(n,1)=abs(atan(tanAng_im))*180/pi; % in deg
    end
end
%LOWER LIMIT OF APERTURE
if all(Ind2==Ind2(1))
    Ind=Ind2;
    Radiance.chromSTOP='constant';
    % For upper rim of the aperture
    %Aperture stop
    Radiance.aperSTOP.indexSurf=Ind(1);
    Radiance.aperSTOP.surf{1,2}=OptSystlist{ImagSystPupil.computed_order(Ind(1))};
    %Entrance Pupil 
    Radiance.EnP.z_pos(:,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Radiance.EnP.m_lat(:,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Radiance.EnP.diam(:,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,2);
    %Angular aperture on the object side
    Radiance.EnP.angularAperture_rad(:,2)=Min2; %in rad
    Radiance.EnP.angularAperture_deg(:,2)=Min2*pi/180; % in deg
    % Exit Pupil
    Radiance.ExP.z_pos(:,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Radiance.ExP.m_lat(:,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Radiance.ExP.diam(:,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,2);
    %Angular aperture on the object side
    tanAng_im=Radiance.ExP.diam(:,2)./(Radiance.ExP.z_pos(:,2)-Object.ConjGauss.z_im);
    Radiance.ExP.angularAperture_rad(:,2)=abs(atan(tanAng_im));%in rad
    Radiance.ExP.angularAperture_deg(:,2)=abs(atan(tanAng_im))*180/pi; % in deg
else
    Radiance.chromSTOP='variable';
    % For upper rim of the aperture
    for n=1:length(wave)
        %Aperture stop
        Radiance.aperSTOP.indexSurf(n,2)=Ind2(n);
        Radiance.aperSTOP.surf{n,2}=OptSystlist{ImagSystPupil.computed_order(Ind2(n))};
        %Entrance Pupil 
        Radiance.EnP.z_pos(n,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind2(n))}.z_pos(n,1);
        Radiance.EnP.m_lat(n,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind2(n))}.m_lat(n,1);
        Radiance.EnP.diam(n,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind2(n))}.diam(n,2);
        %Angular aperture on the object side
        Radiance.EnP.angularAperture_rad(n,2)=Min1(n); %in rad
        Radiance.EnP.angularAperture_deg(n,2)=Min1(n)*pi/180; % in deg
        % Exit Pupil
        Radiance.ExP.z_pos(n,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind2(n))}.z_pos(n,1);
        Radiance.ExP.m_lat(n,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind2(n))}.m_lat(n,1);
        Radiance.ExP.diam(n,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind2(n))}.diam(n,2);
        %Angular aperture on the object side
        tanAng_im=Radiance.ExP.diam(n,2)./(Radiance.ExP.z_pos(n,2)-Object.ConjGauss.z_im(n,1));
        Radiance.ExP.angularAperture_rad(n,2)=abs(atan(tanAng_im));%in rad
        Radiance.ExP.angularAperture_deg(n,2)=abs(atan(tanAng_im))*pi/180; % in deg
    end
end
%Overall parameters
%Angular aperture
%In object space
Radiance.objectSpace.angAperture_rad=abs(Radiance.EnP.angularAperture_rad(n,2)+Radiance.EnP.angularAperture_rad(n,1));
Radiance.objectSpace.angAperture_deg=Radiance.objectSpace.angAperture_rad*180/pi;
%In image space
Radiance.imageSpace.angAperture_rad=abs(Radiance.ExP.angularAperture_rad(n,2)+Radiance.ExP.angularAperture_rad(n,1));
Radiance.imageSpace.angAperture_deg=Radiance.imageSpace.angAperture_rad*180/pi;


