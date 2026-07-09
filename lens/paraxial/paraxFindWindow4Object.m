



function [Field]=paraxFindWindow4Object(ObjectEnP,ObjectExP,ImagSystPupil,Film,Surfslist,wave)
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
%
%   function [Field]=paraxFindWindow4Object(ObjectEnP,ObjectExP,ImagSystPupil,Film,Surfslist,wave)
%
%INPUT

% ObjectEnP: the entrance pupil for the given object point
% ObjectExP: the exit pupil for the given object point
% ImagSystPupil: is a structure containing the following information of the optical system
%       .EnPs: possible entrance pupils position (.z_pos), lateral magnification (.m_lat), and edge (.diam)
%               of the object on the optical axis
%       .ExPs: possible exit pupils position (.z_pos), lateral magnification (.m_lat), and edge (.diam)
%               of the object on the optical axis
%       .computed_order order of computation of the optical system surface
%       .y_ecc: eccentricity on the meridional plane of the object
%Film : strucutre of the the film (sensor
%           .Pupils .EnP
%                   .ExP
%
%Surfslist: structure containing the list of the surface in the optical system
%           .list
%           .order
%
%wave: sampling wavelength  
%
%Field: structure with
%       .Stop (field stop)
%       .EnW (entrance window)
%       .ExW  (exit window)
%       .FoV.objectSpace (field of view in the object space)
%       .FoV.imageSpace  (field of view in the image space)
% NOTE: all coordinates, distances and wavelengths are consistence with
% [unit] of the Imaging System field used as input
%
% % MP Vistasoft 2014


%% CHECK INPUT FIELD

if not((isfield (Film,'Pupils')))
    warning ('There are not possible Pupils for the film! Return empty output')
    Field=[];
    return
end
%create derivated paramters
FilmPupil.EnP=Film.Pupils.EnP; 
FilmPupil.ExP=Film.Pupils.ExP;

%replicate values based on number of sampling wavelength
if not(size(FilmPupil.EnP.z_pos,1)==size(wave,1))
    FilmPupil.EnP.z_pos=repmat(FilmPupil.EnP.z_pos,size(wave,1),1);
    FilmPupil.EnP.m_lat=repmat(FilmPupil.EnP.m_lat,size(wave,1),1);    
    FilmPupil.EnP.diam=repmat(FilmPupil.EnP.diam,size(wave,1),1);
end
if not(size(FilmPupil.ExP.z_pos,1)==size(wave,1))
    FilmPupil.ExP.z_pos=repmat(FilmPupil.ExP.z_pos,size(wave,1),1);
    FilmPupil.ExP.m_lat=repmat(FilmPupil.ExP.m_lat,size(wave,1),1);    
    FilmPupil.ExP.diam=repmat(FilmPupil.ExP.diam,size(wave,1),1);
end


%% FIND ENTRANCE WINDOW as Entrance Pupil of the aperture limiting the marginal rays 
%starting from the ENTRANCE PUPIL

%STEP 1
for k=1:length(ImagSystPupil.computed_order)
    %angle top-rim aperture
    angle1(:,k)=atan(ImagSystPupil.EnPs{k}.diam(:,1)./(ImagSystPupil.EnPs{k}.z_pos-mean(ObjectEnP.z_pos,2))); 
%     angle1(:,k)=atan(ObjectEnP.diam(:,1)./(ImagSystPupil.EnPs{k}.z_pos-mean(ObjectEnP.z_pos,2))); 
    %angle bottom-rim aperture
    angle2(:,k)=atan(ImagSystPupil.EnPs{k}.diam(:,2)./(ImagSystPupil.EnPs{k}.z_pos-mean(ObjectEnP.z_pos,2))); 
%     angle2(:,k)=atan(ObjectEnP.diam(:,2)./(ImagSystPupil.EnPs{k}.z_pos-mean(ObjectEnP.z_pos,2))); 
end
%add the FILM
an1=atan(FilmPupil.EnP.diam(:,1)./(FilmPupil.EnP.z_pos-mean(ObjectEnP.z_pos,2)));
an2=atan(FilmPupil.EnP.diam(:,2)./(FilmPupil.EnP.z_pos-mean(ObjectEnP.z_pos,2))); 
%check if any of that are at infinity
an1(isnan(an1))=0;
an2(isnan(an2))=0;
angle1(:,length(ImagSystPupil.computed_order)+1)=an1;
angle2(:,length(ImagSystPupil.computed_order)+1)=an2;
% angle1(:,length(ImagSystPupil.computed_order)+1)=atan(ObjectEnP.diam(:,1)./(FilmPupil.EnP.z_pos-mean(ObjectEnP.z_pos,2)));
% angle2(:,length(ImagSystPupil.computed_order)+1)=atan(ObjectEnP.diam(:,2)./(FilmPupil.EnP.z_pos-mean(ObjectEnP.z_pos,2))); 

%STEP 2 %Find min angle for upper and lower rim
for n=1:length(wave)
    [Min1(n,1),Ind1(n)]=min(abs(angle1(n,:)));
    [Min2(n,1),Ind2(n)]=min(abs(angle2(n,:)));
end

%STEP 3-6
%UPPER LIMIT OF APERTURE

if all(Ind1==Ind1(1)) && Ind1(1)>length(Surfslist.order)
    %if index greater that number of surface , that is the film the FIELD STOP
    Field.fieldSTOP.surf{1,1}=Film;
    %Entrance Window 
    Field.EnW.z_pos(:,1)=FilmPupil.EnP.z_pos;
    Field.EnW.m_lat(:,1)=FilmPupil.EnP.m_lat;
    Field.EnW.diam(:,1)=FilmPupil.EnP.diam(:,1);
    % Exit Window
    Field.ExW.z_pos(:,1)=FilmPupil.ExP.z_pos;
    Field.ExW.m_lat(:,1)=FilmPupil.ExP.m_lat;
    Field.ExW.diam(:,1)=FilmPupil.ExP.diam(:,1);
    
    %Half-Field of View on the object side
    FoV_obj_rad(:,1)=Min1; %in rad
    %Half-Field of View on the image side
    Min1_im=atan(Field.ExW.diam(:,1)./(Field.ExW.z_pos(:,1)-mean(ObjectExP.z_pos,2)));
    FoV_im_rad(:,1)=Min1_im; %in rad  
 
    
elseif  all(Ind1==Ind1(1))
    Ind=Ind1;
    Field.chromSTOP='constant';
    % For upper rim of the aperture
    %Field stop
    Field.fieldSTOP.indexSurf=Ind(1);
    Field.fieldSTOP.surf{1,1}=Surfslist.list{Surfslist.order(Ind(1))};
    %Entrance Window 
    Field.EnW.z_pos(:,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Field.EnW.m_lat(:,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Field.EnW.diam(:,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,1);
    % Exit Window
    Field.ExW.z_pos(:,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Field.ExW.m_lat(:,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Field.ExW.diam(:,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,1);
   
    %Half-Field of View on the object side
    FoV_obj_rad(:,1)=Min1; %in rad
    %Half-Field of View on the image side
    Min1_im=atan(Field.ExW.diam(:,1)./(Field.ExW.z_pos(:,1)-mean(ObjectExP.z_pos,2)));
    FoV_im_rad(:,1)=Min1_im; %in rad  

else
    Field.chromSTOP='variable';
    Ind=Ind1;
    % For upper rim of the aperture
    for n=1:length(wave)
        %Field stop
        Field.fieldSTOP.indexSurf(n,1)=Ind(n);
        Field.fieldSTOP.surf{n,1}=Surfslist.list{Surfslist.order(Ind(n))};
        %Entrance Window 
        Field.EnW.z_pos(n,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(n))}.z_pos(n,1);
        Field.EnW.m_lat(n,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(n))}.m_lat(n,1);
        Field.EnW.diam(n,1)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(n))}.diam(n,1);
        % Exit Window
        Field.ExW.z_pos(n,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(n))}.z_pos(n,1);
        Field.ExW.m_lat(n,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(n))}.m_lat(n,1);
        Field.ExW.diam(n,1)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(n))}.diam(n,1);
        
        %Half-Field of View on the object side
        FoV_obj_rad(n,1)=Min1(n); %in rad
        %Half-Field of View on the image side
%         Min1_im(n)=atan(Field.ExW.diam(n,1)./(Field.ExW.z_pos(n,1)-mean(ObjectExP.z_pos,2)));
        Min1_im(n)=atan(Field.ExW.diam(n,1)./(Field.ExW.z_pos(n,1)-mean(ObjectExP.z_pos(n,:))));
        FoV_im_rad(n,1)=Min1_im(n); %in rad 
    end
end

%LOWER LIMIT OF APERTURE
if all(Ind2==Ind2(1)) && Ind2(1)>length(Surfslist.order)
    %if index greater that number of surface , that is the film the FIELD STOP
    Field.fieldSTOP.surf{1,2}=Film;
    %Entrance Window 
    Field.EnW.z_pos(:,2)=FilmPupil.EnP.z_pos;
    Field.EnW.m_lat(:,2)=FilmPupil.EnP.m_lat;
    Field.EnW.diam(:,2)=FilmPupil.EnP.diam(:,2);
    % Exit Window
    Field.ExW.z_pos(:,2)=FilmPupil.ExP.z_pos;
    Field.ExW.m_lat(:,2)=FilmPupil.ExP.m_lat;
    Field.ExW.diam(:,2)=FilmPupil.ExP.diam(:,2);
    
    %Half-Field of View on the object side
    FoV_obj_rad(:,2)=Min2; %in rad
    %Half-Field of View on the image side
    Min2_im=atan(Field.ExW.diam(:,2)./(Field.ExW.z_pos(:,2)-mean(ObjectExP.z_pos,2)));
    FoV_im_rad(:,2)=Min2_im; %in rad  
    
elseif  all(Ind2==Ind2(1))
    Ind=Ind2;
    Field.chromSTOP='constant';
    % For upper rim of the aperture
    %Field stop
    Field.fieldSTOP.indexSurf=Ind(1);
    Field.fieldSTOP.surf{1,2}=Surfslist.list{Surfslist.order(Ind(1))};
    %Entrance Window 
    Field.EnW.z_pos(:,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Field.EnW.m_lat(:,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Field.EnW.diam(:,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,2);
    % Exit Window
    Field.ExW.z_pos(:,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.z_pos;
    Field.ExW.m_lat(:,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.m_lat;
    Field.ExW.diam(:,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(1))}.diam(:,2);
   
    %Half-Field of View on the object side
    FoV_obj_rad(:,2)=Min2; %in rad
    %Half-Field of View on the image side
    Min2_im=atan(Field.ExW.diam(:,2)./(Field.ExW.z_pos(:,2)-mean(ObjectExP.z_pos,2)));
    FoV_im_rad(:,2)=Min2_im; %in rad  

else
    Ind=Ind2;
    Field.chromSTOP='variable';
    % For upper rim of the aperture
    for n=1:length(wave)
        %Field stop
        Field.fieldSTOP.indexSurf(n,2)=Ind(n);
        Field.fieldSTOP.surf{n,2}=Surfslist.list{Surfslist.order(Ind(n))};
        %Entrance Window 
        Field.EnW.z_pos(n,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(n))}.z_pos(n,1);
        Field.EnW.m_lat(n,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(n))}.m_lat(n,1);
        Field.EnW.diam(n,2)=ImagSystPupil.EnPs{ImagSystPupil.computed_order(Ind(n))}.diam(n,2);
        % Exit Window
        Field.ExW.z_pos(n,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(n))}.z_pos(n,1);
        Field.ExW.m_lat(n,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(n))}.m_lat(n,1);
        Field.ExW.diam(n,2)=ImagSystPupil.ExPs{ImagSystPupil.computed_order(Ind(n))}.diam(n,2);
        
        %Half-Field of View on the object side
        FoV_obj_rad(n,2)=Min2(n); %in rad
        %Half-Field of View on the image side
%         Min2_im(n)=atan(Field.ExW.diam(n,2)./(Field.ExW.z_pos(n,1)-mean(ObjectExP.z_pos,2)));
        Min2_im(n)=atan(Field.ExW.diam(n,2)./(Field.ExW.z_pos(n,1)-mean(ObjectExP.z_pos(n,:))));
        FoV_im_rad(n,2)=Min2_im(n); %in rad 
    end
end
%COMPUTE THE FIELD of VIEW
%In object space
Field.FoV.obSpace.rad=abs(FoV_obj_rad(:,1))+abs(FoV_obj_rad(:,2)); % in [rad] add the field of view for upper and lower angle
Field.FoV.obSpace.deg=Field.FoV.obSpace.rad*180/pi; %in [deg]
%In image space
Field.FoV.imSpace.rad=abs(FoV_im_rad(:,1))+abs(FoV_im_rad(:,2)); % in [rad] add the field of view for upper and lower angle
Field.FoV.imSpace.deg=Field.FoV.imSpace.rad*180/pi; %in [deg]

%Numerical Aperture :describe the amount of light gathered by the optical
%system from the Entrance Windows

% atanNA=mean(abs(ObjectEnP.diam),2)./(mean(ObjectEnP.z_pos,2)-mean(Field.EnW.z_pos,2));
% Field.NA=sin(atan(atanNA)); %to get the  numerical aperture in needed to multiply for the refractive index